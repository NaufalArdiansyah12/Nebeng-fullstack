// src/routes/auth.routes.ts
import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../../db.ts';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';

const router = express.Router();

// Interface untuk User
interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  password: string;
  remember_token?: string | null;
  created_at?: Date;
  updated_at?: Date;
}

// Login endpoint - IMPROVED
router.post('/login', async (req: Request, res: Response): Promise<any> => {
  const startTime = Date.now();
  console.log('\n');
  console.log('═══════════════════════════════════════════');
  console.log('📥 LOGIN REQUEST');
  console.log('═══════════════════════════════════════════');
  console.log('Email:', req.body.email);
  
  try {
    const { email, password } = req.body;

    // Validasi input
    if (!email || !password) {
      console.log('❌ Validation failed: Missing email or password');
      console.log('═══════════════════════════════════════════\n');
      return res.status(400).json({
        success: false,
        message: 'Email dan password harus diisi'
      });
    }

    // Query user dari database
    console.log('🔍 Querying database for user...');
    const queryStart = Date.now();
    
    // Coba multiple role variations
    const [rows] = await pool.execute<any[]>(
      'SELECT id, name, email, role, password, remember_token, created_at, updated_at FROM users WHERE email = ? LIMIT 1',
      [email]
    );

    console.log(`⏱️  Query took: ${Date.now() - queryStart}ms`);
    console.log(`Found ${rows.length} user(s)`);

    if (rows.length === 0) {
      console.log('❌ User not found');
      console.log('═══════════════════════════════════════════\n');
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah'
      });
    }

    const user: User = rows[0];
    console.log('✅ User found');
    console.log('  - Email:', user.email);
    console.log('  - Role:', user.role);
    console.log('  - Password in DB (first 20 chars):', user.password?.substring(0, 20) + '...');

    // ========== PASSWORD VERIFICATION ==========
    console.log('');
    console.log('───────────────────────────────────────────');
    console.log('🔐 PASSWORD VERIFICATION');
    console.log('───────────────────────────────────────────');
    
    let isPasswordValid = false;
    const hashStartTime = Date.now();
    
    console.log('Password provided (length):', password.length);
    console.log('Password in DB (length):', user.password?.length);
    console.log('Is it bcrypt hash? (starts with $2):', user.password?.startsWith('$2'));

    // Cek apakah password sudah di-hash (support $2a$, $2b$, dan $2y$ dari PHP)
    if (user.password && (user.password.startsWith('$2a$') || user.password.startsWith('$2b$') || user.password.startsWith('$2y$'))) {
      console.log('✅ Detected bcrypt hash format');
      
      // Convert $2y$ (PHP) to $2a$ (Node.js) untuk kompatibilitas
      let passwordHash = user.password;
      if (passwordHash.startsWith('$2y$')) {
        passwordHash = '$2a$' + passwordHash.substring(4);
        console.log('🔄 Converting PHP hash ($2y$) to Node.js format ($2a$)');
      }
      
      console.log('🔒 Using bcrypt.compare()...');
      
      try {
        isPasswordValid = await bcrypt.compare(password, passwordHash);
        console.log(`⏱️  Bcrypt compare took: ${Date.now() - hashStartTime}ms`);
        console.log('Result:', isPasswordValid ? '✅ MATCH' : '❌ NO MATCH');
      } catch (bcryptError: any) {
        console.error('❌ Bcrypt error:', bcryptError.message);
        console.log('Falling back to plain text comparison...');
        isPasswordValid = password === user.password;
      }
    } else {
      console.log('⚠️  Password format not recognized as bcrypt');
      console.log('Trying plain text comparison...');
      isPasswordValid = password === user.password;
      console.log('Result:', isPasswordValid ? '✅ MATCH' : '❌ NO MATCH');
    }
    
    if (!isPasswordValid) {
      console.log('');
      console.log('❌ PASSWORD VERIFICATION FAILED');
      console.log('═══════════════════════════════════════════\n');
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah'
      });
    }

    console.log('');
    console.log('✅ PASSWORD VERIFICATION PASSED');

    // Generate token
    const token = crypto.randomBytes(32).toString('hex');
    console.log('🎫 Token generated');

    // Update token di database (async)
    pool.execute(
      'UPDATE users SET remember_token = ? WHERE id = ?',
      [token, user.id]
    ).catch(err => console.error('⚠️  Error updating token:', err));

    // Hapus password dari response
    const userResponse = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      created_at: user.created_at,
      updated_at: user.updated_at
    };

    console.log('✅ LOGIN SUCCESSFUL');
    console.log(`⏱️  Total time: ${Date.now() - startTime}ms`);
    console.log('═══════════════════════════════════════════\n');

    // Response sukses
    return res.json({
      success: true,
      message: 'Login berhasil',
      user: userResponse,
      token: token
    });

  } catch (error: any) {
    console.error('❌ LOGIN ERROR:', error.message);
    console.log('═══════════════════════════════════════════\n');
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server',
      error: error.message
    });
  }
});

