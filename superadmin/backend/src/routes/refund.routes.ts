import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();
// Get all refund
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT r.id, r.no_order, c.nama as namaCustomer, m.nama as namaDriver, r.tanggal_refund as tanggal,
              r.no_transaksi, r.jumlah_refund, r.status
       FROM refund r
       JOIN pesanan p ON r.pesanan_id = p.id
       JOIN customer c ON p.customer_id = c.id
       JOIN mitra m ON p.mitra_id = m.id
       ORDER BY r.tanggal_refund DESC`
    );
    connection.release();

    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch refund', message: error instanceof Error ? error.message : '' });
  }
});

// Get refund by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT r.*, p.no_order as idPesanan, c.nama as customerName, m.nama as driverName,
              pb.tipe_pembayaran as metodeRefund, p.layanan as layananNebeng,
              pb.biaya_penumpang, pb.biaya_admin, pb.total
       FROM refund r
       LEFT JOIN pesanan p ON r.pesanan_id = p.id
       LEFT JOIN customer c ON p.customer_id = c.id
       LEFT JOIN mitra m ON p.mitra_id = m.id
       LEFT JOIN pembayaran pb ON p.id = pb.pesanan_id
       WHERE r.id = ?`,
      [id]
    );
    connection.release();

    if (Array.isArray(rows) && rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'Refund not found' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch refund', message: error instanceof Error ? error.message : '' });
  }
});

// Create refund
router.post('/', async (req: Request, res: Response) => {
  const { pesananId, noOrder, noTransaksi, jumlahRefund, metodeRefund } = req.body;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `INSERT INTO refund (pesanan_id, no_order, no_transaksi, jumlah_refund, metode_refund)
       VALUES (?, ?, ?, ?, ?)`,
      [pesananId, noOrder, noTransaksi, jumlahRefund, metodeRefund]
    );
    connection.release();

    res.status(201).json({ id: (result as any).insertId, message: 'Refund created successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create refund', message: error instanceof Error ? error.message : '' });
  }
});

// Update refund status
router.patch('/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const connection = await pool.getConnection();
    await connection.execute('UPDATE refund SET status = ? WHERE id = ?', [status, id]);
    connection.release();

    res.json({ message: 'Refund status updated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to update refund status', message: error instanceof Error ? error.message : '' });
  }
});

// Delete refund
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    await connection.execute('DELETE FROM refund WHERE id = ?', [id]);
    connection.release();

    res.json({ message: 'Refund deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete refund', message: error instanceof Error ? error.message : '' });
  }
});

export default router;
