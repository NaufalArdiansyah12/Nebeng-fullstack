import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../../db.ts';

// Function to calculate gender from NIK
function calculateGender(nik: string | null): string | null {
  if (!nik || nik.length < 16) return null;
  const dd = parseInt(nik.substring(6, 8));
  return dd > 31 ? 'Perempuan' : 'Laki-laki';
}

const router = express.Router();

// Get all mitra
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    
    const [rows] = await connection.query(
      `SELECT 
        u.id, 
        u.name as nama, 
        u.email, 
        u.phone as no_tlp, 
        'Motor' as layanan, 
        v.status, 
        u.created_at as tanggal_daftar 
       FROM users u
       LEFT JOIN verifikasi_ktp_mitras v ON u.id = v.mitra_id
       WHERE u.role = 'mitra' 
       ORDER BY u.created_at DESC`
    );
    connection.release();

    res.json(rows);   
  } catch (error) {
    console.error('❌ GET /api/mitra error:', error);
    res.status(500).json({ error: 'Failed to fetch mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Get mitra by ID with kendaraan, KTP, and SIM data
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();
    
    console.log(`📝 Fetching mitra with ID: ${id}`);
    
    // Get mitra basic data
    const [mitraRows] = await connection.query(
      `SELECT
        u.id,
        u.name as nama,
        u.email,
        u.phone as no_tlp,
        u.created_at as tanggal_daftar
       FROM users u
       WHERE u.id = ? AND u.role = 'mitra'`,
      [id]
    );
    
    console.log('✅ Mitra rows:', mitraRows);
    
    if (!Array.isArray(mitraRows) || mitraRows.length === 0) {
      connection.release();
      return res.status(404).json({ error: 'Mitra not found' });
    }
    
    // Get kendaraan data
    const [kendaraanRows] = await connection.query(
      'SELECT * FROM kendaraan_mitra WHERE user_id = ?', 
      [id]
    );
    
    console.log('✅ Kendaraan rows:', kendaraanRows);
    
    // Get KTP data
    const [ktpRows] = await connection.query(
      `SELECT 
        id,
        mitra_id,
        nama_lengkap,
        nik,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        photo_ktp,
        status,
        reviewer_id,
        reviewed_at,
        meta,
        created_at,
        updated_at
       FROM verifikasi_ktp_mitras 
       WHERE mitra_id = ?`, 
      [id]
    );
    
    console.log('✅ KTP rows:', ktpRows);
    
    // ✅ Get SIM data
    const [simRows] = await connection.query(
      `SELECT
        id,
        user_id,
        nama_lengkap,
        sim_number,
        sim_type,
        sim_expiry_date,
        sim_photo,
        status,
        rejection_reason,
        verified_at,
        created_at,
        updated_at
       FROM verifikasi_sim_mitras
       WHERE user_id = ?`,
      [id]
    );

    console.log('✅ SIM rows:', simRows);

    // ✅ Get SKCK data
    const [skckRows] = await connection.query(
      `SELECT
        id,
        user_id,
        skck_number,
        skck_name,
        skck_expiry_date,
        skck_photo,
        status,
        rejection_reason,
        verified_at,
        created_at,
        updated_at
       FROM verifikasi_skck_mitras
       WHERE user_id = ?`,
      [id]
    );

    console.log('✅ SKCK rows:', skckRows);

    connection.release();

    const mitraData = mitraRows[0] as any;
    const ktpData = Array.isArray(ktpRows) && ktpRows.length > 0 ? ktpRows[0] as any : null;
    const simData = Array.isArray(simRows) && simRows.length > 0 ? simRows[0] as any : null;
    const skckData = Array.isArray(skckRows) && skckRows.length > 0 ? skckRows[0] as any : null;

    // Database didahulukan, hitungan NIK sebagai cadangan
    const responseData = {
      ...mitraData,
      jenis_kelamin: ktpData?.jenis_kelamin || calculateGender(ktpData?.nik || null),
      kendaraan: Array.isArray(kendaraanRows) ? kendaraanRows : [],
      ktp_data: ktpData,
      sim_data: simData,
      skck_data: skckData
    };
    
    console.log('📤 Sending response:', responseData);
    res.json(responseData);
    
  } catch (error) {
    console.error('❌ GET /api/mitra/:id error:', error);
    console.error('❌ Error details:', error instanceof Error ? error.stack : error);
    
    if (connection) {
      connection.release();
    }
    
    res.status(500).json({ 
      error: 'Failed to fetch mitra', 
      message: error instanceof Error ? error.message : 'Unknown error',
      details: error instanceof Error ? error.stack : String(error)
    });
  }
});

