import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// PENTING: Route dengan path spesifik harus SEBELUM route dengan parameter :id

// Get all kendaraan from all mitra - HARUS SEBELUM /:id
router.get('/kendaraan/all', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        k.id,
        k.user_id,
        k.vehicle_type,
        k.name,
        k.plate_number,
        k.brand,
        k.model,
        k.color,
        k.year,
        k.is_active,
        k.created_at,
        k.updated_at,
        k.status,
        u.name as mitra_name,
        u.email as mitra_email
      FROM kendaraan_mitra k
      INNER JOIN users u ON k.user_id = u.id
      WHERE u.role = 'mitra'
      ORDER BY k.created_at DESC
    `);
    
    console.log('✅ All kendaraan query result:', rows);
    
    res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('❌ Error fetching all kendaraan:', error);
    res.status(500).json({ error: 'Failed to fetch kendaraan' });
  }
});

// Approve kendaraan (status pending -> approved) - HARUS SEBELUM /:id
router.patch('/kendaraan/:kendaraanId/approve', async (req, res) => {
  try {
    const { kendaraanId } = req.params;
    
    await pool.query(
      'UPDATE kendaraan_mitra SET status = ?, is_active = 1 WHERE id = ?',
      ['approved', kendaraanId]
    );
    
    console.log(`✅ Kendaraan ${kendaraanId} approved`);
    res.json({ message: 'Kendaraan approved successfully', success: true });
  } catch (error) {
    console.error('❌ Error approving kendaraan:', error);
    res.status(500).json({ error: 'Failed to approve kendaraan' });
  }
});

// Reject kendaraan (status pending -> rejected) - HARUS SEBELUM /:id
router.patch('/kendaraan/:kendaraanId/reject', async (req, res) => {
  try {
    const { kendaraanId } = req.params;
    
    await pool.query(
      'UPDATE kendaraan_mitra SET status = ?, is_active = 0 WHERE id = ?',
      ['rejected', kendaraanId]
    );
    
    console.log(`✅ Kendaraan ${kendaraanId} rejected`);
    res.json({ message: 'Kendaraan rejected successfully', success: true });
  } catch (error) {
    console.error('❌ Error rejecting kendaraan:', error);
    res.status(500).json({ error: 'Failed to reject kendaraan' });
  }
});

// Delete kendaraan (superadmin approve deletion) - HARUS SEBELUM /:id
router.delete('/kendaraan/:kendaraanId', async (req, res) => {
  try {
    const { kendaraanId } = req.params;
    
    await pool.query('DELETE FROM kendaraan_mitra WHERE id = ?', [kendaraanId]);
    
    console.log(`✅ Kendaraan ${kendaraanId} deleted`);
    res.json({ message: 'Kendaraan deleted successfully', success: true });
  } catch (error) {
    console.error('❌ Error deleting kendaraan:', error);
    res.status(500).json({ error: 'Failed to delete kendaraan' });
  }
});

// Get all mitra
router.get('/', async (req, res) => {
  try {
    // Get mitra users dengan join ke tabel KTP untuk dapat jenis kelamin
    const [rows] = await pool.query(`
      SELECT 
        u.id, 
        u.name, 
        u.email, 
        u.phone, 
        u.status,
        u.created_at,
        ktp.jenis_kelamin as gender
      FROM users u
      LEFT JOIN verifikasi_ktp_mitras ktp ON u.id = ktp.mitra_id
      WHERE u.role = 'mitra'
      ORDER BY u.created_at DESC
    `);
    
    console.log('✅ Mitra query result:', rows);
    
    // Transform data
    const transformed = (rows as any[]).map((m) => ({
      id: m.id,
      nama: m.name,
      email: m.email,
      no_tlp: m.phone || '',
      noTlp: m.phone || '',
      gender: m.gender || '-',
      status: m.status || 'active', // Status dari tabel users (enum: 'active', 'blocked')
      tanggal_daftar: m.created_at,
      createdAt: m.created_at,
      kode: m.id ? `MTR${String(m.id).padStart(4, '0')}` : ''
    }));
    
    console.log('✅ Transformed mitra data:', transformed);
    res.json(transformed);
  } catch (error) {
    console.error('❌ Error fetching mitra:', error);
    res.status(500).json({ error: 'Failed to fetch mitra' });
  }
});

// Get mitra by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get user data
    const [userRows] = await pool.query(`
      SELECT * FROM users WHERE id = ? AND role = 'mitra'
    `, [id]);
    
    if ((userRows as any[]).length === 0) {
      return res.status(404).json({ error: 'Mitra not found' });
    }
    
    const user = (userRows as any[])[0];
    
    // Get KTP data
    const [ktpRows] = await pool.query(`
      SELECT * FROM verifikasi_ktp_mitras WHERE mitra_id = ?
    `, [id]);
    
    // Get SIM data
    const [simRows] = await pool.query(`
      SELECT * FROM verifikasi_sim_mitras WHERE user_id = ?
    `, [id]);
    
    // Get SKCK data
    const [skckRows] = await pool.query(`
      SELECT * FROM verifikasi_skck_mitras WHERE user_id = ?
    `, [id]);
    
    // Get Bank data
    const [bankRows] = await pool.query(`
      SELECT * FROM verifikasi_bank_mitras WHERE user_id = ?
    `, [id]);
    
    // Get Kendaraan data
    const [vehicleRows] = await pool.query(`
      SELECT * FROM kendaraan_mitra WHERE user_id = ?
    `, [id]);
    
    // Transform response
    const response = {
      id: String(user.id),
      nama: user.name,
      email: user.email,
      no_tlp: user.phone || '',
      jenis_kelamin: user.gender || null,
      tempat_lahir: user.tempat_lahir || null,
      tanggal_lahir: user.date_of_birth || null,
      tanggal_daftar: user.created_at,
      layanan: 'Mobil',
      kode: `MTR${String(user.id).padStart(4, '0')}`,
      status: user.status || 'pending',
      profile_photo: user.profile_photo || user.profile_image || null,
      ktp_data: ktpRows && (ktpRows as any[]).length > 0 ? (ktpRows as any[])[0] : null,
      sim_data: simRows && (simRows as any[]).length > 0 ? (simRows as any[])[0] : null,
      skck_data: skckRows && (skckRows as any[]).length > 0 ? (skckRows as any[])[0] : null,
      bank_data: bankRows && (bankRows as any[]).length > 0 ? (bankRows as any[])[0] : null,
      kendaraan: vehicleRows || []
    };
    
    res.json(response);
  } catch (error) {
    console.error('Error fetching mitra:', error);
    res.status(500).json({ error: 'Failed to fetch mitra' });
  }
});

// Update mitra
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, phone, status } = req.body;
    
    const result = await pool.query(
      'UPDATE users SET name = ?, email = ?, phone = ?, status = ? WHERE id = ? AND role = "mitra"',
      [name, email, phone, status, id]
    );
    
    res.json({ message: 'Mitra updated successfully' });
  } catch (error) {
    console.error('Error updating mitra:', error);
    res.status(500).json({ error: 'Failed to update mitra' });
  }
});

// Delete mitra
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM users WHERE id = ? AND role = "mitra"', [id]);
    
    res.json({ message: 'Mitra deleted successfully' });
  } catch (error) {
    console.error('Error deleting mitra:', error);
    res.status(500).json({ error: 'Failed to delete mitra' });
  }
});

// Block mitra (set status to 'blocked')
router.post('/:id/block', async (req, res) => {
  try {
    const { id } = req.params;
    
    await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "mitra"', ['blocked', id]);
    
    console.log(`✅ Mitra ${id} blocked successfully`);
    res.json({ message: 'Mitra blocked successfully', success: true });
  } catch (error) {
    console.error('❌ Error blocking mitra:', error);
    res.status(500).json({ error: 'Failed to block mitra' });
  }
});

// Unblock mitra (set status to 'active')
router.post('/:id/unblock', async (req, res) => {
  try {
    const { id } = req.params;
    
    await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "mitra"', ['active', id]);
    
    console.log(`✅ Mitra ${id} unblocked successfully`);
    res.json({ message: 'Mitra unblocked successfully', success: true });
  } catch (error) {
    console.error('❌ Error unblocking mitra:', error);
    res.status(500).json({ error: 'Failed to unblock mitra' });
  }
});

// Block/unblock mitra (DEPRECATED - use POST /block or /unblock)
router.patch('/:id/block', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // 'active' or 'blocked'
    
    await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "mitra"', [status, id]);
    
    res.json({ message: `Mitra ${status === 'blocked' ? 'blocked' : 'unblocked'} successfully` });
  } catch (error) {
    console.error('Error blocking/unblocking mitra:', error);
    res.status(500).json({ error: 'Failed to block/unblock mitra' });
  }
});

// Update mitra status
router.patch('/:id/status', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    await pool.query('UPDATE users SET status = ? WHERE id = ? AND role = "mitra"', [status, id]);
    
    res.json({ message: 'Mitra status updated successfully' });
  } catch (error) {
    console.error('Error updating mitra status:', error);
    res.status(500).json({ error: 'Failed to update mitra status' });
  }
});

// Get mitra vehicles
router.get('/:id/kendaraan', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.query(
      'SELECT * FROM vehicles WHERE driver_id = ?',
      [id]
    );
    
    res.json(rows);
  } catch (error) {
    console.error('Error fetching mitra vehicles:', error);
    res.status(500).json({ error: 'Failed to fetch mitra vehicles' });
  }
});

// Get kendaraan by mitra ID
router.get('/:id/kendaraan', async (req, res) => {
  try {
    const { id } = req.params;
    
    const [rows] = await pool.query(`
      SELECT * FROM kendaraan_mitra WHERE user_id = ?
    `, [id]);
    
    res.json({
      success: true,
      data: rows
    });
  } catch (error) {
    console.error('❌ Error fetching mitra kendaraan:', error);
    res.status(500).json({ error: 'Failed to fetch mitra kendaraan' });
  }
});

// Create mitra vehicle
router.post('/:id/kendaraan', async (req, res) => {
  try {
    const { id } = req.params;
    const { vehicle_type, license_plate, brand, model, color, year } = req.body;
    
    const result = await pool.query(
      'INSERT INTO vehicles (driver_id, vehicle_type, license_plate, brand, model, color, year) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, vehicle_type, license_plate, brand, model, color, year]
    );
    
    res.json({ message: 'Vehicle created successfully', id: (result as any)[0].insertId });
  } catch (error) {
    console.error('Error creating mitra vehicle:', error);
    res.status(500).json({ error: 'Failed to create mitra vehicle' });
  }
});

// Update mitra vehicle
router.put('/:id/kendaraan/:vehicleId', async (req, res) => {
  try {
    const { id, vehicleId } = req.params;
    const { vehicle_type, license_plate, brand, model, color, year } = req.body;
    
    await pool.query(
      'UPDATE vehicles SET vehicle_type = ?, license_plate = ?, brand = ?, model = ?, color = ?, year = ? WHERE id = ? AND driver_id = ?',
      [vehicle_type, license_plate, brand, model, color, year, vehicleId, id]
    );
    
    res.json({ message: 'Vehicle updated successfully' });
  } catch (error) {
    console.error('Error updating mitra vehicle:', error);
    res.status(500).json({ error: 'Failed to update mitra vehicle' });
  }
});

// Delete mitra vehicle (DEPRECATED - use DELETE /kendaraan/:kendaraanId)
router.delete('/:id/kendaraan/:vehicleId', async (req, res) => {
  try {
    const { vehicleId } = req.params;
    await pool.query('DELETE FROM kendaraan_mitra WHERE id = ?', [vehicleId]);
    
    res.json({ message: 'Vehicle deleted successfully' });
  } catch (error) {
    console.error('Error deleting mitra vehicle:', error);
    res.status(500).json({ error: 'Failed to delete mitra vehicle' });
  }
});

export default router;
