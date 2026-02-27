import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all laporan (customer ratings and driver ratings)
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();

    // Get customer ratings with rating below 3 (1 and 2)
    const [customerRatings] = await connection.query(
      `SELECT
        cr.id,
        cr.booking_id,
        cr.booking_type,
        cr.mitra_id,
        cr.customer_id,
        cr.rating,
        cr.feedback,
        cr.proof_image,
        cr.created_at,
        'customer_rating' as type,
        u_customer.name as customer_name,
        u_customer.phone as customer_phone,
        u_mitra.name as mitra_name,
        u_mitra.phone as mitra_phone
       FROM customer_ratings cr
       LEFT JOIN users u_customer ON cr.customer_id = u_customer.id
       LEFT JOIN users u_mitra ON cr.mitra_id = u_mitra.id
       WHERE cr.rating < 3
       ORDER BY cr.created_at DESC`
    );

    // Get driver ratings with rating below 3 (1 and 2)
    const [driverRatings] = await connection.query(
      `SELECT
        dr.id,
        dr.booking_id,
        dr.booking_type,
        dr.user_id,
        dr.driver_id,
        dr.rating,
        dr.review,
        dr.created_at,
        'driver_rating' as type,
        u_customer.name as customer_name,
        u_customer.phone as customer_phone,
        u_driver.name as driver_name,
        u_driver.phone as driver_phone
       FROM driver_ratings dr
       LEFT JOIN users u_customer ON dr.user_id = u_customer.id
       LEFT JOIN users u_driver ON dr.driver_id = u_driver.id
       WHERE dr.rating < 3
       ORDER BY dr.created_at DESC`
    );

    console.log('🔍 Driver ratings found:', driverRatings);

    connection.release();

    // Combine and transform the data
    const allRatings = [
      ...(Array.isArray(customerRatings) ? customerRatings : []),
      ...(Array.isArray(driverRatings) ? driverRatings : [])
    ];

    const transformedData = allRatings.map((rating: any) => ({
      id: String(rating.id),
      no_order: `BK${String(rating.booking_id).padStart(4, '0')}`,
      namaCustomer: rating.customer_name || 'Unknown Customer',
      customer_id: rating.customer_id || rating.user_id,
      tanggal_laporan: rating.created_at,
      layanan: rating.booking_type || 'Motor',
      deskripsi_laporan: rating.type === 'customer_rating' ? (rating.feedback || 'No feedback') : (rating.review || 'No review'),
      status: 'active',
      customerPhone: rating.customer_phone || '',
      mitra_id: rating.type === 'customer_rating' ? rating.mitra_id : rating.driver_id,
      namaMitra: rating.type === 'customer_rating' ? (rating.mitra_name || 'Unknown Driver') : (rating.driver_name || 'Unknown Driver'),
      mitraPhone: rating.type === 'customer_rating' ? (rating.mitra_phone || '') : (rating.driver_phone || ''),
      rating: rating.rating,
      type: rating.type,
      pickup_location: rating.pickup_location,
      destination: rating.destination
    }));

    res.json(transformedData);
  } catch (error) {
    console.error('❌ GET /api/laporan error:', error);
    res.status(500).json({ error: 'Failed to fetch laporan', message: error instanceof Error ? error.message : '' });
  }
});

// Get mitra by ID with kendaraan and KTP data
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();
    
    console.log(`📝 Fetching mitra with ID: ${id}`);
    
    // Get mitra basic data - ambil kolom yang ada di tabel users termasuk gender
    const [mitraRows] = await connection.query(
      `SELECT 
        u.id, 
        u.name as nama, 
        u.email, 
        u.phone as no_tlp,
        u.gender as jenis_kelamin,
        u.created_at as tanggal_daftar 
       FROM users u
       WHERE u.role = 'mitra' AND u.id = ?`, 
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
    
    // Get KTP verification data - hanya ambil kolom yang ada
    const [ktpRows] = await connection.query(
      `SELECT 
        id,
        mitra_id,
        nama_lengkap,
        nik,
        tanggal_lahir,
        alamat,
        photo_wajah,
        photo_ktp,
        photo_ktp_wajah,
        status,
        reviewer_id,
        reviewed_at,
        created_at,
        updated_at
       FROM verifikasi_ktp_mitras 
       WHERE mitra_id = ?`, 
      [id]
    );
    
    console.log('✅ KTP rows:', ktpRows);
    
    connection.release();

    const responseData = { 
      ...mitraRows[0], 
      kendaraan: Array.isArray(kendaraanRows) ? kendaraanRows : [],
      ktp_data: Array.isArray(ktpRows) && ktpRows.length > 0 ? ktpRows[0] : null
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
        v.alamat,
        v.photo_wajah,
        v.photo_ktp,
        v.photo_ktp_wajah,
        v.status,
        v.reviewer_id,
        v.reviewed_at,
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
  const { nama, email, noTlp } = req.body;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      `UPDATE users 
       SET name = ?, email = ?, phone = ?
       WHERE id = ? AND role = 'mitra'`,
      [nama, email, noTlp, id]
    );
    connection.release();

    res.json({ message: 'Mitra updated successfully' });
  } catch (error) {
    console.error('❌ PUT /api/mitra/:id error:', error);
    res.status(500).json({ error: 'Failed to update mitra', message: error instanceof Error ? error.message : '' });
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

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_mitras SET status = ? WHERE mitra_id = ?', 
      [status, id]
    );
    connection.release();

    res.json({ message: 'Mitra status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/mitra/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update mitra status', message: error instanceof Error ? error.message : '' });
  }
});

