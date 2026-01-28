import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all pesanan (gabungan dari 4 tabel tebengan)
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(`
      SELECT 
        id,
        booking_number as no_order,
        customerName as namaCustomer,
        NULL as namaDriver,
        departure_date as tanggal,
        layanan,
        price as harga,
        status
      FROM (
        -- Tebengan Motor
        SELECT 
          tm.id,
          CONCAT('TM-', tm.id) as booking_number,
          uc.name as customerName,
          tm.departure_date,
          'Motor' as layanan,
          tm.price,
          tm.status
        FROM tebengan_motor tm
        LEFT JOIN users uc ON tm.user_id = uc.id
        
        UNION ALL
        
        -- Tebengan Mobil
        SELECT 
          tmb.id,
          CONCAT('TMB-', tmb.id) as booking_number,
          uc.name as customerName,
          tmb.departure_date,
          'Mobil' as layanan,
          tmb.price,
          tmb.status
        FROM tebengan_mobil tmb
        LEFT JOIN users uc ON tmb.user_id = uc.id
        
        UNION ALL
        
        -- Tebengan Barang
        SELECT 
          tb.id,
          CONCAT('TB-', tb.id) as booking_number,
          uc.name as customerName,
          tb.departure_date,
          'Barang' as layanan,
          tb.price,
          tb.status
        FROM tebengan_barang tb
        LEFT JOIN users uc ON tb.user_id = uc.id
        
        UNION ALL
        
        -- Tebengan Titip Barang
        SELECT 
          ttb.id,
          CONCAT('TTB-', ttb.id) as booking_number,
          uc.name as customerName,
          ttb.departure_date,
          'Titip Barang' as layanan,
          ttb.price,
          ttb.status
        FROM tebengan_titip_barang ttb
        LEFT JOIN users uc ON ttb.user_id = uc.id
      ) AS all_tebengan
      ORDER BY departure_date DESC
    `);
    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/pesanan error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch pesanan', 
      message: error instanceof Error ? error.message : '' 
    });
  }
});

// Get pesanan by ID with details
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    // Cek di tabel mana pesanan ini ada
    const [motorRows] = await connection.query<any[]>(
      `SELECT 
        tm.*, 
        'Motor' as layanan,
        uc.name as customerName, 
        uc.email as customerEmail, 
        uc.phone as customerPhone
       FROM tebengan_motor tm
       LEFT JOIN users uc ON tm.user_id = uc.id
       WHERE tm.id = ?`,
      [id]
    );

    const [mobilRows] = await connection.query<any[]>(
      `SELECT 
        tmb.*, 
        'Mobil' as layanan,
        uc.name as customerName, 
        uc.email as customerEmail, 
        uc.phone as customerPhone
       FROM tebengan_mobil tmb
       LEFT JOIN users uc ON tmb.user_id = uc.id
       WHERE tmb.id = ?`,
      [id]
    );

    const [barangRows] = await connection.query<any[]>(
      `SELECT 
        tb.*, 
        'Barang' as layanan,
        uc.name as customerName, 
        uc.email as customerEmail, 
        uc.phone as customerPhone
       FROM tebengan_barang tb
       LEFT JOIN users uc ON tb.user_id = uc.id
       WHERE tb.id = ?`,
      [id]
    );

    const [titipBarangRows] = await connection.query<any[]>(
      `SELECT 
        ttb.*, 
        'Titip Barang' as layanan,
        uc.name as customerName, 
        uc.email as customerEmail, 
        uc.phone as customerPhone
       FROM tebengan_titip_barang ttb
       LEFT JOIN users uc ON ttb.user_id = uc.id
       WHERE ttb.id = ?`,
      [id]
    );

    connection.release();

    // Ambil data dari tabel yang ada datanya
    let pesananData = null;
    if (motorRows.length > 0) pesananData = motorRows[0];
    else if (mobilRows.length > 0) pesananData = mobilRows[0];
    else if (barangRows.length > 0) pesananData = barangRows[0];
    else if (titipBarangRows.length > 0) pesananData = titipBarangRows[0];

    if (pesananData) {
      res.json(pesananData);
    } else {
      res.status(404).json({ error: 'Pesanan not found' });
    }
  } catch (error) {
    console.error('❌ GET /api/pesanan/:id error:', error);
    res.status(500).json({ 
      error: 'Failed to fetch pesanan', 
      message: error instanceof Error ? error.message : '' 
    });
  }
});

