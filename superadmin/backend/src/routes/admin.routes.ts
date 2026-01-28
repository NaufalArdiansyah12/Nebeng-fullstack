// src/routes/admin.routes.ts
import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

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
      [token, 'admin']
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
      `SELECT id, name, email, role, tempat_lahir, tanggal_lahir, 
              jenis_kelamin, no_tlp, foto, created_at, updated_at 
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
        namaLengkap: userData.name, // Untuk kompatibilitas
        email: userData.email,
        role: userData.role,
        tempat_lahir: userData.tempat_lahir || '',
        tempatLahir: userData.tempat_lahir || '',
        tanggal_lahir: userData.tanggal_lahir || '',
        tanggalLahir: userData.tanggal_lahir || '',
        jenis_kelamin: userData.jenis_kelamin || '',
        jenisKelamin: userData.jenis_kelamin || '',
        no_tlp: userData.no_tlp || '',
        noTlp: userData.no_tlp || '',
        foto: userData.foto || '',
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
    const { namaLengkap, name, email, tempatLahir, tempat_lahir, tanggalLahir, tanggal_lahir, jenisKelamin, jenis_kelamin, noTlp, no_tlp } = req.body;

    // Normalisasi field names (support both camelCase and snake_case)
    const updateData = {
      name: namaLengkap || name,
      email: email,
      tempat_lahir: tempatLahir || tempat_lahir,
      tanggal_lahir: tanggalLahir || tanggal_lahir,
      jenis_kelamin: jenisKelamin || jenis_kelamin,
      no_tlp: noTlp || no_tlp
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
        tempat_lahir = ?, 
        tanggal_lahir = ?, 
        jenis_kelamin = ?, 
        no_tlp = ?,
        updated_at = NOW()
      WHERE id = ?`,
      [
        updateData.name, 
        updateData.email, 
        updateData.tempat_lahir,
        updateData.tanggal_lahir,
        updateData.jenis_kelamin,
        updateData.no_tlp,
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
        tempat_lahir: updateData.tempat_lahir,
        tempatLahir: updateData.tempat_lahir,
        tanggal_lahir: updateData.tanggal_lahir,
        tanggalLahir: updateData.tanggal_lahir,
        jenis_kelamin: updateData.jenis_kelamin,
        jenisKelamin: updateData.jenis_kelamin,
        no_tlp: updateData.no_tlp,
        noTlp: updateData.no_tlp,
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

export default router;