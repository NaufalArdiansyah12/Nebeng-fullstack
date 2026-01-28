# Nebeng Admin - Backend & Database

Backend folder untuk Nebeng Admin aplikasi dengan MySQL database.

## Quick Start

1. **Setup Database**
   ```bash
   mysql -u root -p < backend/database/schema.sql
   ```

2. **Install Dependencies**
   ```bash
   cd backend
   npm install
   ```

3. **Configure Environment**
   ```bash
   cp .env.example .env
   # Edit .env dengan MySQL credentials
   ```

4. **Start Server**
   ```bash
   npm run dev
   ```

Server akan jalan di `http://localhost:3001`

## Struktur Folder

```
backend/
├── src/
│   ├── routes/           # API routes
│   │   ├── admin.routes.ts
│   │   ├── customer.routes.ts
│   │   ├── mitra.routes.ts
│   │   ├── pesanan.routes.ts
│   │   ├── laporan.routes.ts
│   │   └── refund.routes.ts
│   └── server.ts         # Main server file
├── database/
│   └── schema.sql        # Database schema
├── .env.example          # Environment template
├── tsconfig.json         # TypeScript config
└── package.json          # Dependencies
```

## API Features

✅ Admin management  
✅ Customer CRUD + block/unblock  
✅ Mitra/Driver CRUD + vehicle management  
✅ Order management  
✅ Report handling  
✅ Refund processing  

## Database Tables

- `admin` - Admin users
- `customer` - Customers
- `mitra` - Drivers
- `kendaraan_mitra` - Vehicles
- `pesanan` - Orders
- `perjalanan` - Trip details
- `pembayaran` - Payments
- `laporan` - Reports
- `refund` - Refunds
- `pengaturan` - Settings

Lihat `SETUP_GUIDE.md` untuk dokumentasi lengkap.
