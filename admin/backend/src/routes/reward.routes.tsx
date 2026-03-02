import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';
import fs from 'fs';
import path from 'path';

const router = express.Router();

// Helpers for saving base64 images to disk to avoid storing huge blobs in DB
const ensureDir = (dir: string) => {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
};

const saveBase64Image = async (dataUrl: string, subfolder = 'rewards') => {
  try {
    const m = dataUrl.match(/^data:(image\/[^;]+);base64,(.+)$/);
    if (!m) return null;
    const mime = m[1];
    const base64 = m[2];
    const ext = mime.split('/')[1] || 'png';
    const filename = `reward_${Date.now()}_${Math.random().toString(36).slice(2,8)}.${ext}`;
    const uploadsDir = path.join(process.cwd(), 'public', 'uploads', subfolder);
    ensureDir(uploadsDir);
    const filePath = path.join(uploadsDir, filename);
    await fs.promises.writeFile(filePath, Buffer.from(base64, 'base64'));
    // Public URL served by express static at /uploads
    const publicBase = process.env.PUBLIC_BASE_URL || `http://localhost:${process.env.PORT || 3001}`;
    const publicPath = `${publicBase}/uploads/${subfolder}/${filename}`;
    return publicPath;
  } catch (err) {
    console.error('Failed to save base64 image:', err);
    return null;
  }
};

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

// --- Reward catalog CRUD (rewards table) ---
// Create reward
router.post('/rewards', async (req: Request, res: Response) => {
  const { title, description, points_cost, image_url, stock } = req.body;

  if (!title || typeof points_cost === 'undefined') {
    return res.status(400).json({ error: 'title and points_cost are required' });
  }

  try {
    // If image is a base64 data URL, save it to disk and store public URL instead
    let imgUrl = image_url || null;
    if (typeof imgUrl === 'string' && imgUrl.startsWith('data:')) {
      const saved = await saveBase64Image(imgUrl, 'rewards');
      if (saved) imgUrl = saved;
    }

    const connection = await pool.getConnection();
    const [result]: any = await connection.execute(
      `INSERT INTO rewards (title, description, points_cost, image_url, stock, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, NOW(), NOW())`,
      [title, description || null, points_cost, imgUrl || null, stock || 0]
    );
    const insertId = result?.insertId;
    // return created row
    const [rows] = await connection.query('SELECT * FROM rewards WHERE id = ?', [insertId]);
    connection.release();
    res.status(201).json({ message: 'Reward created', data: Array.isArray(rows) ? rows[0] : null });
  } catch (error) {
    console.error('❌ POST /api/reward/rewards error:', error);
    res.status(500).json({ error: 'Failed to create reward', message: error instanceof Error ? error.message : '' });
  }
});

// Update reward
router.put('/rewards/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { title, description, points_cost, image_url, stock } = req.body;

  try {
    console.log('🔁 PUT /api/reward/rewards/:id called', { id, body: req.body });
    // If image is base64, save to disk and replace with public URL
    let imgUrl = image_url || null;
    if (typeof imgUrl === 'string' && imgUrl.startsWith('data:')) {
      const saved = await saveBase64Image(imgUrl, 'rewards');
      if (saved) imgUrl = saved;
    }

    const connection = await pool.getConnection();
    await connection.execute(
      `UPDATE rewards SET title = ?, description = ?, points_cost = ?, image_url = ?, stock = ?, updated_at = NOW() WHERE id = ?`,
      [title, description || null, points_cost || 0, imgUrl || null, stock || 0, id]
    );
    const [rows] = await connection.query('SELECT * FROM rewards WHERE id = ?', [id]);
    connection.release();
    res.json({ message: 'Reward updated', data: Array.isArray(rows) ? rows[0] : null });
  } catch (error) {
    console.error('❌ PUT /api/reward/rewards/:id error:', error instanceof Error ? error.message : error, error instanceof Error ? error.stack : 'no-stack');
    res.status(500).json({ error: 'Failed to update reward', message: error instanceof Error ? error.message : String(error) });
  }
});

// Delete reward
router.delete('/rewards/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const connection = await pool.getConnection();
    await connection.execute('DELETE FROM rewards WHERE id = ?', [id]);
    connection.release();
    res.json({ message: 'Reward deleted' });
  } catch (error) {
    console.error('❌ DELETE /api/reward/rewards/:id error:', error);
    res.status(500).json({ error: 'Failed to delete reward', message: error instanceof Error ? error.message : '' });
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
