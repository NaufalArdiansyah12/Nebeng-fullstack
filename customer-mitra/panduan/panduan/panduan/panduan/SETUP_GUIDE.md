# Nebeng Admin Backend Setup Guide

## Prerequisites

- Node.js v18+ dan npm/yarn/bun
- MySQL 8.0+

## Installation

### 1. Backend Setup

```bash
cd backend
npm install
# or
yarn install
# or
bun install
```

### 2. Database Setup

#### Option A: Menggunakan MySQL CLI

```bash
# Buka MySQL
mysql -u root -p

# Run SQL script
source database/schema.sql
```

#### Option B: Manual

1. Buka MySQL Workbench atau MySQL Command Line
2. Copy seluruh isi file `backend/database/schema.sql`
3. Paste dan jalankan

### 3. Environment Configuration

Buat file `.env` di folder `backend`:

```bash
cp .env.example .env
```

Edit `.env` dengan konfigurasi database Anda:

```
NODE_ENV=development
PORT=3001

# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password_here
DB_NAME=nebeng_admin

JWT_SECRET=your_secret_key_here
```

### 4. Start Backend Server

```bash
npm run dev
```

Server akan berjalan di `http://localhost:3001`

## Frontend Setup

### 1. Create `.env` file di root project

```bash
VITE_API_URL=http://localhost:3001/api
```

### 2. Install dependencies

```bash
npm install
# or
bun install
```

### 3. Start Development Server

```bash
npm run dev
# or
bun dev
```

## API Endpoints

### Admin
- `GET /api/admin/profile` - Get admin profile
- `PUT /api/admin/profile` - Update admin profile

### Customers
- `GET /api/customers` - Get all customers
- `GET /api/customers/:id` - Get customer by ID
- `POST /api/customers` - Create customer
- `PUT /api/customers/:id` - Update customer
- `DELETE /api/customers/:id` - Delete customer
- `PATCH /api/customers/:id/status` - Update status
- `POST /api/customers/:id/block` - Block customer
- `POST /api/customers/:id/unblock` - Unblock customer

### Mitra (Drivers)
- `GET /api/mitra` - Get all mitra
- `GET /api/mitra/:id` - Get mitra by ID
- `POST /api/mitra` - Create mitra
- `PUT /api/mitra/:id` - Update mitra
- `DELETE /api/mitra/:id` - Delete mitra
- `PATCH /api/mitra/:id/status` - Update status
- `POST /api/mitra/:id/block` - Block mitra
- `POST /api/mitra/:id/unblock` - Unblock mitra
- `GET /api/mitra/:id/kendaraan` - Get kendaraan
- `POST /api/mitra/:id/kendaraan` - Add kendaraan

### Pesanan (Orders)
- `GET /api/pesanan` - Get all pesanan
- `GET /api/pesanan/:id` - Get pesanan by ID
- `POST /api/pesanan` - Create pesanan
- `PATCH /api/pesanan/:id/status` - Update status
- `POST /api/pesanan/:id/perjalanan` - Add perjalanan
- `POST /api/pesanan/:id/pembayaran` - Add pembayaran

### Laporan (Reports)
- `GET /api/laporan` - Get all laporan
- `GET /api/laporan/:id` - Get laporan by ID
- `POST /api/laporan` - Create laporan
- `PATCH /api/laporan/:id/status` - Update status
- `DELETE /api/laporan/:id` - Delete laporan

### Refund
- `GET /api/refund` - Get all refund
- `GET /api/refund/:id` - Get refund by ID
- `POST /api/refund` - Create refund
- `PATCH /api/refund/:id/status` - Update status
- `DELETE /api/refund/:id` - Delete refund

## Database Schema

### Tables

1. **admin** - Admin users
2. **customer** - Customer data
3. **mitra** - Driver/partner data
4. **kendaraan_mitra** - Driver vehicles
5. **pesanan** - Orders
6. **perjalanan** - Trip details
7. **pembayaran** - Payment records
8. **laporan** - Reports
9. **refund** - Refund records
10. **pengaturan** - Settings

## Troubleshooting

### Connection Error
- Pastikan MySQL running
- Check DB credentials di `.env`
- Verify database sudah di-create

### Port Already in Use
```bash
# Find process using port 3001
netstat -ano | findstr :3001

# Kill process (Windows)
taskkill /PID <PID> /F

# Or use different port
PORT=3002 npm run dev
```

### CORS Error
- Backend harus running
- API_URL di frontend harus sesuai dengan backend URL

## Development Tips

- Backend logs akan muncul di terminal
- Check network tab di DevTools untuk API calls
- Database akan persist setelah server restart
- Untuk reset database, jalankan ulang `schema.sql`

## Production Deployment

1. Build frontend: `npm run build`
2. Setup backend di production server
3. Update `.env` dengan production credentials
4. Setup MySQL di production
5. Use process manager seperti PM2 untuk backend

## Support

Jika ada error, check:
1. MySQL connection
2. Environment variables
3. Database schema sudah tercipta
4. Backend server running
