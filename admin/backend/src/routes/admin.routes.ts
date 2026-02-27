// src/routes/admin.routes.ts
import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';
import bcrypt from 'bcrypt';

const router = express.Router();

// Middleware untuk verifikasi token (sederhana)
const verifyToken = async (req: Request, res: Response, next: any) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak ditemukan'
      });
    }

    // Verifikasi token di database
    const [rows] = await pool.execute<any[]>(
      'SELECT id, name, email, role FROM users WHERE remember_token = ? AND role = ?',
      [token, 'superadmin']
    );

    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Token tidak valid'
      });
    }

    // Simpan user info di request
    (req as any).user = rows[0];
    next();
  } catch (error: any) {
    console.error('❌ Token verification error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error verifying token',
      error: error.message
    });
  }
};

// Get admin profile
router.get('/profile', verifyToken, async (req: Request, res: Response): Promise<any> => {
  try {
    const user = (req as any).user;
    
    // Query lengkap untuk mendapatkan semua data user
    const [rows] = await pool.execute<any[]>(
      `SELECT id, name, email, role, phone, profile_photo, address, created_at, updated_at
       FROM users WHERE id = ? LIMIT 1`,
      [user.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const userData = rows[0];
    
    console.log('✅ Admin profile fetched:', userData.email);
    
    return res.json({
      success: true,
      data: {
        id: userData.id,
        nama_lengkap: userData.name,
        namaLengkap: userData.name,
        email: userData.email,
        role: userData.role,
        tempat_lahir: userData.address || '',
        tempatLahir: userData.address || '',
        no_tlp: userData.phone || '',
        noTlp: userData.phone || '',
        foto: userData.profile_photo || '',
        alamat: userData.address || '',
        layanan: 'Nebeng'
      }
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

// Update admin profile
router.put('/profile', verifyToken, async (req: Request, res: Response): Promise<any> => {
  try {
    const user = (req as any).user;
    const { namaLengkap, name, email, noTlp, no_tlp, foto, alamat, tempatLahir, tempat_lahir } = req.body;

    // Normalisasi field names (support both camelCase dan snake_case)
    const updateData = {
      name: namaLengkap || name || null,
      email: email || null,
      phone: noTlp || no_tlp || null,
      profile_photo: foto || null,
      address: alamat || tempatLahir || tempat_lahir || null
    };

    if (!updateData.name || !updateData.email) {
      return res.status(400).json({
        success: false,
        message: 'Name and email are required'
      });
    }

    // Update database
    await pool.execute(
      `UPDATE users SET
        name = ?,
        email = ?,
        phone = ?,
        profile_photo = ?,
        address = ?,
        updated_at = NOW()
      WHERE id = ?`,
      [
        updateData.name,
        updateData.email,
        updateData.phone,
        updateData.profile_photo,
        updateData.address,
        user.id
      ]
    );

    console.log('✅ Admin profile updated:', updateData.email);

    return res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: user.id,
        nama_lengkap: updateData.name,
        namaLengkap: updateData.name,
        email: updateData.email,
        role: user.role,
        no_tlp: updateData.phone,
        noTlp: updateData.phone,
        foto: updateData.profile_photo,
        alamat: updateData.address,
        layanan: 'Nebeng'
      }
    });
  } catch (error: any) {
    console.error('❌ Update profile error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error updating profile',
      error: error.message
    });
  }
});

// Update admin password - SIMPLIFIED (bypass current password verification)
router.put('/password', verifyToken, async (req: Request, res: Response): Promise<any> => {
  try {
    const user = (req as any).user;
    const { newPassword, new_password } = req.body;

    // Support both camelCase dan snake_case
    const newPass = newPassword || new_password;

    console.log('\n');
    console.log('═══════════════════════════════════════════');
    console.log('🔐 PASSWORD UPDATE REQUEST');
    console.log('═══════════════════════════════════════════');
    console.log('User ID:', user.id);
    console.log('User Email:', user.email);
    console.log('New password provided (length):', newPass?.length);

    // Validasi input
    if (!newPass) {
      console.warn('⚠️ Missing new password');
      return res.status(400).json({
        success: false,
        message: 'New password is required'
      });
    }

    // Validasi panjang password
    if (newPass.length < 6) {
      console.warn('⚠️ New password too short');
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters long'
      });
    }

    // ✅ BYPASS: Langsung hash password baru tanpa verifikasi current password
    console.log('✅ Skipping current password verification (DEVELOPMENT MODE)');
    console.log('🔒 Hashing new password...');
    
    const hashedNewPassword = await bcrypt.hash(newPass, 10);
    console.log('✅ New password hashed');

    // Update password di database
    await pool.execute(
      'UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?',
      [hashedNewPassword, user.id]
    );

    console.log('✅ Password updated in database');
    console.log('═══════════════════════════════════════════\n');

    return res.json({
      success: true,
      message: 'Password updated successfully'
    });

  } catch (error: any) {
    console.error('❌ UNEXPECTED ERROR:', error.message);
    console.error('Stack trace:', error.stack);
    console.log('═══════════════════════════════════════════\n');
    
    return res.status(500).json({
      success: false,
      message: 'Error updating password',
      error: error.message
    });
  }
});

export default router;