// Update pesanan status
router.patch('/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const connection = await pool.getConnection();
    
    // Update di semua tabel
    await connection.execute('UPDATE tebengan_motor SET status = ? WHERE id = ?', [status, id]);
    await connection.execute('UPDATE tebengan_mobil SET status = ? WHERE id = ?', [status, id]);
    await connection.execute('UPDATE tebengan_barang SET status = ? WHERE id = ?', [status, id]);
    await connection.execute('UPDATE tebengan_titip_barang SET status = ? WHERE id = ?', [status, id]);
    
    connection.release();

    res.json({ message: 'Pesanan status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/pesanan/:id/status error:', error);
    res.status(500).json({ 
      error: 'Failed to update pesanan status', 
      message: error instanceof Error ? error.message : '' 
    });
  }
});

// Create pesanan
router.post('/', async (req: Request, res: Response) => {
  const { userId, kendaraanMitraId, layanan, originLocationId, destinationLocationId, 
          departureDate, departureTime, rideType, serviceType, price, availableSeats, 
          bagasiCapacity } = req.body;

  try {
    const connection = await pool.getConnection();
    let result;

    // Tentukan tabel berdasarkan layanan
    switch (layanan) {
      case 'Motor':
        [result] = await connection.execute(
          `INSERT INTO tebengan_motor (user_id, kendaraan_mitra_id, origin_location_id, 
            destination_location_id, departure_date, departure_time, ride_type, service_type, 
            price, available_seats, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
          [userId, kendaraanMitraId, originLocationId, destinationLocationId, departureDate, 
           departureTime, rideType, serviceType, price, availableSeats]
        );
        break;
      case 'Mobil':
        [result] = await connection.execute(
          `INSERT INTO tebengan_mobil (user_id, kendaraan_mitra_id, origin_location_id, 
            destination_location_id, departure_date, departure_time, ride_type, service_type, 
            price, available_seats, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
          [userId, kendaraanMitraId, originLocationId, destinationLocationId, departureDate, 
           departureTime, rideType, serviceType, price, availableSeats]
        );
        break;
      case 'Barang':
        [result] = await connection.execute(
          `INSERT INTO tebengan_barang (user_id, kendaraan_mitra_id, origin_location_id, 
            destination_location_id, departure_date, departure_time, ride_type, service_type, 
            price, bagasi_capacity, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
          [userId, kendaraanMitraId, originLocationId, destinationLocationId, departureDate, 
           departureTime, rideType, serviceType, price, bagasiCapacity]
        );
        break;
      case 'Titip Barang':
        [result] = await connection.execute(
          `INSERT INTO tebengan_titip_barang (user_id, kendaraan_mitra_id, origin_location_id, 
            destination_location_id, departure_date, departure_time, transportation_type, 
            bagasi_capacity, price, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')`,
          [userId, kendaraanMitraId, originLocationId, destinationLocationId, departureDate, 
           departureTime, rideType, bagasiCapacity, price]
        );
        break;
      default:
        connection.release();
        return res.status(400).json({ error: 'Invalid layanan type' });
    }

    connection.release();

    res.status(201).json({ 
      id: (result as any).insertId, 
      message: 'Pesanan created successfully' 
    });
  } catch (error) {
    console.error('❌ POST /api/pesanan error:', error);
    res.status(500).json({ 
      error: 'Failed to create pesanan', 
      message: error instanceof Error ? error.message : '' 
    });
  }
});

// Delete pesanan
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();
    
    // Update status menjadi completed/cancelled di semua tabel
    await connection.execute('UPDATE tebengan_motor SET status = ? WHERE id = ?', ['completed', id]);
    await connection.execute('UPDATE tebengan_mobil SET status = ? WHERE id = ?', ['completed', id]);
    await connection.execute('UPDATE tebengan_barang SET status = ? WHERE id = ?', ['completed', id]);
    await connection.execute('UPDATE tebengan_titip_barang SET status = ? WHERE id = ?', ['completed', id]);
    
    connection.release();

    res.json({ message: 'Pesanan deleted successfully' });
  } catch (error) {
    console.error('❌ DELETE /api/pesanan/:id error:', error);
    res.status(500).json({ 
      error: 'Failed to delete pesanan', 
      message: error instanceof Error ? error.message : '' 
    });
  }
});

export default router;