import express from 'express';
import type { Request, Response } from 'express';
import { pool } from '../db.ts';

const router = express.Router();

// Get dashboard statistics
router.get('/stats', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    // Get total mitra count
    const [mitraResult] = await connection.query(
      'SELECT COUNT(*) as total FROM users WHERE role = "mitra"'
    );
    const totalMitra = (mitraResult as any[])[0]?.total || 0;

    // Get total customer count
    const [customerResult] = await connection.query(
      'SELECT COUNT(*) as total FROM users WHERE role = "customer"'
    );
    const totalCustomer = (customerResult as any[])[0]?.total || 0;

    // Get verified mitra count (approved KTP)
    const [verifiedMitraResult] = await connection.query(
      'SELECT COUNT(*) as total FROM verifikasi_ktp_mitras WHERE status = "approved"'
    );
    const verifiedMitra = (verifiedMitraResult as any[])[0]?.total || 0;

    // Get verified customer count (approved KTP)
    const [verifiedCustomerResult] = await connection.query(
      'SELECT COUNT(*) as total FROM verifikasi_ktp_customers WHERE status = "approved"'
    );
    const verifiedCustomer = (verifiedCustomerResult as any[])[0]?.total || 0;

    connection.release();

    res.json({
      totalMitra,
      totalCustomer,
      verifiedMitra,
      verifiedCustomer
    });

  } catch (error) {
    console.error('❌ GET /api/dashboard/stats error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch dashboard stats',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get order statistics for chart
router.get('/orders/chart', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const { month, year } = req.query;
    let dateFilter = '';

    if (month && year) {
      // Filter by specific month and year
      const monthNum = parseInt(month as string);
      const yearNum = parseInt(year as string);
      dateFilter = `AND YEAR(created_at) = ${yearNum} AND MONTH(created_at) = ${monthNum}`;
    } else {
      // Default to last 30 days if no month/year specified
      dateFilter = 'AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
    }

    // Get order counts from all booking tables
    const [motorCount] = await connection.query(
      `SELECT COUNT(*) as count FROM booking_motor WHERE 1=1 ${dateFilter}`
    ).catch(() => [{ count: 0 }]);
    const [mobilCount] = await connection.query(
      `SELECT COUNT(*) as count FROM booking_mobil WHERE 1=1 ${dateFilter}`
    ).catch(() => [{ count: 0 }]);
    const [barangCount] = await connection.query(
      `SELECT COUNT(*) as count FROM booking_barang WHERE 1=1 ${dateFilter}`
    ).catch(() => [{ count: 0 }]);
    const [titipBarangCount] = await connection.query(
      `SELECT COUNT(*) as count FROM booking_titip_barang WHERE 1=1 ${dateFilter}`
    ).catch(() => [{ count: 0 }]);

    // Transform to chart format
    const chartData = [
      { name: "Nebeng Motor", value: (motorCount as any[])[0]?.count || 0, color: "#1e3a5f" },
      { name: "Nebeng Mobil", value: (mobilCount as any[])[0]?.count || 0, color: "#1e3a5f" },
      { name: "Nebeng Barang", value: (barangCount as any[])[0]?.count || 0, color: "#6366f1" },
      { name: "Titip Barang", value: (titipBarangCount as any[])[0]?.count || 0, color: "#6366f1" },
    ];

    connection.release();

    res.json({
      data: chartData,
      total: chartData.reduce((sum, item) => sum + item.value, 0)
    });

  } catch (error) {
    console.error('❌ GET /api/dashboard/orders/chart error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch order chart data',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get top destinations
router.get('/destinations/top', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const { month, year } = req.query;
    let dateFilter = '';

    if (month && year) {
      // Filter by specific month and year
      const monthNum = parseInt(month as string);
      const yearNum = parseInt(year as string);
      dateFilter = `WHERE YEAR(tebengan_mobil.created_at) = ${yearNum} AND MONTH(tebengan_mobil.created_at) = ${monthNum}`;
    } else {
      // Default to last 30 days if no month/year specified
      dateFilter = 'WHERE tebengan_mobil.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
    }

    // Get top destination routes from tebengan tables
    const [destinationResult] = await connection.query(`
      SELECT
        origin_loc.city as kotaAsal,
        dest_loc.city as kotaTujuan,
        COUNT(*) as total
      FROM tebengan_mobil
      LEFT JOIN locations origin_loc ON tebengan_mobil.origin_location_id = origin_loc.id
      LEFT JOIN locations dest_loc ON tebengan_mobil.destination_location_id = dest_loc.id
      ${dateFilter}
      GROUP BY origin_loc.city, dest_loc.city
      HAVING COUNT(*) > 0
      ORDER BY total DESC
      LIMIT 7
    `).catch((error) => {
      console.error('❌ Destinations query error:', error);
      return [[]]; // Return empty array on error
    });

    const destinations = (destinationResult as any[]).map((row, index) => ({
      no: index + 1,
      kotaAsal: row.kotaAsal || 'Unknown',
      kotaTujuan: row.kotaTujuan || 'Unknown',
      total: row.total.toString()
    }));

    connection.release();

    res.json(destinations);

  } catch (error) {
    console.error('❌ GET /api/dashboard/destinations/top error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch top destinations',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get recent mitra data
router.get('/mitra/recent', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const { month, year } = req.query;
    let dateFilter = '';

    if (month && year) {
      // Filter by specific month and year when mitra registered
      const monthNum = parseInt(month as string);
      const yearNum = parseInt(year as string);
      dateFilter = `AND YEAR(u.created_at) = ${yearNum} AND MONTH(u.created_at) = ${monthNum}`;
    }

    const [mitraResult] = await connection.query(`
      SELECT
        u.id,
        u.name as nama,
        u.email,
        u.phone as no_tlp,
        'Motor' as layanan,
        COALESCE(v.status, 'pending') as status,
        u.created_at
      FROM users u
      LEFT JOIN verifikasi_ktp_mitras v ON u.id = v.mitra_id
      WHERE u.role = 'mitra' ${dateFilter}
      ORDER BY u.created_at DESC
      LIMIT 10
    `);

    const mitraData = (mitraResult as any[]).map(mitra => ({
      id: mitra.id.toString(),
      nama: mitra.nama,
      email: mitra.email,
      noTlp: mitra.no_tlp || '',
      layanan: mitra.layanan,
      status: mapStatusToFrontend(mitra.status)
    }));

    connection.release();

    res.json(mitraData);

  } catch (error) {
    console.error('❌ GET /api/dashboard/mitra/recent error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch recent mitra data',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Get all mitra data
router.get('/mitra/all', async (req: Request, res: Response) => {
  let connection;
  try {
    connection = await pool.getConnection();

    const [mitraResult] = await connection.query(`
      SELECT
        u.id,
        u.name as nama,
        u.email,
        u.phone as no_tlp,
        'Motor' as layanan,
        COALESCE(v.status, 'pending') as status,
        u.created_at
      FROM users u
      LEFT JOIN verifikasi_ktp_mitras v ON u.id = v.mitra_id
      WHERE u.role = 'mitra'
      ORDER BY u.created_at DESC
    `);

    const mitraData = (mitraResult as any[]).map(mitra => ({
      id: mitra.id.toString(),
      nama: mitra.nama,
      email: mitra.email,
      noTlp: mitra.no_tlp || '',
      layanan: mitra.layanan,
      status: mapStatusToFrontend(mitra.status)
    }));

    connection.release();

    res.json(mitraData);

  } catch (error) {
    console.error('❌ GET /api/dashboard/mitra/all error:', error);
    if (connection) connection.release();
    res.status(500).json({
      error: 'Failed to fetch all mitra data',
      message: error instanceof Error ? error.message : ''
    });
  }
});

// Helper function to map database status to frontend status
function mapStatusToFrontend(status: string): string {
  const statusMap: Record<string, string> = {
    'pending': 'PENGAJUAN',
    'approved': 'TERVERIFIKASI',
    'rejected': 'DITOLAK',
    'suspended': 'DIBLOCK'
  };
  return statusMap[status] || 'PENGAJUAN';
}

export default router;
