import express from 'express';
import type { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import { pool } from '../../db.ts';

const router = express.Router();

// Get all posmitra users (from posmitra_users table, not verifikasi)
router.get('/', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const [rows] = await connection.query(
      `SELECT 
        p.*,
        v.id as verifikasi_id,
        v.nama_lengkap as verifikasi_nama,
        v.nik,
        v.tanggal_lahir,
        v.jenis_kelamin,
        v.alamat,
        v.photo_ktp,
        v.status as verifikasi_status,
        v.created_at as verifikasi_created_at
      FROM posmitra_users p
      LEFT JOIN verifikasi_ktp_posmitra v ON p.id = v.posmitra_id
      ORDER BY p.created_at DESC`,
      []
    );

    connection.release();

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/posmitra-users error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch posmitra users',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get posmitra user by ID with all verifikasi records
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    const [userRows] = await connection.query(
      `SELECT p.* FROM posmitra_users p WHERE p.id = ?`,
      [id]
    );

    if (!Array.isArray(userRows) || userRows.length === 0) {
      connection.release();
      return res.status(404).json({ error: 'Posmitra user not found' });
    }

    const user = (userRows as any[])[0];

    const [verifikasiRows] = await connection.query(
      `SELECT v.* FROM verifikasi_ktp_posmitra v WHERE v.posmitra_id = ? ORDER BY v.created_at DESC`,
      [id]
    );

    connection.release();

    res.json({
      user,
      verifikasi: verifikasiRows || []
    });
  } catch (error) {
    console.error('❌ GET /api/posmitra-users/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch posmitra user',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Create new posmitra user ✅ DENGAN DEBUG
router.post('/', async (req: Request, res: Response) => {
  console.log('🟢 POST /posmitra-users received');
  console.log('📦 Request body:', JSON.stringify(req.body, null, 2));

  const { name, email, phone, location_id, password } = req.body;

  // Validasi required fields
  if (!name || !email || !phone || !location_id) {
    console.error('❌ Validation failed - missing required fields');
    console.error('  name:', name);
    console.error('  email:', email);
    console.error('  phone:', phone);
    console.error('  location_id:', location_id);
    return res.status(400).json({
      error: 'Validation error',
      message: 'name, email, phone, dan location_id harus diisi'
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    console.log('✅ Database connection acquired');

    // Check if location_id exists
    const [locationCheck] = await connection.query(
      'SELECT id FROM locations WHERE id = ?',
      [location_id]
    );

    if (!Array.isArray(locationCheck) || locationCheck.length === 0) {
      console.error(`❌ Location ID ${location_id} tidak ditemukan di database`);
      connection.release();
      return res.status(400).json({
        error: 'Invalid location_id',
        message: `Location dengan ID ${location_id} tidak ditemukan`
      });
    }

    console.log('✅ Location ID valid');

    // Insert data
    console.log('📝 Inserting data:', { name, email, phone, location_id, hasPassword: !!password });

    // Determine raw password: use provided one if present, otherwise generate a temporary one
    let tempPassword: string | null = null;
    const rawPassword = password && String(password).length > 0
      ? String(password)
      : (tempPassword = Math.random().toString(36).slice(-8));

    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    const [result] = await connection.query(
      `INSERT INTO posmitra_users (name, email, phone, location_id, password)
       VALUES (?, ?, ?, ?, ?)`,
      [name, email, phone, location_id, hashedPassword]
    );

    connection.release();

    const insertResult = result as any;
    console.log('✅ INSERT successful');
    console.log('   insertId:', insertResult.insertId);
    console.log('   affectedRows:', insertResult.affectedRows);

    const responseBody: any = {
      success: true,
      id: insertResult.insertId,
      message: 'Posmitra user created successfully'
    };

    if (tempPassword) {
      // Return the temporary password so admin can communicate it to the user
      responseBody.tempPassword = tempPassword;
    }

    res.status(201).json(responseBody);
  } catch (error) {
    console.error('❌ POST /api/posmitra-users error:', error);
    if (connection) connection.release();

    const errorMsg = error instanceof Error ? error.message : String(error);
    console.error('   Error details:', errorMsg);

    res.status(500).json({
      error: 'Failed to create posmitra user',
      message: errorMsg
    });
  }
});

// Update posmitra user
router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { name, email, phone, location_id } = req.body;

  console.log('🟢 PUT /posmitra-users/:id received');
  console.log('   ID:', id);
  console.log('   Body:', { name, email, phone, location_id });

  let connection;
  try {
    connection = await pool.getConnection();

    // Check if user exists
    const [existingRows] = await connection.query(
      'SELECT id FROM posmitra_users WHERE id = ?',
      [id]
    );

    if (!Array.isArray(existingRows) || existingRows.length === 0) {
      connection.release();
      console.error(`❌ User ID ${id} tidak ditemukan`);
      return res.status(404).json({ error: 'Posmitra user not found' });
    }

    const [result] = await connection.query(
      `UPDATE posmitra_users 
       SET name = COALESCE(?, name),
           email = COALESCE(?, email),
           phone = COALESCE(?, phone),
           location_id = COALESCE(?, location_id),
           updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [name, email, phone, location_id, id]
    );

    connection.release();

    console.log('✅ UPDATE successful');

    res.json({
      success: true,
      message: 'Posmitra user updated successfully'
    });
  } catch (error) {
    console.error('❌ PUT /api/posmitra-users/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to update posmitra user',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Delete posmitra user
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  console.log('🟢 DELETE /posmitra-users/:id received');
  console.log('   ID:', id);

  let connection;
  try {
    connection = await pool.getConnection();

    // Delete verifikasi records first (foreign key constraint)
    const [verifikasiDelete] = await connection.query(
      'DELETE FROM verifikasi_ktp_posmitra WHERE posmitra_id = ?',
      [id]
    );

    console.log('   Deleted verifikasi records:', (verifikasiDelete as any).affectedRows);

    // Delete user
    const [result] = await connection.query(
      'DELETE FROM posmitra_users WHERE id = ?',
      [id]
    );

    connection.release();

    const deleteResult = result as any;
    console.log('   Deleted user rows:', deleteResult.affectedRows);

    if (deleteResult.affectedRows === 0) {
      console.error(`❌ User ID ${id} tidak ditemukan`);
      return res.status(404).json({ error: 'Posmitra user not found' });
    }

    console.log('✅ DELETE successful');

    res.json({
      success: true,
      message: 'Posmitra user deleted successfully'
    });
  } catch (error) {
    console.error('❌ DELETE /api/posmitra-users/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to delete posmitra user',
      message: error instanceof Error ? error.message : ''
    });
  }
});

export default router;