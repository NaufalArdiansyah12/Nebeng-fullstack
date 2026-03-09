import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../../db.ts';

const router = express.Router();

// Get all pesanan (gabungan dari 4 tabel booking)
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();
    const [rows] = await connection.query(`
      SELECT
        id,
        booking_number as no_order,
        customerName as namaCustomer,
        driverName as namaDriver,
        created_at as tanggal,
        layanan,
        COALESCE(tebenganPrice, 0) as harga,
        status
      FROM (
        -- Booking Motor
        SELECT
          bm.id,
          bm.booking_number,
          uc.name as customerName,
          ud.name as driverName,
          bm.created_at,
          'Motor' as layanan,
          bm.status,
          tm.price as tebenganPrice
        FROM booking_motor bm
        LEFT JOIN users uc ON bm.user_id = uc.id
        LEFT JOIN tebengan_motor tm ON bm.ride_id = tm.id
        LEFT JOIN users ud ON tm.user_id = ud.id

        UNION ALL

        -- Booking Mobil
        SELECT
          bmb.id,
          bmb.booking_number,
          uc.name as customerName,
          ud.name as driverName,
          bmb.created_at,
          'Mobil' as layanan,
          bmb.status,
          tmb.price as tebenganPrice
        FROM booking_mobil bmb
        LEFT JOIN users uc ON bmb.user_id = uc.id
        LEFT JOIN tebengan_mobil tmb ON bmb.ride_id = tmb.id
        LEFT JOIN users ud ON tmb.user_id = ud.id

        UNION ALL

        -- Booking Barang
        SELECT
          bb.id,
          bb.booking_number,
          uc.name as customerName,
          ud.name as driverName,
          bb.created_at,
          'Barang' as layanan,
          bb.status,
          tb.price as tebenganPrice
        FROM booking_barang bb
        LEFT JOIN users uc ON bb.user_id = uc.id
        LEFT JOIN tebengan_barang tb ON bb.ride_id = tb.id
        LEFT JOIN users ud ON tb.user_id = ud.id

        UNION ALL

        -- Booking Titip Barang
        SELECT
          btb.id,
          btb.booking_number,
          uc.name as customerName,
          ud.name as driverName,
          btb.created_at,
          'Titip Barang' as layanan,
          btb.status,
          ttb.price as tebenganPrice
        FROM booking_titip_barang btb
        LEFT JOIN users uc ON btb.user_id = uc.id
        LEFT JOIN tebengan_titip_barang ttb ON btb.ride_id = ttb.id
        LEFT JOIN users ud ON ttb.user_id = ud.id
      ) AS all_booking
      ORDER BY created_at DESC
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

// Get pesanan by ID with details (UPDATED - ambil price dari tebengan dan lokasi)
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();

    // Cek di tabel mana pesanan ini ada dan ambil price dari tebengan + lokasi details
    const [motorRows] = await connection.query<any[]>(
      `SELECT
        bm.*,
        'Motor' as layanan,
        uc.name as customerName,
        uc.email as customerEmail,
        uc.phone as customerPhone,
        ud.id as driverId,
        ud.name as driverName,
        ud.email as driverEmail,
        ud.phone as driverPhone,
        ud.address as driverAddress,
        km.id as kendaraanId,
        km.name as vehicleName,
        km.plate_number as platNomor,
        km.brand as merek,
        km.model as model,
        km.vehicle_type as vehicleType,
        tm.price as tebenganPrice,
        origin_loc.id as originLocationId,
        origin_loc.city as originCity,
        origin_loc.address as originAddress,
        dest_loc.id as destinationLocationId,
        dest_loc.city as destinationCity,
        dest_loc.address as destinationAddress
       FROM booking_motor bm
       LEFT JOIN users uc ON bm.user_id = uc.id
       LEFT JOIN tebengan_motor tm ON bm.ride_id = tm.id
       LEFT JOIN kendaraan_mitra km ON tm.kendaraan_mitra_id = km.id
       LEFT JOIN users ud ON tm.user_id = ud.id
       LEFT JOIN locations origin_loc ON tm.origin_location_id = origin_loc.id
       LEFT JOIN locations dest_loc ON tm.destination_location_id = dest_loc.id
       WHERE bm.id = ?`,
      [id]
    );

    const [mobilRows] = await connection.query<any[]>(
      `SELECT
        bmb.*,
        'Mobil' as layanan,
        uc.name as customerName,
        uc.email as customerEmail,
        uc.phone as customerPhone,
        ud.id as driverId,
        ud.name as driverName,
        ud.email as driverEmail,
        ud.phone as driverPhone,
        ud.address as driverAddress,
        km.id as kendaraanId,
        km.name as vehicleName,
        km.plate_number as platNomor,
        km.brand as merek,
        km.model as model,
        km.vehicle_type as vehicleType,
        tmb.price as tebenganPrice,
        origin_loc.id as originLocationId,
        origin_loc.city as originCity,
        origin_loc.address as originAddress,
        dest_loc.id as destinationLocationId,
        dest_loc.city as destinationCity,
        dest_loc.address as destinationAddress
       FROM booking_mobil bmb
       LEFT JOIN users uc ON bmb.user_id = uc.id
       LEFT JOIN tebengan_mobil tmb ON bmb.ride_id = tmb.id
       LEFT JOIN kendaraan_mitra km ON tmb.kendaraan_mitra_id = km.id
       LEFT JOIN users ud ON tmb.user_id = ud.id
       LEFT JOIN locations origin_loc ON tmb.origin_location_id = origin_loc.id
       LEFT JOIN locations dest_loc ON tmb.destination_location_id = dest_loc.id
       WHERE bmb.id = ?`,
      [id]
    );

    const [barangRows] = await connection.query<any[]>(
      `SELECT
        bb.*,
        'Barang' as layanan,
        uc.name as customerName,
        uc.email as customerEmail,
        uc.phone as customerPhone,
        ud.id as driverId,
        ud.name as driverName,
        ud.email as driverEmail,
        ud.phone as driverPhone,
        ud.address as driverAddress,
        km.id as kendaraanId,
        km.name as vehicleName,
        km.plate_number as platNomor,
        km.brand as merek,
        km.model as model,
        km.vehicle_type as vehicleType,
        tb.price as tebenganPrice,
        origin_loc.id as originLocationId,
        origin_loc.city as originCity,
        origin_loc.address as originAddress,
        dest_loc.id as destinationLocationId,
        dest_loc.city as destinationCity,
        dest_loc.address as destinationAddress
       FROM booking_barang bb
       LEFT JOIN users uc ON bb.user_id = uc.id
       LEFT JOIN tebengan_barang tb ON bb.ride_id = tb.id
       LEFT JOIN kendaraan_mitra km ON tb.kendaraan_mitra_id = km.id
       LEFT JOIN users ud ON tb.user_id = ud.id
       LEFT JOIN locations origin_loc ON tb.origin_location_id = origin_loc.id
       LEFT JOIN locations dest_loc ON tb.destination_location_id = dest_loc.id
       WHERE bb.id = ?`,
      [id]
    );

    const [titipBarangRows] = await connection.query<any[]>(
      `SELECT
        btb.*,
        'Titip Barang' as layanan,
        uc.name as customerName,
        uc.email as customerEmail,
        uc.phone as customerPhone,
        ud.id as driverId,
        ud.name as driverName,
        ud.email as driverEmail,
        ud.phone as driverPhone,
        ud.address as driverAddress,
        NULL as kendaraanId,
        NULL as vehicleName,
        NULL as platNomor,
        NULL as merek,
        NULL as model,
        NULL as vehicleType,
        ttb.price as tebenganPrice,
        origin_loc.id as originLocationId,
        origin_loc.city as originCity,
        origin_loc.address as originAddress,
        dest_loc.id as destinationLocationId,
        dest_loc.city as destinationCity,
        dest_loc.address as destinationAddress,
        ttb.transportation_type as transportationType
       FROM booking_titip_barang btb
       LEFT JOIN users uc ON btb.user_id = uc.id
       LEFT JOIN tebengan_titip_barang ttb ON btb.ride_id = ttb.id
       LEFT JOIN users ud ON ttb.user_id = ud.id
       LEFT JOIN locations origin_loc ON ttb.origin_location_id = origin_loc.id
       LEFT JOIN locations dest_loc ON ttb.destination_location_id = dest_loc.id
       WHERE btb.id = ?`,
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

    // Update di semua tabel booking
    await connection.execute('UPDATE booking_motor SET status = ? WHERE id = ?', [status, id]);
    await connection.execute('UPDATE booking_mobil SET status = ? WHERE id = ?', [status, id]);
    await connection.execute('UPDATE booking_barang SET status = ? WHERE id = ?', [status, id]);
    await connection.execute('UPDATE booking_titip_barang SET status = ? WHERE id = ?', [status, id]);

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
          `INSERT INTO booking_motor (user_id, ride_id, booking_number, seats, status, meta, created_at, updated_at)
           VALUES (?, ?, CONCAT('BM-', UNIX_TIMESTAMP()), ?, 'pending', '{}', NOW(), NOW())`,
          [userId, kendaraanMitraId, availableSeats || 1]
        );
        break;
      case 'Mobil':
        [result] = await connection.execute(
          `INSERT INTO booking_mobil (user_id, ride_id, booking_number, seats, status, meta, created_at, updated_at)
           VALUES (?, ?, CONCAT('BMB-', UNIX_TIMESTAMP()), ?, 'pending', '{}', NOW(), NOW())`,
          [userId, kendaraanMitraId, availableSeats || 1]
        );
        break;
      case 'Barang':
        [result] = await connection.execute(
          `INSERT INTO booking_barang (user_id, ride_id, booking_number, seats, status, meta, photo, weight, description, created_at, updated_at)
           VALUES (?, ?, CONCAT('BB-', UNIX_TIMESTAMP()), ?, 'pending', '{}', '', ?, '', NOW(), NOW())`,
          [userId, kendaraanMitraId, availableSeats || 1, bagasiCapacity || '']
        );
        break;
      case 'Titip Barang':
        [result] = await connection.execute(
          `INSERT INTO booking_titip_barang (user_id, ride_id, booking_number, seats, status, meta, photo, weight, description, penerima, created_at, updated_at)
           VALUES (?, ?, CONCAT('BTB-', UNIX_TIMESTAMP()), ?, 'pending', '{}', '', ?, '', '', NOW(), NOW())`,
          [userId, kendaraanMitraId, availableSeats || 1, bagasiCapacity || '']
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

    // Update status menjadi completed/cancelled di semua tabel booking
    await connection.execute('UPDATE booking_motor SET status = ? WHERE id = ?', ['cancelled', id]);
    await connection.execute('UPDATE booking_mobil SET status = ? WHERE id = ?', ['cancelled', id]);
    await connection.execute('UPDATE booking_barang SET status = ? WHERE id = ?', ['cancelled', id]);
    await connection.execute('UPDATE booking_titip_barang SET status = ? WHERE id = ?', ['cancelled', id]);

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