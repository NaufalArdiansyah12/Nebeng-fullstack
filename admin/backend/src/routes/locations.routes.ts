import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all locations
router.get('/', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const [rows] = await connection.query(
      'SELECT * FROM locations ORDER BY created_at DESC'
    );

    connection.release();

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

    const [rows] = await connection.query(
      'SELECT * FROM locations WHERE id = ?',
      [id]
    );

    connection.release();

    if (!Array.isArray(rows) || rows.length === 0) {
      return res.status(404).json({ error: 'Location not found' });
    }

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

  let connection;
  try {
    connection = await pool.getConnection();

    const [result] = await connection.query(
      `INSERT INTO locations (name, city, address, latitude, longitude, created_by_role)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [name, city, address, latitude, longitude, created_by_role]
    );

    connection.release();

    const insertResult = result as any;
    res.status(201).json({
      success: true,
      id: insertResult.insertId,
      message: 'Location created successfully'
    });
  } catch (error) {
    console.error('❌ POST /api/locations error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to create location',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Delete location by ID
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    const [result] = await connection.query(
      'DELETE FROM locations WHERE id = ?',
      [id]
    );

    connection.release();

    const deleteResult = result as any;
    if (deleteResult.affectedRows === 0) {
      return res.status(404).json({ error: 'Location not found' });
    }

    res.json({
      success: true,
      message: 'Location deleted successfully'
    });
  } catch (error) {
    console.error('❌ DELETE /api/locations/:id error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to delete location',
      message: error instanceof Error ? error.message : ''
    });
  }
});

export default router;