// Get KTP verification data for specific mitra
router.get('/:id/ktp', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();
    
    console.log(`📝 Fetching KTP data for mitra ID: ${id}`);
    
    const [rows] = await connection.query(
      `SELECT 
        v.id,
        v.mitra_id,
        v.nama_lengkap,
        v.nik,
        v.tanggal_lahir,
        v.jenis_kelamin,
        v.alamat,
        v.photo_ktp,
        v.status,
        v.reviewer_id,
        v.reviewed_at,
        v.meta,
        v.created_at,
        v.updated_at,
        u.name as mitra_nama,
        u.email as mitra_email
       FROM verifikasi_ktp_mitras v
       LEFT JOIN users u ON v.mitra_id = u.id
       WHERE v.mitra_id = ?`, 
      [id]
    );
    
    console.log('✅ KTP data found:', rows);
    
    connection.release();

    if (Array.isArray(rows) && rows.length > 0) {
      res.json(rows[0]);
    } else {
      res.status(404).json({ error: 'KTP data not found for this mitra' });
    }
  } catch (error) {
    console.error('❌ GET /api/mitra/:id/ktp error:', error);
    console.error('❌ Error details:', error instanceof Error ? error.stack : error);
    
    if (connection) {
      connection.release();
    }
    
    res.status(500).json({ 
      error: 'Failed to fetch KTP data', 
      message: error instanceof Error ? error.message : 'Unknown error',
      details: error instanceof Error ? error.stack : String(error)
    });
  }
});

