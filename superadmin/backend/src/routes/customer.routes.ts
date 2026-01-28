import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all customers from users table (role = 'customer')
router.get('/', async (req: Request, res: Response) => {
  try { 
    const connection = await pool.getConnection();
    
    const [rows] = await connection.query(
      `SELECT   
        u.id,   
        u.name as nama,     
        u.email,    
        u.phone as no_tlp,  
        v.status,   
        u.created_at as tanggal_daftar  
       FROM users u 
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' 
       ORDER BY u.created_at DESC`
    );
    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/customers error:', error);
    res.status(500).json({ error: 'Failed to fetch customers', message: error instanceof Error ? error.message : '' });
  }
});

// Get customer by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    // ✅ PERBAIKAN: Ambil semua data dari verifikasi_ktp_customers
   const [rows] = await connection.query(
  `SELECT 
    u.id, 
    u.name as nama, 
    u.email, 
    u.phone as no_tlp, 
    v.id as verifikasi_id,
    v.status,
    v.nama_lengkap,
    v.nik,
    v.tanggal_lahir,
    v.alamat,
    v.photo_wajah,
    v.photo_ktp,
    u.created_at as tanggal_daftar 
   FROM users u
   LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
   WHERE u.role = 'customer' AND u.id = ?`,
  [id]
);
    connection.release();

    if (Array.isArray(rows) && rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Customer not found' });
    }
  } catch (error) {
    console.error('❌ GET /api/customers/:id error:', error);
    res.status(500).json({ error: 'Failed to fetch customer', message: error instanceof Error ? error.message : '' });
  }
});

// Create customer
router.post('/', async (req: Request, res: Response) => {
  const { kode, nama, email, noTlp, namaLengkap, tempatLahir, tanggalLahir, jenisKelamin, nik, alamat } = req.body;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `INSERT INTO customer (kode, nama, email, no_tlp, nama_lengkap, tempat_lahir, tanggal_lahir, jenis_kelamin, nik, alamat)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [kode, nama, email, noTlp, namaLengkap, tempatLahir, tanggalLahir, jenisKelamin, nik, alamat]
    );
    connection.release();

    res.status(201).json({ id: (result as any).insertId, message: 'Customer created successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create customer', message: error instanceof Error ? error.message : '' });
  }
});

// Update customer
router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { nama, email, noTlp, namaLengkap, tempatLahir, tanggalLahir, jenisKelamin, nik, alamat } = req.body;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      `UPDATE customer 
       SET nama = ?, email = ?, no_tlp = ?, nama_lengkap = ?, tempat_lahir = ?, 
           tanggal_lahir = ?, jenis_kelamin = ?, nik = ?, alamat = ?
       WHERE id = ?`,
      [nama, email, noTlp, namaLengkap, tempatLahir, tanggalLahir, jenisKelamin, nik, alamat, id]
    );
    connection.release();

    res.json({ message: 'Customer updated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update customer', message: error instanceof Error ? error.message : '' });
  }
});

// Delete customer (deactivate instead)
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
      ['DELETED', id]
    );
    connection.release();

    res.json({ message: 'Customer deleted successfully' });
  } catch (error) {
    console.error('❌ DELETE /api/customers/:id error:', error);
    res.status(500).json({ error: 'Failed to delete customer', message: error instanceof Error ? error.message : '' });
  }
});

// Update customer status
router.patch('/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
      [status, id]
    );
    connection.release();

    res.json({ message: 'Customer status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/customers/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update customer status', message: error instanceof Error ? error.message : '' });
  }
});

// Block customer
router.post('/:id/block', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
      ['DIBLOCK', id]
    );
    connection.release();

    res.json({ message: 'Customer blocked successfully' });
  } catch (error) {
    console.error('❌ POST /api/customers/:id/block error:', error);
    res.status(500).json({ error: 'Failed to block customer', message: error instanceof Error ? error.message : '' });
  }
});

// Unblock customer
router.post('/:id/unblock', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_customers SET status = ? WHERE user_id = ?', 
      ['TERVERIFIKASI', id]
    );
    connection.release();

    res.json({ message: 'Customer unblocked successfully' });
  } catch (error) {
    console.error('❌ POST /api/customers/:id/unblock error:', error);
    res.status(500).json({ error: 'Failed to unblock customer', message: error instanceof Error ? error.message : '' });
  }
});

export default router;