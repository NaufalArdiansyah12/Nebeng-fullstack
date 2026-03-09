import express from 'express';
import { pool } from '../../db.js';

const router = express.Router();

// Get dashboard stats
router.get('/stats', async (req, res) => {
  try {
    // Simplified query - count separately then combine
    const [mitraCount] = await pool.query(`SELECT COUNT(*) as count FROM users WHERE role = 'mitra'`);
    const [customerCount] = await pool.query(`SELECT COUNT(*) as count FROM users WHERE role = 'customer'`);
    const [bookingMobilCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_mobil`);
    const [bookingMotorCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_motor`);
    const [bookingBarangCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_barang`);
    const [bookingTitipBarangCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_titip_barang`);
    
    const totalMitra = (mitraCount as any[])[0].count;
    const totalCustomer = (customerCount as any[])[0].count;
    const totalPesanan = (bookingMobilCount as any[])[0].count + 
                         (bookingMotorCount as any[])[0].count + 
                         (bookingBarangCount as any[])[0].count + 
                         (bookingTitipBarangCount as any[])[0].count;
    
    const stats = {
      total_mitra: totalMitra,
      total_customer: totalCustomer,
      total_pesanan: totalPesanan,
      total_pendapatan: 0, // TODO: Calculate from payments table
      verified_mitra: totalMitra, // Simplified
      verified_customer: totalCustomer // Simplified
    };
    
    res.json({
      totalMitra: Number(stats.total_mitra) || 0,
      totalCustomer: Number(stats.total_customer) || 0,
      totalPesanan: Number(stats.total_pesanan) || 0,
      totalPendapatan: Number(stats.total_pendapatan) || 0,
      verifiedMitra: Number(stats.verified_mitra) || 0,
      verifiedCustomer: Number(stats.verified_customer) || 0
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats' });
  }
});

// Get orders chart data
router.get('/orders/chart', async (req, res) => {
  try {
    const { month, year } = req.query;
    
    // Build date filter
    let dateFilter = '';
    if (month && year) {
      dateFilter = `AND MONTH(created_at) = ${parseInt(month as string)} AND YEAR(created_at) = ${parseInt(year as string)}`;
    }
    
    // Get counts for each booking type
    const [mobilCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_mobil WHERE 1=1 ${dateFilter}`);
    const [motorCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_motor WHERE 1=1 ${dateFilter}`);
    const [barangCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_barang WHERE 1=1 ${dateFilter}`);
    const [titipBarangCount] = await pool.query(`SELECT COUNT(*) as count FROM booking_titip_barang WHERE 1=1 ${dateFilter}`);
    
    const chartData = [
      { name: "Nebeng Mobil", value: (mobilCount as any[])[0].count, color: "#1e3a5f" },
      { name: "Nebeng Motor", value: (motorCount as any[])[0].count, color: "#1e3a5f" },
      { name: "Nebeng Barang", value: (barangCount as any[])[0].count, color: "#6366f1" },
      { name: "Titip Barang", value: (titipBarangCount as any[])[0].count, color: "#6366f1" }
    ];
    
    res.json({ success: true, data: chartData });
  } catch (error) {
    console.error('Error fetching orders chart:', error);
    res.status(500).json({ error: 'Failed to fetch orders chart' });
  }
});

// Get top destinations
router.get('/destinations/top', async (req, res) => {
  try {
    const { month, year } = req.query;
    
    // Build date filter
    let dateFilter = '';
    if (month && year) {
      dateFilter = `AND MONTH(t.created_at) = ${parseInt(month as string)} AND YEAR(t.created_at) = ${parseInt(year as string)}`;
    }
    
    const [rows] = await pool.query(`
      SELECT l.name as kotaTujuan, COUNT(*) as total
      FROM tebengan_mobil t
      JOIN locations l ON t.destination_location_id = l.id
      WHERE 1=1 ${dateFilter}
      GROUP BY l.id, l.name
      ORDER BY total DESC
      LIMIT 5
    `);
    
    // Transform to expected format
    const transformed = (rows as any[]).map((row, index) => ({
      no: index + 1,
      kotaAsal: '-', // Not tracked in current schema
      kotaTujuan: row.kotaTujuan,
      total: String(row.total)
    }));
    
    res.json(transformed);
  } catch (error) {
    console.error('Error fetching top destinations:', error);
    res.status(500).json({ error: 'Failed to fetch top destinations' });
  }
});

// Get recent mitra
router.get('/mitra/recent', async (req, res) => {
  try {
    const { month, year } = req.query;
    
    // Build date filter
    let dateFilter = '';
    if (month && year) {
      dateFilter = `AND MONTH(u.created_at) = ${parseInt(month as string)} AND YEAR(u.created_at) = ${parseInt(year as string)}`;
    }
    
    const [rows] = await pool.query(`
      SELECT u.id, u.name, u.email, u.phone, u.status, u.gender, u.created_at
      FROM users u
      WHERE u.role = 'mitra' ${dateFilter}
      ORDER BY u.created_at DESC
      LIMIT 5
    `);
    
    const transformed = (rows as any[]).map(m => ({
      id: String(m.id),
      nama: m.name,
      email: m.email,
      noTlp: m.phone || '',
      gender: m.gender || '-',
      status: m.status || 'active',
      tanggal: m.created_at
    }));
    
    res.json(transformed);
  } catch (error) {
    console.error('Error fetching recent mitra:', error);
    res.status(500).json({ error: 'Failed to fetch recent mitra' });
  }
});

// Get all mitra for dashboard
router.get('/mitra/all', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT u.id, u.name, u.email, u.phone, u.status, u.created_at
      FROM users u
      WHERE u.role = 'mitra'
      ORDER BY u.created_at DESC
    `);
    
    const transformed = (rows as any[]).map(m => ({
      id: String(m.id),
      nama: m.name,
      email: m.email,
      noTlp: m.phone || '',
      status: m.status || 'pending',
      tanggal: m.created_at
    }));
    
    res.json(transformed);
  } catch (error) {
    console.error('Error fetching all mitra:', error);
    res.status(500).json({ error: 'Failed to fetch all mitra' });
  }
});

export default router;
