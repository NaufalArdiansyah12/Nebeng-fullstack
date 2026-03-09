import express from 'express';
import type { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

const app: Express = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
// Increase body size limit to support larger base64 images from frontend
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Health check endpoint
app.get('/api/health', (req: Request, res: Response) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Import database connection
import { pool } from './src/db.ts';

// ========================================
// ADMIN ROUTES (untuk dashboard admin)
// ========================================
import authRoutes from './src/routes/admin/auth.routes.ts';
import customerRoutes from './src/routes/admin/customer.routes.ts';
import dashboardRoutes from './src/routes/admin/dashboard.routes.ts';
import mitraRoutes from './src/routes/admin/mitra.routes.ts';
import pesananRoutes from './src/routes/admin/pesanan.routes.ts';
import laporanRoutes from './src/routes/admin/laporan.routes.ts';
import refundRoutes from './src/routes/admin/refund.routes.ts';
import verifikasiRoutes from './src/routes/admin/verifikasi.routes.ts';

// ========================================
// SUPERADMIN ROUTES (untuk dashboard superadmin)
// ========================================
import adminRoutes from './src/routes/superadmin/admin.routes.ts';
import locationsRoutes from './src/routes/superadmin/locations.routes.ts';
import posmitraRoutes from './src/routes/superadmin/posmitra.routes.ts';
import posmitraUsersRoutes from './src/routes/superadmin/posmitra-users.routes.ts';
import bannersRoutes from './src/routes/superadmin/banners.routes.ts';
import rewardRoutes from './src/routes/superadmin/reward.routes.tsx';
import qrBypassRoutes from './src/routes/superadmin/qr-bypass.routes.ts';
import superadminDashboardRoutes from './src/routes/superadmin/dashboard.routes.ts';
import superadminMitraRoutes from './src/routes/superadmin/mitra.routes.ts';
import superadminCustomersRoutes from './src/routes/superadmin/customers.routes.ts';
import superadminVerifikasiRoutes from './src/routes/superadmin/verifikasi.routes.ts';
import superadminPesananRoutes from './src/routes/superadmin/pesanan.routes.ts';
import superadminLaporanRoutes from './src/routes/superadmin/laporan.routes.ts';
import superadminRefundRoutes from './src/routes/superadmin/refund.routes.ts';

// ========================================
// SHARED ROUTES (digunakan admin, superadmin, dan mobile app)
// ========================================
import bookingRoutes from './src/routes/booking.routes.ts';

// ========================================
// REGISTER ADMIN ROUTES
// ========================================
app.use('/api/admin/auth', authRoutes);
app.use('/api/admin/customers', customerRoutes);
app.use('/api/admin/dashboard', dashboardRoutes);
app.use('/api/admin/mitra', mitraRoutes);
app.use('/api/admin/pesanan', pesananRoutes);
app.use('/api/admin/laporan', laporanRoutes);
app.use('/api/admin/refund', refundRoutes);
app.use('/api/admin/verifikasi', verifikasiRoutes);
app.use('/api/admin/banners', bannersRoutes);
app.use('/api/admin/reward', rewardRoutes);

// ========================================
// REGISTER SUPERADMIN ROUTES
// ========================================
app.use('/api/superadmin/auth', authRoutes); // Auth shared but accessed via different prefix
app.use('/api/superadmin/admin', adminRoutes);
app.use('/api/superadmin/dashboard', superadminDashboardRoutes);
app.use('/api/superadmin/mitra', superadminMitraRoutes);
app.use('/api/superadmin/customers', superadminCustomersRoutes);
app.use('/api/superadmin/verifikasi', superadminVerifikasiRoutes);
app.use('/api/superadmin/pesanan', superadminPesananRoutes);
app.use('/api/superadmin/laporan', superadminLaporanRoutes);
app.use('/api/superadmin/refund', superadminRefundRoutes);
app.use('/api/superadmin/locations', locationsRoutes);
app.use('/api/superadmin/posmitra', posmitraRoutes);
app.use('/api/superadmin/posmitra-users', posmitraUsersRoutes);
app.use('/api/superadmin/banners', bannersRoutes);
app.use('/api/superadmin/reward', rewardRoutes);
app.use('/api/superadmin/location-qr-bypass', qrBypassRoutes);

// ========================================
// REGISTER SHARED ROUTES (for mobile app & both dashboards)
// ========================================
app.use('/api/booking', bookingRoutes);
// QR Bypass check for mobile app (without auth prefix)
app.use('/api/location-qr-bypass', qrBypassRoutes);

// Serve uploaded files
// Primary: backend-express/public/uploads (file baru)
app.use('/uploads', express.static(path.join(process.cwd(), 'public', 'uploads')));
// Fallback: backend (Laravel)/public/uploads (file lama yang diupload via Laravel/Android)
app.use('/uploads', express.static(path.join(process.cwd(), '..', 'backend', 'public', 'uploads')));

// Ensure banners.image_url can store large base64 payloads
(async function ensureBannerColumn() {
  try {
    await pool.execute("ALTER TABLE banners MODIFY image_url MEDIUMTEXT NULL;");
    console.log('✅ Ensured banners.image_url is MEDIUMTEXT');
  } catch (err: any) {
    // If table/column doesn't exist yet, just log and continue
    console.warn('⚠️ Could not alter banners.image_url:', err.message);
  }
})();

// Ensure rewards.image_url can store large base64 payloads (for admin uploads)
(async function ensureRewardsColumn() {
  try {
    await pool.execute("ALTER TABLE rewards MODIFY image_url MEDIUMTEXT NULL;");
    console.log('✅ Ensured rewards.image_url is MEDIUMTEXT');
  } catch (err: any) {
    console.warn('⚠️ Could not alter rewards.image_url:', err.message);
  }
})();

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Centralized error handler (placed after routes)
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error', stack: err.stack });
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Server running at http://localhost:${PORT}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️  Database: ${process.env.DB_NAME}`);
});