// Block mitra
router.post('/:id/block', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_mitras SET status = ? WHERE mitra_id = ?', 
      ['suspended', id]
    );
    connection.release();

    res.json({ message: 'Mitra blocked successfully' });
  } catch (error) {
    console.error('❌ POST /api/mitra/:id/block error:', error);
    res.status(500).json({ error: 'Failed to block mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Unblock mitra
router.post('/:id/unblock', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    await connection.execute(
      'UPDATE verifikasi_ktp_mitras SET status = ? WHERE mitra_id = ?', 
      ['active', id]
    );
    connection.release();

    res.json({ message: 'Mitra unblocked successfully' });
  } catch (error) {
    console.error('❌ POST /api/mitra/:id/unblock error:', error);
    res.status(500).json({ error: 'Failed to unblock mitra', message: error instanceof Error ? error.message : '' });
  }
});

// Get kendaraan mitra
router.get('/:id/kendaraan', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(
      `SELECT 
        km.id,
        km.user_id,
        u.name as mitra_nama,
        km.vehicle_type as jenis_kendaraan,
        km.name as merek_kendaraan,
        km.plate_number as plat_nomor,
        km.brand,
        km.model,
        km.color as warna,
        km.year,
        km.is_active,
        km.created_at,
        km.updated_at
       FROM kendaraan_mitra km
       LEFT JOIN users u ON km.user_id = u.id
       WHERE km.user_id = ?`, 
      [id]
    );
    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/mitra/:id/kendaraan error:', error);
    res.status(500).json({ error: 'Failed to fetch kendaraan', message: error instanceof Error ? error.message : '' });
  }
});

// Add kendaraan
router.post('/:id/kendaraan', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { jenisKendaraan, merkKendaraan, platNomor, tahunPembuatan } = req.body;

  try {
    const connection = await pool.getConnection();
    const [result] = await connection.execute(
      `INSERT INTO kendaraan_mitra (user_id, vehicle_type, name, plate_number, brand, model, color, year, seats, is_active)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, jenisKendaraan, merkKendaraan, platNomor, '', '', '', tahunPembuatan, 1, 1]
    );
    connection.release();

    res.status(201).json({ id: (result as any).insertId, message: 'Kendaraan added successfully' });
  } catch (error) {
    console.error('❌ POST /api/mitra/:id/kendaraan error:', error);
    res.status(500).json({ error: 'Failed to add kendaraan', message: error instanceof Error ? error.message : '' });
  }
});

// Update kendaraan
router.put('/:mitraId/kendaraan/:kendaraanId', async (req: Request, res: Response) => {
  const { mitraId, kendaraanId } = req.params;
  const { jenisKendaraan, merkKendaraan, platNomor, tahunPembuatan } = req.body;

  try {
    const connection = await pool.getConnection();
    await connection.execute(
      `UPDATE kendaraan_mitra 
       SET vehicle_type = ?, name = ?, plate_number = ?, year = ?
       WHERE id = ? AND user_id = ?`,
      [jenisKendaraan, merkKendaraan, platNomor, tahunPembuatan, kendaraanId, mitraId]
    );
    connection.release();

    res.json({ message: 'Kendaraan updated successfully' });
  } catch (error) {
    console.error('❌ PUT /api/mitra/:mitraId/kendaraan/:kendaraanId error:', error);
    res.status(500).json({ error: 'Failed to update kendaraan', message: error instanceof Error ? error.message : '' });
  }
});

// Delete kendaraan
router.delete('/:mitraId/kendaraan/:kendaraanId', async (req: Request, res: Response) => {
  const { mitraId, kendaraanId } = req.params;

  try {
    const connection = await pool.getConnection();
    await connection.execute(
      'DELETE FROM kendaraan_mitra WHERE id = ? AND user_id = ?',
      [kendaraanId, mitraId]
    );
    connection.release();

    res.json({ message: 'Kendaraan deleted successfully' });
  } catch (error) {
    console.error('❌ DELETE /api/mitra/:mitraId/kendaraan/:kendaraanId error:', error);
    res.status(500).json({ error: 'Failed to delete kendaraan', message: error instanceof Error ? error.message : '' });
  }
});

// Respond to laporan (add tanggapan and optionally update status)
router.patch('/:id/respond', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { tanggapan, status } = req.body;

  try {
    const connection = await pool.getConnection();
    
    // Check which table has this ID
    const [customerData] = await connection.query(
      'SELECT id FROM customer_ratings WHERE id = ?',
      [id]
    );
    
    const isCustomerRating = Array.isArray(customerData) && customerData.length > 0;
    const tableName = isCustomerRating ? 'customer_ratings' : 'driver_ratings';
    
    // Build the update query
    let query = `UPDATE ${tableName} SET `;
    const params: any[] = [];
    
    if (tanggapan !== undefined) {
      query += 'admin_response = ?';
      params.push(tanggapan);
    }
    
    if (status !== undefined) {
        if (params.length > 0) query += ', ';
      query += 'status = ?';
      params.push(status);
    }
    
    if (params.length === 0) {
      connection.release();
      return res.status(400).json({ error: 'No fields to update' });
    }
    
    query += ', updated_at = NOW() WHERE id = ?';
    params.push(id);
    
    await connection.execute(query, params);
    connection.release();

    res.json({ message: 'Laporan responded successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/laporan/:id/respond error:', error);
    res.status(500).json({ error: 'Failed to respond to laporan', message: error instanceof Error ? error.message : '' });
  }
});

export default router;
