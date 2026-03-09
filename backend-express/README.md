# Backend Express - Unified Backend for Admin & SuperAdmin

Backend Express yang terunifikasi untuk Admin dan SuperAdmin panel dengan route grouping.

## Features

- ✅ Shared backend untuk Admin dan SuperAdmin
- ✅ TypeScript + Express.js
- ✅ MySQL Database (nebeng-bro)
- ✅ Route Grouping berdasarkan role (Admin & SuperAdmin)
- ✅ QR Bypass Management API
- ✅ Complete Trip API untuk mitra

## Port

- **Port 3001** - Backend Express Server

## Setup

1. Install dependencies:
```bash
npm install
```

2. Setup environment:
```bash
cp .env.example .env
```

Edit `.env` dan sesuaikan konfigurasi database:
```env
NODE_ENV=development
PORT=3001

DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=nebeng-bro

JWT_SECRET=your_secret_key_here
```

3. Jalankan server:
```bash
npm run dev
```

Server akan berjalan di: http://localhost:3001

## API Route Structure

### ADMIN ROUTES (prefix: `/api/admin`)
Khusus untuk Admin Dashboard (folder: `admin/`)

- `POST /api/admin/auth/login` - Login admin
- `GET /api/admin/customers` - Manage customers
- `GET /api/admin/dashboard` - Dashboard stats
- `GET /api/admin/mitra` - Manage mitra/drivers
- `GET /api/admin/pesanan` - Manage orders
- `GET /api/admin/laporan` - Reports
- `GET /api/admin/refund` - Refund management
- `GET /api/admin/verifikasi` - Verification

**Frontend Config:**
```env
# admin/.env
VITE_API_URL=http://localhost:3001/api/admin
```

### SUPERADMIN ROUTES (prefix: `/api/superadmin`)
Khusus untuk SuperAdmin Dashboard (folder: `superadmin/`)

- `POST /api/superadmin/auth/login` - Login superadmin
- `GET /api/superadmin/admin` - Manage admins
- `GET /api/superadmin/locations` - Manage locations
- `GET /api/superadmin/posmitra` - Manage PosMitra
- `GET /api/superadmin/posmitra-users` - Manage PosMitra users
- `GET /api/superadmin/banners` - Manage banners
- `GET /api/superadmin/reward` - Manage rewards
- `GET /api/superadmin/location-qr-bypass` - QR bypass settings

**Frontend Config:**
```env
# superadmin/.env
VITE_API_URL=http://localhost:3001/api/superadmin
VITE_API_BASE_URL=http://localhost:3001
```

### SHARED ROUTES (prefix: `/api`)
Digunakan oleh Mobile App dan kedua dashboard

- `POST /api/booking/:bookingType/:bookingId/complete-by-driver` - Complete trip tanpa QR (Mitra App)

**Mobile App Config:**
```dart
// Flutter
const API_BASE_URL = 'http://10.0.2.2:3001/api';
```

## Directory Structure

```
backend-express/
├── src/
│   ├── routes/
│   │   ├── admin/                    👥 ADMIN ROUTES
│   │   │   ├── auth.routes.ts        - Authentication
│   │   │   ├── customer.routes.ts    - Customer management
│   │   │   ├── dashboard.routes.ts   - Dashboard stats
│   │   │   ├── mitra.routes.ts       - Mitra/driver management
│   │   │   ├── pesanan.routes.ts     - Order management
│   │   │   ├── laporan.routes.ts     - Reports
│   │   │   ├── refund.routes.ts      - Refund management
│   │   │   └── verifikasi.routes.ts  - Verification
│   │   │
│   │   ├── superadmin/               🔐 SUPERADMIN ROUTES
│   │   │   ├── admin.routes.ts       - Admin management
│   │   │   ├── locations.routes.ts   - Location management
│   │   │   ├── posmitra.routes.ts    - PosMitra management
│   │   │   ├── posmitra-users.routes.ts - PosMitra user management
│   │   │   ├── banners.routes.ts     - Banner management
│   │   │   ├── reward.routes.tsx     - Reward management
│   │   │   └── qr-bypass.routes.ts   - QR bypass settings
│   │   │
│   │   └── booking.routes.ts         📱 SHARED (Mobile App)
│   │
│   ├── db.ts
│   └── ...
├── server.ts
├── package.json
└── README.md
```

## Route Grouping Benefits

1. **Clear Separation**: Admin dan SuperAdmin routes terpisah dengan jelas
2. **Easy Maintenance**: Mudah mengelola routes berdasarkan role
3. **Scalability**: Mudah menambah routes baru per group
4. **Security**: Bisa tambahkan middleware khusus per group
5. **Documentation**: Struktur yang jelas untuk developer
- `/api/auth` - Authentication
- `/api/admin` - Admin management
- `/api/customers` - Customer management
- `/api/dashboard` - Dashboard data
- `/api/mitra` - Mitra management
- `/api/pesanan` - Orders/bookings
- `/api/laporan` - Reports
- `/api/refund` - Refunds
- `/api/verifikasi` - Verifications
- `/api/locations` - Locations/terminals
- `/api/posmitra` - PosMitra management
- `/api/posmitra-users` - PosMitra users
- `/api/v1/banners` - Banners
- `/api/reward` - Rewards

## Frontend Configuration

### Admin Frontend
```env
VITE_API_BASE_URL=http://localhost:3001
```

### SuperAdmin Frontend
```env
VITE_API_BASE_URL=http://localhost:3001
```

### Mitra App (Flutter)
```dart
// Default API URL for Android emulator
const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3001')
```

## Database

Menggunakan database MySQL: **nebeng-bro**

Migration dikelola oleh Laravel backend di folder `backend/`.

## Development

```bash
# Development mode with auto-reload
npm run dev

# Build for production
npm run build

# Production mode
npm start
```

## Scripts

- `npm run dev` - Development mode (auto-reload)
- `npm run build` - Build TypeScript ke JavaScript
- `npm start` - Production mode
- `npm run init-db` - Initialize database
- `npm run test-db` - Test database connection

## File Structure

```
backend-express/
├── server.ts          # Main server file
├── package.json       # Dependencies
├── tsconfig.json      # TypeScript config
├── .env              # Environment variables
└── src/
    ├── db.ts         # Database connection
    └── routes/       # API routes
        ├── admin.routes.ts
        ├── auth.routes.ts
        ├── booking.routes.ts
        ├── customer.routes.ts
        ├── dashboard.routes.ts
        ├── laporan.routes.ts
        ├── locations.routes.ts
        ├── mitra.routes.ts
        ├── pesanan.routes.ts
        ├── posmitra.routes.ts
        ├── posmitra-users.routes.ts
        ├── qr-bypass.routes.ts
        ├── refund.routes.ts
        └── verifikasi.routes.ts
```

## Notes

- Backend ini menggantikan backend yang ada di `admin/backend` dan `superadmin/backend`
- Semua frontend (admin dan superadmin) harus pointing ke backend ini
- Database tetap menggunakan MySQL dengan nama `nebeng-bro`
- Migration database masih menggunakan Laravel di folder `backend/`