// Create mitra
router.post('/', async (req: Request, res: Response) => {
  const { nama, email, noTlp, password } = req.body;

  try {
    const connection = await pool.getConnection();
    
    const [result] = await connection.execute(
      `INSERT INTO users (name, email, phone, password, role)
       VALUES (?, ?, ?, ?, 'mitra')`,
      [nama, email, noTlp, password]
    );
    connection.release();

    res.status(201).json({ id: (result as any).insertId, message: 'Mitra created successfully' });
  } catch (error) {
    console.error('❌ POST /api/mitra error:', error);
    res.status(500).json({ error: 'Failed to create mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Update mitra
router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { nama, email, noTlp, jenisKelamin, tanggalLahir, ktp, sim } = req.body;

  let connection;
  try {
    connection = await pool.getConnection();
    
    // Start transaction
    await connection.beginTransaction();
    
    console.log(`📝 Updating mitra ${id}:`, { nama, email, noTlp, jenisKelamin, tanggalLahir, ktp, sim });
    
    // Update data di tabel users
    await connection.execute(
      `UPDATE users 
       SET name = ?, email = ?, phone = ?
       WHERE id = ? AND role = 'mitra'`,
      [nama, email, noTlp || null, id]
    );
    
    // Update data di tabel verifikasi_ktp_mitras
    if (ktp) {
      const { nama_lengkap, nik, alamat, tanggal_lahir } = ktp;
      
      // Check if KTP data exists
      const [ktpCheck] = await connection.query(
        'SELECT id FROM verifikasi_ktp_mitras WHERE mitra_id = ?',
        [id]
      );
      
      if (Array.isArray(ktpCheck) && ktpCheck.length > 0) {
        await connection.execute(
          `UPDATE verifikasi_ktp_mitras 
           SET nama_lengkap = ?, nik = ?, alamat = ?, tanggal_lahir = ?, jenis_kelamin = ?
           WHERE mitra_id = ?`,
          [nama_lengkap || null, nik || null, alamat || null, tanggal_lahir || null, jenisKelamin || null, id]
        );
      } else {
        await connection.execute(
          `INSERT INTO verifikasi_ktp_mitras (mitra_id, nama_lengkap, nik, alamat, tanggal_lahir, jenis_kelamin, status)
           VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
          [id, nama_lengkap || null, nik || null, alamat || null, tanggal_lahir || null, jenisKelamin || null]
        );
      }
    }
    
    // ✅ Update data di tabel verifikasi_sim_mitras
    if (sim) {
      const { nama_lengkap, sim_number, sim_type, sim_expiry_date } = sim;
      
      // Check if SIM data exists
      const [simCheck] = await connection.query(
        'SELECT id FROM verifikasi_sim_mitras WHERE user_id = ?',
        [id]
      );
      
      if (Array.isArray(simCheck) && simCheck.length > 0) {
        await connection.execute(
          `UPDATE verifikasi_sim_mitras 
           SET nama_lengkap = ?, sim_number = ?, sim_type = ?, sim_expiry_date = ?
           WHERE user_id = ?`,
          [nama_lengkap || null, sim_number || null, sim_type || null, sim_expiry_date || null, id]
        );
      } else {
        await connection.execute(
          `INSERT INTO verifikasi_sim_mitras (user_id, nama_lengkap, sim_number, sim_type, sim_expiry_date, status)
           VALUES (?, ?, ?, ?, ?, 'approved')`,
          [id, nama_lengkap || null, sim_number || null, sim_type || null, sim_expiry_date || null]
        );
      }
    }
    
    // Commit transaction
    await connection.commit();
    connection.release();

    console.log(`✅ Mitra ${id} updated successfully`);
    res.json({ message: 'Mitra updated successfully' });
  } catch (error) {
    // Rollback on error
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    
    console.error('❌ PUT /api/mitra/:id error:', error);
    res.status(500).json({ 
      error: 'Failed to update mitra', 
      message: error instanceof Error ? error.message : '' 
    });
  }
});

// Delete mitra (soft delete)
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      `UPDATE verifikasi_ktp_mitras SET status = 'inactive' WHERE mitra_id = ?`, 
      [id]
    );

    connection.release();

    res.json({ message: 'Mitra deleted (status updated to inactive)' });
  } catch (error) {
    console.error('❌ DELETE /api/mitra/:id error:', error);
    res.status(500).json({ error: 'Failed to delete mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Update mitra status
router.patch('/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  // Map frontend status to database status
  const statusMap: Record<string, string> = {
    'PENGAJUAN': 'pending',
    'TERVERIFIKASI': 'approved',
    'DITOLAK': 'rejected',
    'DIBLOCK': 'blocked'
  };

  const dbStatus = statusMap[status] || status.toLowerCase();

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_mitras SET status = ? WHERE mitra_id = ?', 
      [dbStatus, id]
    );
    connection.release();

    console.log(`✅ Mitra ${id} status updated to ${dbStatus} (${status})`);
    res.json({ message: 'Mitra status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/mitra/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update mitra status', message: error instanceof Error ? error.message : '' });
  }
});

// Block mitra
router.post('/:id/block', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();
    
    // First check if record exists
    const [existing] = await connection.query(
      'SELECT id FROM verifikasi_ktp_mitras WHERE mitra_id = ?',
      [id]
    );
    
    if (Array.isArray(existing) && existing.length > 0) {
      // Record exists, update it
      await connection.execute(
        'UPDATE verifikasi_ktp_mitras SET status = ? WHERE mitra_id = ?', 
        ['blocked', id]
      );
      console.log(`✅ Mitra ${id} blocked (updated existing record)`);
    } else {
      // Record doesn't exist, insert new record
      await connection.execute(
        'INSERT INTO verifikasi_ktp_mitras (mitra_id, status) VALUES (?, ?)',
        [id, 'blocked']
      );
      console.log(`✅ Mitra ${id} blocked (created new record)`);
    }
    
    connection.release();
    res.json({ message: 'Mitra blocked successfully' });
  } catch (error) {
    console.error('❌ POST /api/mitra/:id/block error:', error);
    if (connection) {
      connection.release();
    }
    res.status(500).json({ error: 'Failed to block mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Unblock mitra
router.post('/:id/unblock', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();
    
    // First check if record exists
    const [existing] = await connection.query(
      'SELECT id FROM verifikasi_ktp_mitras WHERE mitra_id = ?',
      [id]
    );
    
    if (Array.isArray(existing) && existing.length > 0) {
      // Record exists, update it
      await connection.execute(
        'UPDATE verifikasi_ktp_mitras SET status = ? WHERE mitra_id = ?', 
        ['approved', id]
      );
      console.log(`✅ Mitra ${id} unblocked (updated record to approved)`);
    } else {
      // Record doesn't exist, insert new record with approved status
      await connection.execute(
        'INSERT INTO verifikasi_ktp_mitras (mitra_id, status) VALUES (?, ?)',
        [id, 'approved']
      );
      console.log(`✅ Mitra ${id} unblocked (created new record with approved status)`);
    }
    
    connection.release();
    res.json({ message: 'Mitra unblocked successfully' });
  } catch (error) {
    console.error('❌ POST /api/mitra/:id/unblock error:', error);
    if (connection) {
      connection.release();
    }
    res.status(500).json({ error: 'Failed to unblock mitra', message: error instanceof Error ? error.message : '' });
  }
});

/* ===========================
   GET semua kendaraan dari semua mitra (with role mitra)
   =========================== */
router.get('/kendaraan/all', async (req, res) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT
        km.id,
        km.user_id,
        u.name as mitra_nama,
        km.vehicle_type,
        km.name,
        km.plate_number,
        km.color,
        km.year,
        km.created_at,
        km.updated_at
       FROM kendaraan_mitra km
       LEFT JOIN users u ON km.user_id = u.id
       WHERE u.role = 'mitra'
       ORDER BY km.created_at DESC`
    );
    connection.release();

    res.json({
      success: true,
      data: rows as any[]
    });
  } catch (error) {
    console.error('❌ GET /api/mitra/kendaraan/all error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch kendaraan',
      error: error instanceof Error ? error.message : ''
    });
  }
});

/* ===========================
   GET kendaraan untuk mitra tertentu
   =========================== */
router.get('/:mitraId/kendaraan', async (req, res) => {
  const { mitraId } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT
        km.id,
        km.user_id,
        u.name as mitra_nama,
        km.vehicle_type,
        km.name,
        km.plate_number,
        km.color,
        km.year,
        km.created_at,
        km.updated_at
       FROM kendaraan_mitra km
       LEFT JOIN users u ON km.user_id = u.id
       WHERE km.user_id = ?`,
      [mitraId]
    );
    connection.release();

    res.json({
      success: true,
      data: rows as any[]
    });
  } catch (error) {
    console.error('❌ GET /api/mitra/:mitraId/kendaraan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch kendaraan',
      error: error instanceof Error ? error.message : ''
    });
  }
});

/* ===========================
   GET detail kendaraan by ID (ambil data dari kendaraan itu sendiri)
   =========================== */
router.get('/kendaraan/detail/:kendaraanId', async (req, res) => {
  const { kendaraanId } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.execute(
      `SELECT km.*, u.name as mitra_nama, u.role
       FROM kendaraan_mitra km
       LEFT JOIN users u ON km.user_id = u.id
       WHERE km.id = ? AND u.role = 'mitra'`,
      [kendaraanId]
    );
    connection.release();

    const data = rows as any[];

    if (data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Kendaraan not found or not from mitra'
      });
    }

    res.json({
      success: true,
      data: data[0]
    });
  } catch (error) {
    console.error('❌ GET detail kendaraan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch kendaraan detail'
    });
  }
});

/* ===========================
   GET detail kendaraan (with mitra validation)
   =========================== */
router.get('/:mitraId/kendaraan/:kendaraanId', async (req, res) => {
  const { mitraId, kendaraanId } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.execute(
      `SELECT *
       FROM kendaraan_mitra
       WHERE id = ? AND user_id = ?`,
      [kendaraanId, mitraId]
    );
    connection.release();

    const data = rows as any[];

    if (data.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Kendaraan not found'
      });
    }

    res.json({
      success: true,
      data: data[0]
    });
  } catch (error) {
    console.error('❌ GET detail kendaraan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch kendaraan detail'
    });
  }
});

/* ===========================
   ADD kendaraan
   =========================== */
router.post('/:id/kendaraan', async (req, res) => {
  const { id } = req.params;
  const { jenisKendaraan, merkKendaraan, platNomor, tahunPembuatan } = req.body;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `INSERT INTO kendaraan_mitra 
       (user_id, vehicle_type, name, plate_number, brand, model, color, year, seats, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, jenisKendaraan, merkKendaraan, platNomor, '', '', '', tahunPembuatan, 1, 1]
    );
    connection.release();

    const insertResult = result as any;

    res.status(201).json({
      success: true,
      id: insertResult.insertId,
      message: 'Kendaraan added successfully'
    });
  } catch (error) {
    console.error('❌ POST kendaraan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add kendaraan'
    });
  }
});

/* ===========================
   UPDATE kendaraan
   =========================== */
router.put('/:mitraId/kendaraan/:kendaraanId', async (req, res) => {
  const { mitraId, kendaraanId } = req.params;
  const { jenisKendaraan, merkKendaraan, platNomor, tahunPembuatan } = req.body;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `UPDATE kendaraan_mitra 
       SET vehicle_type = ?, name = ?, plate_number = ?, year = ?
       WHERE id = ? AND user_id = ?`,
      [jenisKendaraan, merkKendaraan, platNomor, tahunPembuatan, kendaraanId, mitraId]
    );
    connection.release();

    const updateResult = result as any;

    if (updateResult.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Kendaraan not found'
      });
    }

    res.json({
      success: true,
      message: 'Kendaraan updated successfully'
    });
  } catch (error) {
    console.error('❌ PUT kendaraan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update kendaraan'
    });
  }
});

/* ===========================
   DELETE kendaraan
   =========================== */
router.delete('/:mitraId/kendaraan/:kendaraanId', async (req, res) => {
  const { mitraId, kendaraanId } = req.params;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `DELETE FROM kendaraan_mitra
       WHERE id = ? AND user_id = ?`,
      [kendaraanId, mitraId]
    );
    connection.release();

    const deleteResult = result as any;

    if (deleteResult.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Kendaraan not found'
      });
    }

    res.json({
      success: true,
      message: 'Kendaraan deleted successfully'
    });
  } catch (error) {
    console.error('❌ DELETE kendaraan error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete kendaraan'
    });
  }
});


export default router;
