import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();
// Get all refund
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT p.id, p.booking_number as no_order, u.name as namaCustomer, u2.name as namaDriver,
              p.created_at as tanggal, p.external_id as no_transaksi, p.amount as jumlah_refund,
              CASE
                WHEN p.status = 'paid' THEN 'SELESAI'
                WHEN p.status = 'pending' THEN 'PROSES'
                WHEN p.status = 'expired' THEN 'BATAL'
                ELSE p.status
              END as status
       FROM payments p
       LEFT JOIN users u ON p.user_id = u.id
       LEFT JOIN users u2 ON p.ride_id = u2.id
       WHERE p.status IN ('paid', 'pending', 'expired')
       ORDER BY p.created_at DESC`
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
      `SELECT p.id, p.booking_number as no_order, p.external_id as no_transaksi,
              p.amount as jumlah_refund, p.payment_method as metodeRefund,
              p.admin_fee, p.total_amount as total, p.status,
              p.created_at as tanggal_refund, p.paid_at,
              u.name as customerName, u2.name as driverName,
              p.booking_id as idPesanan, 'Nebeng' as layananNebeng,
              p.amount as biaya_penumpang, p.admin_fee as biaya_admin
       FROM payments p
       LEFT JOIN users u ON p.user_id = u.id
       LEFT JOIN users u2 ON p.ride_id = u2.id
       WHERE p.id = ? AND p.status IN ('paid', 'pending', 'expired')`,
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
      `INSERT INTO payments (booking_id, booking_number, external_id, amount, payment_method, total_amount, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [pesananId, noOrder, noTransaksi, jumlahRefund, metodeRefund, jumlahRefund]
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

  // Map frontend status to payment status
  let paymentStatus = status;
  if (status === 'SELESAI') paymentStatus = 'paid';
  else if (status === 'PROSES') paymentStatus = 'pending';
  else if (status === 'BATAL') paymentStatus = 'expired';

  try {
    const connection = await pool.getConnection();
    await connection.execute('UPDATE payments SET status = ? WHERE id = ?', [paymentStatus, id]);
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
    await connection.execute('DELETE FROM payments WHERE id = ?', [id]);
    connection.release();

    res.json({ message: 'Refund deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete refund', message: error instanceof Error ? error.message : '' });
  }
});

export default router;
