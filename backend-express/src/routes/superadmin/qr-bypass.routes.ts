import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../../db.ts';

const router = express.Router();

// Get all locations with their QR bypass settings
router.get('/', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    console.log('🟢 GET /api/location-qr-bypass - Fetching locations with bypass settings');

    const [rows] = await connection.query(`
      SELECT 
        l.id,
        l.name,
        l.city,
        l.address,
        COALESCE(qb.qr_bypass_enabled, 0) as qr_bypass_enabled,
        qb.notes
      FROM locations l
      LEFT JOIN location_qr_bypass_settings qb ON l.id = qb.location_id
      ORDER BY l.city, l.name
    `);

    connection.release();

    console.log(`✅ Found ${Array.isArray(rows) ? rows.length : 0} locations`);

    res.json({
      success: true,
      data: rows,
    });
  } catch (error) {
    console.error('❌ GET /api/location-qr-bypass error:', error);
    if (connection) connection.release();
    res.status(500).json({
      success: false,
      error: 'Failed to fetch locations',
      message: error instanceof Error ? error.message : '',
    });
  }
});

// Update QR bypass setting for a location
router.put('/:locationId', async (req: Request, res: Response) => {
  const { locationId } = req.params;
  const { qr_bypass_enabled, notes } = req.body;

  // Validation
  if (typeof qr_bypass_enabled !== 'boolean') {
    return res.status(422).json({
      success: false,
      message: 'qr_bypass_enabled must be a boolean',
    });
  }

  let connection;
  try {
    connection = await pool.getConnection();

    console.log(`🟢 PUT /api/location-qr-bypass/${locationId} - Updating bypass setting`);

    // Check if location exists
    const [locationRows] = await connection.query(
      'SELECT id FROM locations WHERE id = ?',
      [locationId]
    );

    if (!Array.isArray(locationRows) || locationRows.length === 0) {
      connection.release();
      return res.status(404).json({
        success: false,
        message: 'Location not found',
      });
    }

    // Insert or update bypass setting
    await connection.query(
      `INSERT INTO location_qr_bypass_settings (location_id, qr_bypass_enabled, notes, created_at, updated_at)
       VALUES (?, ?, ?, NOW(), NOW())
       ON DUPLICATE KEY UPDATE 
         qr_bypass_enabled = VALUES(qr_bypass_enabled),
         notes = VALUES(notes),
         updated_at = NOW()`,
      [locationId, qr_bypass_enabled ? 1 : 0, notes || null]
    );

    connection.release();

    console.log(`✅ Updated bypass setting for location ${locationId}`);

    res.json({
      success: true,
      message: 'QR bypass setting updated successfully',
      data: {
        location_id: parseInt(locationId),
        qr_bypass_enabled: qr_bypass_enabled,
        notes: notes || null,
      },
    });
  } catch (error) {
    console.error('❌ PUT /api/location-qr-bypass/:locationId error:', error);
    if (connection) connection.release();
    res.status(500).json({
      success: false,
      error: 'Failed to update bypass setting',
      message: error instanceof Error ? error.message : '',
    });
  }
});

// Check if a location has QR bypass enabled (for mitra app)
router.get('/:locationId/check', async (req: Request, res: Response) => {
  const { locationId } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    console.log(`🟢 GET /api/location-qr-bypass/${locationId}/check - Checking bypass status`);

    const [rows] = await connection.query(
      `SELECT 
        l.id,
        l.name,
        COALESCE(qb.qr_bypass_enabled, 0) as qr_bypass_enabled
       FROM locations l
       LEFT JOIN location_qr_bypass_settings qb ON l.id = qb.location_id
       WHERE l.id = ?`,
      [locationId]
    );

    connection.release();

    if (!Array.isArray(rows) || rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Location not found',
      });
    }

    const location = rows[0] as any;

    res.json({
      success: true,
      data: {
        location_id: location.id,
        location_name: location.name,
        qr_bypass_enabled: Boolean(location.qr_bypass_enabled),
      },
    });
  } catch (error) {
    console.error('❌ GET /api/location-qr-bypass/:locationId/check error:', error);
    if (connection) connection.release();
    res.status(500).json({
      success: false,
      error: 'Failed to check bypass status',
      message: error instanceof Error ? error.message : '',
    });
  }
});

export default router;
