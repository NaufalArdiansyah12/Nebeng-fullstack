// src/routes/auth.routes.ts
import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';
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

// Login endpoint
router.post('/login', async (req: Request, res: Response): Promise<any> => {
  const startTime = Date.now();
  console.log('📥 Login request received:', { email: req.body.email });
  
  try {
    const { email, password } = req.body;

    // Validasi input
    if (!email || !password) {
      console.log('❌ Validation failed: Missing email or password');
      return res.status(400).json({
        success: false,
        message: 'Email dan password harus diisi'
      });
    }

    // Query user dari database
    console.log('🔍 Querying database for user...');
    const queryStart = Date.now();
    
    const [rows] = await pool.execute<any[]>(
      'SELECT id, name, email, role, password, remember_token, created_at, updated_at FROM users WHERE email = ? AND role = ? LIMIT 1',
      [email, 'admin']
    );

    console.log(`⏱️  Query took: ${Date.now() - queryStart}ms`);

    if (rows.length === 0) {
      console.log('❌ User not found or not admin');
      return res.status(401).json({
        success: false,
        message: 'Email tidak ditemukan atau Anda bukan admin'
      });
    }

    const user: User = rows[0];
    console.log('✅ User found:', user.email);

    // Verifikasi password
    let isPasswordValid = false;
    const hashStartTime = Date.now();
    
    // Cek apakah password sudah di-hash (support $2a$, $2b$, dan $2y$ dari PHP)
    if (user.password && (user.password.startsWith('$2a$') || user.password.startsWith('$2b$') || user.password.startsWith('$2y$'))) {
      console.log('🔐 Verifying hashed password...');
      
      // Convert $2y$ (PHP) to $2a$ (Node.js) untuk kompatibilitas
      let passwordHash = user.password;
      if (passwordHash.startsWith('$2y$')) {
        passwordHash = '$2a$' + passwordHash.substring(4);
        console.log('🔄 Converting PHP hash ($2y$) to Node.js format ($2a$)');
      }
      
      isPasswordValid = await bcrypt.compare(password, passwordHash);
      console.log(`⏱️  Bcrypt compare took: ${Date.now() - hashStartTime}ms`);
    } else {
      console.log('⚠️  Warning: Using plain text password comparison');
      isPasswordValid = password === user.password;
    }
    
    if (!isPasswordValid) {
      console.log('❌ Invalid password');
      return res.status(401).json({
        success: false,
        message: 'Email atau password salah'
      });
    }

    console.log('✅ Password verified');

    // Generate token
    const token = crypto.randomBytes(32).toString('hex');

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

    console.log(`✅ Login successful! Total time: ${Date.now() - startTime}ms`);

    // Response sukses
    return res.json({
      success: true,
      message: 'Login berhasil',
      user: userResponse,
      token: token
    });

  } catch (error: any) {
    console.error('❌ Login error:', error);
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
      'SELECT id, name, email, role, created_at, updated_at FROM users WHERE remember_token = ? AND role = ? LIMIT 1',
      [token, 'admin']
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
      'SELECT id, name, email, role FROM users WHERE remember_token = ? AND role = ? LIMIT 1',
      [token, 'admin']
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

export default router;