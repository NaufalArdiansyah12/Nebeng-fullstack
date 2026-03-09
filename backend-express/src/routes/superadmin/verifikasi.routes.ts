import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// Get mitra verifications
router.get('/mitra', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        v.id,
        v.mitra_id as user_id,
        v.nama_lengkap,
        v.nik,
        v.tanggal_lahir,
        v.status,
        v.created_at,
        v.reviewed_at as tanggal_pengajuan
      FROM verifikasi_ktp_mitras v
      ORDER BY v.created_at DESC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error fetching mitra verifications:', error);
    res.status(500).json({ error: 'Failed to fetch mitra verifications', details: (error as Error).message });
  }
});

// Get customer verifications
router.get('/customer', async (req, res) => {
  try {
    // Get customers with verification data from verifikasi_ktp_customers
    const [rows] = await pool.query(`
      SELECT 
        v.id,
        v.user_id,
        v.nama_lengkap,
        v.nik,
        v.tanggal_lahir,
        v.status,
        v.created_at,
        v.created_at as tanggal_pengajuan,
        u.name as nama_user,
        u.email
      FROM verifikasi_ktp_customers v
      LEFT JOIN users u ON v.user_id = u.id
      WHERE u.role = 'customer'
      ORDER BY v.created_at DESC
    `);
    
    console.log('✅ Customer verifications fetched:', (rows as any[]).length);
    res.json(rows);
  } catch (error) {
    console.error('❌ Error fetching customer verifications:', error);
    res.status(500).json({ error: 'Failed to fetch customer verifications', details: (error as Error).message });
  }
});

// Update mitra verification status
router.patch('/mitra/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    // Update status in verifikasi_ktp_mitras table using mitra_id
    await pool.query(
      'UPDATE verifikasi_ktp_mitras SET status = ?, reviewed_at = NOW() WHERE mitra_id = ?',
      [status, id]
    );
    
    res.json({ message: 'Mitra verification status updated successfully' });
  } catch (error) {
    console.error('Error updating mitra verification status:', error);
    res.status(500).json({ error: 'Failed to update mitra verification status' });
  }
});

// Update customer verification status
router.patch('/customer/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    // Update status in verifikasi_ktp_customers table using user_id
    await pool.query(
      'UPDATE verifikasi_ktp_customers SET status = ?, reviewed_at = NOW() WHERE user_id = ?',
      [status, id]
    );
    
    console.log(`✅ Customer ${id} verification status updated to ${status}`);
    res.json({ message: 'Customer verification status updated successfully' });
  } catch (error) {
    console.error('❌ Error updating customer verification status:', error);
    res.status(500).json({ error: 'Failed to update customer verification status' });
  }
});

export default router;
