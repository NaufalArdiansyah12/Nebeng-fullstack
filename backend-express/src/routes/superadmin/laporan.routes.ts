import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// Get laporan
router.get('/', async (req, res) => {
  try {
    // For now, just return empty array - can be expanded later
    res.json([]);
  } catch (error) {
    console.error('Error fetching laporan:', error);
    res.status(500).json({ error: 'Failed to fetch laporan' });
  }
});

export default router;
