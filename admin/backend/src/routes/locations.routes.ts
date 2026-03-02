import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all locations
router.get('/', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    console.log('🟢 GET /api/locations - Fetching all terminals');

    const [rows] = await connection.query(
      'SELECT * FROM locations ORDER BY created_at DESC'
    );

    connection.release();

    console.log(`✅ Found ${Array.isArray(rows) ? rows.length : 0} terminals`);

    res.json(rows);
  } catch (error) {
    console.error('❌ GET /api/locations error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch locations',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get location by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    console.log('🟢 GET /api/locations/:id - Fetching terminal ID:', id);

    const [rows] = await connection.query(
      'SELECT * FROM locations WHERE id = ?',
      [id]
    );

    connection.release();

    if (!Array.isArray(rows) || rows.length === 0) {
      console.log('⚠️ Terminal not found with ID:', id);
      return res.status(404).json({ error: 'Location not found' });
    }

    console.log('✅ Terminal found:', (rows[0] as any).name);

    res.json(rows[0]);
  } catch (error) {
    console.error('❌ GET /api/locations/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch location',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Create new location
router.post('/', async (req: Request, res: Response) => {
  const { name, city, address, latitude, longitude, created_by_role } = req.body;

  // Validation
  if (!name || !city || !address) {
    return res.status(400).json({
      error: 'Validation failed',
      message: 'Name, city, and address are required'
    });
  }

  // Validate coordinates if provided
  if (latitude !== undefined && latitude !== null && latitude !== '') {
    const latNum = parseFloat(latitude);
    if (isNaN(latNum) || latNum < -90 || latNum > 90) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Latitude must be a number between -90 and 90'
      });
    }
  }

  if (longitude !== undefined && longitude !== null && longitude !== '') {
    const lngNum = parseFloat(longitude);
    if (isNaN(lngNum) || lngNum < -180 || lngNum > 180) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Longitude must be a number between -180 and 180'
      });
    }
  }

  let connection;
  try {
    connection = await pool.getConnection();

    console.log('🟢 POST /api/locations - Creating new terminal:', { name, city, address, latitude, longitude });

    const [result] = await connection.query(
      `INSERT INTO locations (name, city, address, latitude, longitude, created_by_role, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())`,
      [
        name,
        city,
        address,
        latitude !== undefined && latitude !== null && latitude !== '' ? parseFloat(latitude) : null,
        longitude !== undefined && longitude !== null && longitude !== '' ? parseFloat(longitude) : null,
        created_by_role || 'admin'
      ]
    );

    connection.release();

    const insertResult = result as any;
    console.log('✅ Terminal created successfully with ID:', insertResult.insertId);

    res.status(201).json({
      success: true,
      id: insertResult.insertId,
      message: 'Terminal berhasil dibuat'
    });
  } catch (error) {
    console.error('❌ POST /api/locations error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to create location',
      message: error instanceof Error ? error.message : 'Internal server error'
    });
  }
});

// Update location by ID
router.put('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { name, city, address, latitude, longitude } = req.body;

  // Validation
  if (!name || !city || !address) {
    return res.status(400).json({
      error: 'Validation failed',
      message: 'Name, city, and address are required'
    });
  }

  // Validate coordinates if provided
  if (latitude !== undefined && latitude !== null && latitude !== '') {
    const latNum = parseFloat(latitude);
    if (isNaN(latNum) || latNum < -90 || latNum > 90) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Latitude must be a number between -90 and 90'
      });
    }
  }

  if (longitude !== undefined && longitude !== null && longitude !== '') {
    const lngNum = parseFloat(longitude);
    if (isNaN(lngNum) || lngNum < -180 || lngNum > 180) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Longitude must be a number between -180 and 180'
      });
    }
  }

  let connection;
  try {
    connection = await pool.getConnection();

    console.log('🟢 PUT /api/locations/:id - Updating terminal ID:', id);

    const [result] = await connection.query(
      `UPDATE locations 
       SET name = ?, city = ?, address = ?, latitude = ?, longitude = ?, updated_at = NOW()
       WHERE id = ?`,
      [
        name,
        city,
        address,
        latitude !== undefined && latitude !== null && latitude !== '' ? parseFloat(latitude) : null,
        longitude !== undefined && longitude !== null && longitude !== '' ? parseFloat(longitude) : null,
        id
      ]
    );

    connection.release();

    const updateResult = result as any;
    if (updateResult.affectedRows === 0) {
      console.log('⚠️ Terminal not found with ID:', id);
      return res.status(404).json({ error: 'Location not found' });
    }

    console.log('✅ Terminal updated successfully');

    res.json({
      success: true,
      message: 'Terminal berhasil diupdate'
    });
  } catch (error) {
    console.error('❌ PUT /api/locations/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to update location',
      message: error instanceof Error ? error.message : 'Internal server error'
    });
  }
});

// Delete location by ID
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    console.log('🟢 DELETE /api/locations/:id - Deleting terminal ID:', id);

    // Check if there are any pos mitra users associated with this location
    const [posmitraCheck] = await connection.query(
      'SELECT COUNT(*) as count FROM posmitra_users WHERE location_id = ?',
      [id]
    );

    const checkResult = posmitraCheck as any[];
    if (checkResult[0].count > 0) {
      connection.release();
      return res.status(400).json({
        error: 'Cannot delete location',
        message: `Terminal ini memiliki ${checkResult[0].count} pos mitra. Hapus pos mitra terlebih dahulu.`
      });
    }

    const [result] = await connection.query(
      'DELETE FROM locations WHERE id = ?',
      [id]
    );

    connection.release();

    const deleteResult = result as any;
    if (deleteResult.affectedRows === 0) {
      console.log('⚠️ Terminal not found with ID:', id);
      return res.status(404).json({ error: 'Location not found' });
    }

    console.log('✅ Terminal deleted successfully');

    res.json({
      success: true,
      message: 'Terminal berhasil dihapus'
    });
  } catch (error) {
    console.error('❌ DELETE /api/locations/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to delete location',
      message: error instanceof Error ? error.message : 'Internal server error'
    });
  }
});

export default router;
