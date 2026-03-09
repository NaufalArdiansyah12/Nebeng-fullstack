import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// Get all refunds
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT * FROM refunds ORDER BY created_at DESC
    `);
    
    res.json(rows);
  } catch (error) {
    console.error('Error fetching refunds:', error);
    res.status(500).json({ error: 'Failed to fetch refunds' });
  }
});

// Get refund by ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const [rows] = await pool.query(`
      SELECT * FROM refunds WHERE id = ?
    `, [id]);
    
    if ((rows as any[]).length === 0) {
      return res.status(404).json({ error: 'Refund not found' });
    }
    
    res.json((rows as any[])[0]);
  } catch (error) {
    console.error('Error fetching refund:', error);
    res.status(500).json({ error: 'Failed to fetch refund' });
  }
});

export default router;
