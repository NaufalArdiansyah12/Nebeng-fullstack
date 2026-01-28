import express from 'express';
import type { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app: Express = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Error handling middleware
app.use((err: any, req: Request, res: Response, next: NextFunction) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// Health check endpoint
app.get('/api/health', (req: Request, res: Response) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Import routes
import authRoutes from './src/routes/auth.routes.ts';
import adminRoutes from './src/routes/admin.routes.ts';
import customerRoutes from './src/routes/customer.routes.ts';
import mitraRoutes from './src/routes/mitra.routes.ts';
import pesananRoutes from './src/routes/pesanan.routes.ts';
import laporanRoutes from './src/routes/laporan.routes.ts';
import refundRoutes from './src/routes/refund.routes.ts';
import verifikasiRoutes from './src/routes/verifikasi.routes.ts';

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/mitra', mitraRoutes);
app.use('/api/pesanan', pesananRoutes);
app.use('/api/laporan', laporanRoutes);
app.use('/api/refund', refundRoutes);
app.use('/api/verifikasi', verifikasiRoutes);

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Server running at http://localhost:${PORT}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🗄️  Database: ${process.env.DB_NAME}`);
});
