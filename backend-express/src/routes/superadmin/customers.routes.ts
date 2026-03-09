import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// Get all customers
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT * FROM users WHERE role = 'customer' ORDER BY created_at DESC
    `);
    
    // Transform rows to match Mitra response shape, but omit gender
    const transformed = (rows as any[]).map((u) => ({
      id: String(u.id),
      nama: u.name,
      email: u.email,
      no_tlp: u.phone,
      noTlp: u.phone,
      alamat: u.address || null,
      status: u.status,
      tanggal_daftar: u.created_at,
      tanggal: u.created_at,
      created_at: u.created_at,
      updated_at: u.updated_at,
      layanan: 'Customer',
      kode: `#${u.id}`,
    }));

    res.json(transformed);
  } catch (error) {
    console.error('Error fetching customers:', error);
    res.status(500).json({ error: 'Failed to fetch customers' });
  }
});

// Get customer by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.query(`
      SELECT * FROM users WHERE id = ? AND role = 'customer'
    `, [id]);
    
    if ((rows as any[]).length === 0) {
      return res.status(404).json({ error: 'Customer not found' });
    }
    
    const u = (rows as any[])[0];

    const transformed = {
      id: String(u.id),
      nama: u.name,
      email: u.email,
      no_tlp: u.phone,
      noTlp: u.phone,
      alamat: u.address || null,
      status: u.status,
      tanggal_daftar: u.created_at,
      tanggal: u.created_at,
      created_at: u.created_at,
      updated_at: u.updated_at,
      layanan: 'Customer',
      kode: `#${u.id}`,
    };

    res.json(transformed);
  } catch (error) {
    console.error('Error fetching customer:', error);
    res.status(500).json({ error: 'Failed to fetch customer' });
  }
});

// Block customer
router.post('/:id/block', async (req, res) => {
  const { id } = req.params;
  try {
    const connection = await pool.getConnection();

    // Set user status to 'blocked' in users table (verifikasi.status enum doesn't include 'blocked')
    await connection.execute(
      'UPDATE users SET status = ? WHERE id = ? AND role = "customer"',
      ['blocked', id]
    );

    // Fetch updated customer
    const [customerRows] = await connection.query(
      `SELECT u.id, u.name as nama, u.email, u.phone as no_tlp, u.status as status, u.created_at as tanggal_daftar
       FROM users u
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' AND u.id = ?`,
      [id]
    );

    connection.release();

    if (Array.isArray(customerRows) && customerRows.length > 0) {
      // transform to match other responses
      const u = (customerRows as any[])[0];
      const transformed = {
        id: String(u.id),
        nama: u.nama,
        email: u.email,
        no_tlp: u.no_tlp,
        status: u.status,
        tanggal_daftar: u.tanggal_daftar,
      };
      return res.json(transformed);
    }

    res.json({ message: 'Customer blocked successfully' });
  } catch (error) {
    console.error('Error blocking customer:', error);
    res.status(500).json({ error: 'Failed to block customer' });
  }
});

// Unblock customer
router.post('/:id/unblock', async (req, res) => {
  const { id } = req.params;
  try {
    const connection = await pool.getConnection();

    // Set user status back to 'active'
    await connection.execute(
      'UPDATE users SET status = ? WHERE id = ? AND role = "customer"',
      ['active', id]
    );

    const [customerRows] = await connection.query(
      `SELECT u.id, u.name as nama, u.email, u.phone as no_tlp, u.status as status, u.created_at as tanggal_daftar
       FROM users u
       LEFT JOIN verifikasi_ktp_customers v ON u.id = v.user_id
       WHERE u.role = 'customer' AND u.id = ?`,
      [id]
    );

    connection.release();

    if (Array.isArray(customerRows) && customerRows.length > 0) {
      const u = (customerRows as any[])[0];
      const transformed = {
        id: String(u.id),
        nama: u.nama,
        email: u.email,
        no_tlp: u.no_tlp,
        status: u.status,
        tanggal_daftar: u.tanggal_daftar,
      };
      return res.json(transformed);
    }

    res.json({ message: 'Customer unblocked successfully' });
  } catch (error) {
    console.error('Error unblocking customer:', error);
    res.status(500).json({ error: 'Failed to unblock customer' });
  }
});

export default router;
