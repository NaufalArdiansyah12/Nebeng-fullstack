import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../../db.ts';

const router = express.Router();
// Get all refund (from refunds table)
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();

    const [rows] = await connection.query(
      `SELECT
         r.id,
        r.booking_type as booking_type,
        r.refund_reason as refund_reason,
         r.booking_id as no_order,
         u.name as namaCustomer,
         '' as namaDriver,
         COALESCE(r.submitted_at, r.created_at) as tanggal,
         r.id as no_transaksi,
         r.refund_amount as jumlah_refund,
         CASE
           WHEN r.status = 'completed' THEN 'SELESAI'
           WHEN r.status IN ('pending','approved','processing') THEN 'PROSES'
           WHEN r.status = 'rejected' THEN 'BATAL'
           ELSE r.status
         END as status
       FROM refunds r
       LEFT JOIN users u ON r.user_id = u.id
       ORDER BY COALESCE(r.submitted_at, r.created_at) DESC`
    );

    connection.release();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch refund', message: error instanceof Error ? error.message : '' });
  }
});

// Get refund by ID (from refunds table)
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
            `SELECT r.*,
              u.name as customerName,
              u.email as customerEmail,
              u.phone as customerPhone
             FROM refunds r
             LEFT JOIN users u ON r.user_id = u.id
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

// Create refund (insert into refunds table)
router.post('/', async (req: Request, res: Response) => {
  const { bookingId, bookingNumber, totalAmount, refundAmount, userId } = req.body;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `INSERT INTO refunds (booking_id, booking_number, total_amount, refund_amount, user_id, status, created_at)
       VALUES (?, ?, ?, ?, ?, 'pending', NOW())`,
      [bookingId, bookingNumber, totalAmount, refundAmount, userId]
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

  // Map frontend status to refunds.status
  let refundStatus = status;
  if (status === 'SELESAI') refundStatus = 'completed';
  else if (status === 'PROSES') refundStatus = 'processing';
  else if (status === 'BATAL') refundStatus = 'rejected';

  try {
    const connection = await pool.getConnection();
    await connection.execute('UPDATE refunds SET status = ? WHERE id = ?', [refundStatus, id]);
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
    await connection.execute('DELETE FROM refunds WHERE id = ?', [id]);
    connection.release();

    res.json({ message: 'Refund deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete refund', message: error instanceof Error ? error.message : '' });
  }
});

export default router;
