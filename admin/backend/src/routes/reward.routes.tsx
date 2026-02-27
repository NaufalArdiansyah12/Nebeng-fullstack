import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get all reward redemptions
router.get('/', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();

    const [redemptions] = await connection.query(
      `SELECT 
        rr.id,
        rr.user_id,
        rr.reward_id,
        rr.points_spent,
        rr.status,
        rr.metadata,
        rr.created_at,
        rr.updated_at,
        r.title as reward_name,
        r.description as reward_description,
        r.points_cost,
        u.name as user_name,
        u.email as user_email,
        u.phone as user_phone,
        COALESCE(u.reward_points, 0) as user_total_points,
        u.address as user_address
       FROM reward_redemptions rr
       LEFT JOIN rewards r ON rr.reward_id = r.id
       LEFT JOIN users u ON rr.user_id = u.id
       ORDER BY rr.created_at DESC`
    );

    connection.release();
    res.json(redemptions);
  } catch (error) {
    console.error('❌ GET /api/reward error:', error);
    res.status(500).json({ error: 'Failed to fetch reward redemptions', message: error instanceof Error ? error.message : '' });
  }
});

// Get reward redemption by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let connection;
  try {
    connection = await pool.getConnection();

    const [redemptions] = await connection.query(
      `SELECT 
        rr.id,
        rr.user_id,
        rr.reward_id,
        rr.points_spent,
        rr.status,
        rr.metadata,
        rr.created_at,
        rr.updated_at,
        r.title as reward_name,
        r.description as reward_description,
        r.points_cost,
        r.image_url as reward_image,
        u.name as user_name,
        u.email as user_email,
        u.phone as user_phone,
        COALESCE(u.reward_points, 0) as user_total_points,
        u.address as user_address
       FROM reward_redemptions rr
       LEFT JOIN rewards r ON rr.reward_id = r.id
       LEFT JOIN users u ON rr.user_id = u.id
       WHERE rr.id = ?`,
      [id]
    );

    connection.release();

    if (Array.isArray(redemptions) && redemptions.length > 0) {
      res.json(redemptions[0]);
    } else {
      res.status(404).json({ error: 'Reward redemption not found' });
    }
  } catch (error) {
    console.error('❌ GET /api/reward/:id error:', error);
    if (connection) {
      connection.release();
    }
    res.status(500).json({ error: 'Failed to fetch reward redemption', message: error instanceof Error ? error.message : '' });
  }
});

// Update reward redemption status
router.patch('/:id/status', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ error: 'Status is required' });
  }

  try {
    const connection = await pool.getConnection();

    await connection.execute(
      'UPDATE reward_redemptions SET status = ?, updated_at = NOW() WHERE id = ?',
      [status, id]
    );

    connection.release();
    res.json({ message: 'Reward redemption status updated successfully' });
  } catch (error) {
    console.error('❌ PATCH /api/reward/:id/status error:', error);
    res.status(500).json({ error: 'Failed to update reward redemption status', message: error instanceof Error ? error.message : '' });
  }
});

// Delete reward redemption
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const connection = await pool.getConnection();

    await connection.execute(
      'DELETE FROM reward_redemptions WHERE id = ?',
      [id]
    );

    connection.release();
    res.json({ message: 'Reward redemption deleted successfully' });
  } catch (error) {
    console.error('❌ DELETE /api/reward/:id error:', error);
    res.status(500).json({ error: 'Failed to delete reward redemption', message: error instanceof Error ? error.message : '' });
  }
});

// Get all rewards (for dropdown)
router.get('/rewards/all', async (req: Request, res: Response) => {
  try {
    const connection = await pool.getConnection();

    const [rewards] = await connection.query(
      'SELECT * FROM rewards ORDER BY points_cost ASC'
    );

    connection.release();
    res.json(rewards);
  } catch (error) {
    console.error('❌ GET /api/reward/rewards/all error:', error);
    res.status(500).json({ error: 'Failed to fetch rewards', message: error instanceof Error ? error.message : '' });
  }
});

// Create a new reward redemption
router.post('/', async (req: Request, res: Response) => {
  const { user_id, reward_id, points_spent, metadata } = req.body;

  if (!user_id || !reward_id || !points_spent) {
    return res.status(400).json({ error: 'user_id, reward_id, and points_spent are required' });
  }

  let connection;
  try {
    connection = await pool.getConnection();
    await connection.beginTransaction();

    // Check user's reward points
    const [userRows] = await connection.query<any[]>(
      'SELECT reward_points FROM users WHERE id = ?',
      [user_id]
    );

    if (!Array.isArray(userRows) || userRows.length === 0) {
      await connection.rollback();
      connection.release();
      return res.status(404).json({ error: 'User not found' });
    }

    const userRewardPoints = userRows[0]?.reward_points || 0;

    if (userRewardPoints < points_spent) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ error: 'Insufficient reward points' });
    }

    // Deduct points from user
    await connection.execute(
      'UPDATE users SET reward_points = reward_points - ? WHERE id = ?',
      [points_spent, user_id]
    );

    // Create redemption record
    const [result]: any = await connection.execute(
      'INSERT INTO reward_redemptions (user_id, reward_id, points_spent, status, metadata, created_at, updated_at) VALUES (?, ?, ?, ?, ?, NOW(), NOW())',
      [user_id, reward_id, points_spent, 'pending', JSON.stringify(metadata || {})]
    );

    await connection.commit();
    connection.release();

    res.status(201).json({ 
      message: 'Reward redemption created successfully', 
      id: result?.insertId 
    });
  } catch (error) {
    if (connection) {
      await connection.rollback();
      connection.release();
    }
    console.error('❌ POST /api/reward error:', error);
    res.status(500).json({ error: 'Failed to create reward redemption', message: error instanceof Error ? error.message : '' });
  }
});

export default router;