// Logout endpoint
router.post('/logout', async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.body;
    
    if (userId) {
      await pool.execute(
        'UPDATE users SET remember_token = NULL WHERE id = ?',
        [userId]
      );
      console.log('✅ User logged out:', userId);
    }

    return res.json({
      success: true,
      message: 'Logout berhasil'
    });
  } catch (error: any) {
    console.error('❌ Logout error:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server',
      error: error.message
    });
  }
});

// Verify token endpoint
router.post('/verify', async (req: Request, res: Response): Promise<any> => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak ditemukan'
      });
    }

    const [rows] = await pool.execute<any[]>(
      'SELECT id, name, email, role, created_at, updated_at FROM users WHERE remember_token = ? LIMIT 1',
      [token]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak valid'
      });
    }

    return res.json({
      success: true,
      user: rows[0]
    });
  } catch (error: any) {
    console.error('❌ Verify error:', error);
    return res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan server',
      error: error.message
    });
  }
});

// Get profile endpoint (untuk kompatibilitas dengan AdminContext)
router.get('/profile', async (req: Request, res: Response): Promise<any> => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak ditemukan'
      });
    }

    const [rows] = await pool.execute<any[]>(
      'SELECT id, name, email, role FROM users WHERE remember_token = ? LIMIT 1',
      [token]
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak valid atau expired'
      });
    }

    return res.json({
      success: true,
      data: rows[0]
    });
  } catch (error: any) {
    console.error('❌ Get profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error fetching profile',
      error: error.message
    });
  }
});

// ⚠️ TESTING ENDPOINTS - HANYA UNTUK DEVELOPMENT

// Reset password user untuk testing
router.post('/test/reset-password', async (req: Request, res: Response): Promise<any> => {
  try {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email dan newPassword diperlukan'
      });
    }

    console.log('\n⚠️ TESTING: Resetting password for user:', email);

    // Cek user ada atau tidak
    const [userRows] = await pool.execute<any[]>(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );

    if (userRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Hash password baru
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await pool.execute(
      'UPDATE users SET password = ? WHERE email = ?',
      [hashedPassword, email]
    );

    console.log('✅ Password reset successful');
    console.log('Email:', email);
    console.log('New plain password:', newPassword);
    console.log('Hashed:', hashedPassword);
    console.log('\n');

    return res.json({
      success: true,
      message: 'Password reset successful',
      data: {
        email,
        plainPassword: newPassword,
        hashedPassword,
        instruction: `User dapat login dengan email: ${email} dan password: ${newPassword}`
      }
    });

  } catch (error: any) {
    console.error('❌ Reset password error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error resetting password',
      error: error.message
    });
  }
});

// Check password - apakah plain password cocok dengan hash di database
router.post('/test/check-password', async (req: Request, res: Response): Promise<any> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email dan password diperlukan'
      });
    }

    console.log('\n🔍 TESTING: Checking password for user:', email);

    // Cek user ada atau tidak
    const [userRows] = await pool.execute<any[]>(
      'SELECT id, password FROM users WHERE email = ?',
      [email]
    );

    if (userRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const hashedPassword = userRows[0].password;

    console.log('Plain password provided:', password);
    console.log('Hashed password in DB (first 20 chars):', hashedPassword?.substring(0, 20) + '...');

    // Compare password
    let isMatch = false;
    try {
      isMatch = await bcrypt.compare(password, hashedPassword);
    } catch (bcryptError: any) {
      console.log('Bcrypt compare failed, trying plain text:', bcryptError.message);
      isMatch = password === hashedPassword;
    }

    console.log('Match result:', isMatch);
    console.log('\n');

    return res.json({
      success: true,
      data: {
        email,
        plainPasswordProvided: password,
        hashedPasswordInDB: hashedPassword,
        match: isMatch,
        message: isMatch ? '✅ PASSWORD MATCHES' : '❌ PASSWORD DOES NOT MATCH'
      }
    });

  } catch (error: any) {
    console.error('❌ Check password error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error checking password',
      error: error.message
    });
  }
});
// Tambahkan endpoint ini ke auth.routes.ts untuk debugging

// ⚠️ DEBUGGING - Check semua password yang ada di database
router.get('/test/all-passwords', async (req: Request, res: Response): Promise<any> => {
  try {
    console.log('\n🔍 TESTING: Getting all users and their passwords');

    const [userRows] = await pool.execute<any[]>(
      'SELECT id, email, password FROM users LIMIT 10'
    );

    const users = userRows.map((user: any) => ({
      id: user.id,
      email: user.email,
      password: user.password,
      passwordLength: user.password?.length,
      isBcrypt: user.password?.startsWith('$2'),
      firstChars: user.password?.substring(0, 20) + '...'
    }));

    console.log('Users found:', users);
    console.log('\n');

    return res.json({
      success: true,
      data: users
    });

  } catch (error: any) {
    console.error('❌ Error:', error);
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
export default router;