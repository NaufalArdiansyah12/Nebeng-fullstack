import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all posmitra with user data joined
router.get('/', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const [rows] = await connection.query(
      `SELECT
        v.*,
        p.name as user_name,
        p.email as user_email,
        p.phone as user_phone,
        l.name as terminal_name,
        l.city as terminal_city,
        l.address as terminal_address,
        l.latitude as terminal_latitude,
        l.longitude as terminal_longitude
      FROM verifikasi_ktp_posmitra v
      LEFT JOIN posmitra_users p ON v.posmitra_id = p.id
      LEFT JOIN locations l ON p.location_id = l.id
      ORDER BY v.created_at DESC`,
      []
    );

    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/posmitra error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch posmitra',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get posmitra by ID with user data joined
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    const [rows] = await connection.query(
      `SELECT
        v.*,
        p.id as user_id,
        p.name as user_name,
        p.email as user_email,
        p.phone as user_phone,
        l.name as terminal_name,
        l.city as terminal_city,
        l.address as terminal_address,
        l.latitude as terminal_latitude,
        l.longitude as terminal_longitude
      FROM verifikasi_ktp_posmitra v
      LEFT JOIN posmitra_users p ON v.posmitra_id = p.id
      LEFT JOIN locations l ON p.location_id = l.id
      WHERE v.posmitra_id = ? OR p.id = ?`,
      [id, id]
    );

    connection.release();

    if (!Array.isArray(rows) || rows.length === 0) {
      return res.status(404).json({ error: 'Posmitra not found' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('❌ GET /api/posmitra/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch posmitra',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Create new posmitra
router.post('/', async (req: Request, res: Response) => {
  const {
    posmitra_id,
    nama_lengkap,
    nik,
    tanggal_lahir,
    jenis_kelamin,
    alamat,
    photo_ktp,
    status,
    reviewer_id,
    reviewed_at,
    meta
  } = req.body;

  let connection;
  try {
    connection = await pool.getConnection();

    const [result] = await connection.query(
      `INSERT INTO verifikasi_ktp_posmitra (
        posmitra_id,
        nama_lengkap,
        nik,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        photo_ktp,
        status,
        reviewer_id,
        reviewed_at,
        meta
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        posmitra_id,
        nama_lengkap,
        nik,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        photo_ktp,
        status || 'pending',
        reviewer_id,
        reviewed_at,
        meta
      ]
    );

    connection.release();

    const insertResult = result as any;
    res.status(201).json({
      success: true,
      id: insertResult.insertId,
      message: 'Posmitra created successfully'
    });
  } catch (error) {
    console.error('❌ POST /api/posmitra error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to create posmitra',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Update posmitra
router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const {
    posmitra_id,
    nama_lengkap,
    nik,
    tanggal_lahir,
    jenis_kelamin,
    alamat,
    photo_ktp,
    status,
    reviewer_id,
    reviewed_at,
    meta
  } = req.body;

  let connection;
  try {
    connection = await pool.getConnection();

    // First, get the existing record to preserve values if not provided
    const [existingRows] = await connection.query(
      'SELECT posmitra_id, nama_lengkap, nik, tanggal_lahir, jenis_kelamin, alamat, photo_ktp, status, reviewer_id, reviewed_at, meta FROM verifikasi_ktp_posmitra WHERE id = ?',
      [id]
    );

    const existingRecords = existingRows as any[];
    if (!existingRecords || existingRecords.length === 0) {
      connection.release();
      return res.status(404).json({ error: 'Posmitra not found' });
    }

    const existing = existingRecords[0];

    // Only update fields that are provided and not null/undefined
    // For required fields with FK constraint, always keep the existing value if not provided
    const finalPosmitraId = posmitra_id !== undefined && posmitra_id !== null ? posmitra_id : existing.posmitra_id;
    const finalNamaLengkap = nama_lengkap !== undefined && nama_lengkap !== null ? nama_lengkap : existing.nama_lengkap;
    const finalNik = nik !== undefined && nik !== null ? nik : existing.nik;
    const finalTanggalLahir = tanggal_lahir !== undefined && tanggal_lahir !== null ? tanggal_lahir : existing.tanggal_lahir;
    const finalJenisKelamin = jenis_kelamin !== undefined && jenis_kelamin !== null ? jenis_kelamin : existing.jenis_kelamin;
    const finalAlamat = alamat !== undefined && alamat !== null ? alamat : existing.alamat;
    const finalPhotoKtp = photo_ktp !== undefined && photo_ktp !== null ? photo_ktp : existing.photo_ktp;
    const finalStatus = status !== undefined && status !== null ? status : existing.status;
    const finalReviewerId = reviewer_id !== undefined ? reviewer_id : existing.reviewer_id;
    const finalReviewedAt = reviewed_at !== undefined ? reviewed_at : existing.reviewed_at;
    const finalMeta = meta !== undefined ? meta : existing.meta;

    const [result] = await connection.query(
      `UPDATE verifikasi_ktp_posmitra SET
        posmitra_id = ?,
        nama_lengkap = ?,
        nik = ?,
        tanggal_lahir = ?,
        jenis_kelamin = ?,
        alamat = ?,
        photo_ktp = ?,
        status = ?,
        reviewer_id = ?,
        reviewed_at = ?,
        meta = ?,
        updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [
        finalPosmitraId,
        finalNamaLengkap,
        finalNik,
        finalTanggalLahir,
        finalJenisKelamin,
        finalAlamat,
        finalPhotoKtp,
        finalStatus,
        finalReviewerId,
        finalReviewedAt,
        finalMeta,
        id
      ]
    );

    connection.release();

    const updateResult = result as any;
    if (updateResult.affectedRows === 0) {
      return res.status(404).json({ error: 'Posmitra not found' });
    }

    res.json({
      success: true,
      message: 'Posmitra updated successfully'
    });
  } catch (error) {
    console.error('❌ PUT /api/posmitra/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to update posmitra',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Approve/Reject posmitra verification
router.patch('/:id/approve', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status, reviewer_id, reviewed_at } = req.body;

  let connection;
  try {
    connection = await pool.getConnection();

    const [result] = await connection.query(
      `UPDATE verifikasi_ktp_posmitra SET
        status = ?,
        reviewer_id = ?,
        reviewed_at = ?,
        updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [status, reviewer_id, reviewed_at, id]
    );

    connection.release();

    const updateResult = result as any;
    if (updateResult.affectedRows === 0) {
      return res.status(404).json({ error: 'Posmitra not found' });
    }

    res.json({
      success: true,
      message: `Posmitra ${status === 'approved' ? 'approved' : 'rejected'} successfully`
    });
  } catch (error) {
    console.error('❌ PATCH /api/posmitra/:id/approve error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to approve posmitra',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Delete posmitra
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    const [result] = await connection.query(
      'DELETE FROM verifikasi_ktp_posmitra WHERE id = ?',
      [id]
    );

    connection.release();

    const deleteResult = result as any;
    if (deleteResult.affectedRows === 0) {
      return res.status(404).json({ error: 'Posmitra not found' });
    }

    res.json({
      success: true,
      message: 'Posmitra deleted successfully'
    });
  } catch (error) {
    console.error('❌ DELETE /api/posmitra/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to delete posmitra',
      message: error instanceof Error ? error.message : ''
    });
  }
});

export default router;