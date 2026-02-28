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

// Import routes
import authRoutes from './src/routes/auth.routes.ts';
import adminRoutes from './src/routes/admin.routes.ts';
import customerRoutes from './src/routes/customer.routes.ts';
import dashboardRoutes from './src/routes/dashboard.routes.ts';
import mitraRoutes from './src/routes/mitra.routes.ts';
import pesananRoutes from './src/routes/pesanan.routes.ts';
import laporanRoutes from './src/routes/laporan.routes.ts';
import refundRoutes from './src/routes/refund.routes.ts';
import verifikasiRoutes from './src/routes/verifikasi.routes.ts';
import locationsRoutes from './src/routes/locations.routes.ts';
import posmitraRoutes from './src/routes/posmitra.routes.ts';
import posmitraUsersRoutes from './src/routes/posmitra-users.routes.ts';
import bannersRoutes from './src/routes/banners.routes.ts';

// Import database connection
import { pool } from './src/db.ts';

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/mitra', mitraRoutes);
app.use('/api/pesanan', pesananRoutes);
app.use('/api/laporan', laporanRoutes);
app.use('/api/refund', refundRoutes);
app.use('/api/verifikasi', verifikasiRoutes);
app.use('/api/locations', locationsRoutes);
app.use('/api/posmitra', posmitraRoutes);
app.use('/api/posmitra-users', posmitraUsersRoutes);
app.use('/api/v1/banners', bannersRoutes);

// Serve uploaded files
app.use('/uploads', express.static(path.join(process.cwd(), 'public', 'uploads')));

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
