import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all verifikasi mitra (pending verification)
router.get('/mitra', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT id, mitra_id as user_id, nik, nama_lengkap, tanggal_lahir,
              status, created_at as tanggal_pengajuan FROM verifikasi_ktp_mitras ORDER BY created_at DESC`
    );
    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/verifikasi/mitra error:', error);
    res.status(500).json({ error: 'Failed to fetch verifikasi mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Get verifikasi mitra by ID
router.get('/mitra/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      'SELECT * FROM verifikasi_ktp_mitras WHERE id = ?',
      [id]
    );
    connection.release();

    if (Array.isArray(rows) && rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Verifikasi mitra not found' });
    }
  } catch (error) {
    console.error('❌ GET /api/verifikasi/mitra/:id error:', error);
    res.status(500).json({ error: 'Failed to fetch verifikasi mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Get all verifikasi customer (pending verification)
router.get('/customer', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT id, user_id, nik, nama_lengkap, tanggal_lahir, 
              status, created_at as tanggal_pengajuan FROM verifikasi_ktp_customers ORDER BY created_at DESC`
    );
    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/verifikasi/customer error:', error);
    res.status(500).json({ error: 'Failed to fetch verifikasi customer', message: error instanceof Error ? error.message : '' });
  }
});

// Get verifikasi customer by ID
router.get('/customer/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      'SELECT * FROM verifikasi_ktp_customers WHERE id = ?',
      [id]
    );
    connection.release();

    if (Array.isArray(rows) && rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Verifikasi customer not found' });
    }
  } catch (error) {
    console.error('❌ GET /api/verifikasi/customer/:id error:', error);
    res.status(500).json({ error: 'Failed to fetch verifikasi customer', message: error instanceof Error ? error.message : '' });
  }
});

// Update verifikasi mitra status
router.patch('/mitra/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const connection = await pool.getConnection();
    await connection.query('UPDATE mitra SET status = ? WHERE id = ?', [status, id]);
    connection.release();

    res.json({ message: 'Status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/verifikasi/mitra/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update status', message: error instanceof Error ? error.message : '' });
  }
});

// Update verifikasi customer status
router.patch('/customer/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const connection = await pool.getConnection();
    await connection.query('UPDATE customer SET status = ? WHERE id = ?', [status, id]);
    connection.release();

    res.json({ message: 'Status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/verifikasi/customer/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update status', message: error instanceof Error ? error.message : '' });
  }
});

export default router;
