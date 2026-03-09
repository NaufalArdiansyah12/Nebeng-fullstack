import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// Get all pesanan (bookings)
router.get('/', async (req, res) => {
  try {
    // For now, just return empty array - can be expanded later
    res.json([]);
  } catch (error) {
    console.error('Error fetching pesanan:', error);
    res.status(500).json({ error: 'Failed to fetch pesanan' });
  }
});

export default router;
