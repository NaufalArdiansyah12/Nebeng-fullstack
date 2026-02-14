# Admin Panel - Petunjuk Penggunaan

## 📋 Informasi Umum

Admin Panel telah dikonversi dari SuperAdmin panel dan sekarang menggunakan Laravel backend (bukan Express.js).

**Backend:** Laravel 12 (Port 8000)  
**Frontend:** React + TypeScript + Vite (Port 5173)  
**Database:** MySQL

---

## 🚀 Cara Menjalankan

### 1. Backend (Laravel)

```bash
cd backend
php artisan serve
```

Server akan berjalan di `http://localhost:8000`

### 2. Frontend (React)

```bash
cd superadmin
npm install  # atau bun install
npm run dev  # atau bun dev
```

Frontend akan berjalan di `http://localhost:5173`

---

## 🔐 Login Admin

**URL:** http://localhost:5173

**Credentials:**
- Email: `admin@nebeng.com`
- Password: `admin123`

---

## 📊 Fitur Dashboard

### Stats Cards
Dashboard menampilkan 4 kartu statistik utama:
1. **Total Mitra** - Jumlah total mitra terdaftar
2. **Total Pelanggan** - Jumlah total customer
3. **Verifikasi Mitra** - Mitra yang menunggu verifikasi
4. **Verifikasi Pelanggan** - Customer yang menunggu verifikasi

### Grafik Pesanan
- Menampilkan grafik pesanan 7 hari terakhir
- Data diambil dari API `/api/admin/dashboard`

### Pesanan Terbaru
- Menampilkan 5 pesanan terbaru
- Informasi: Customer, Mitra, Total, Status

### Statistik Tambahan
- Total Pesanan
- Pesanan Selesai
- Pesanan Hari Ini
- Total Pendapatan

---

## 🔧 Struktur API

Semua endpoint admin menggunakan prefix: `/api/admin/*`

### Authentication
- `POST /api/admin/login` - Login admin
- `POST /api/admin/logout` - Logout admin
- `GET /api/admin/verify` - Verifikasi token
- `GET /api/admin/profile` - Get admin profile
- `PUT /api/admin/profile` - Update admin profile

### Dashboard
- `GET /api/admin/dashboard` - Get dashboard statistics

### Mitra Management
- `GET /api/admin/mitra` - Get all mitra
- `GET /api/admin/mitra/{id}` - Get mitra detail
- `PUT /api/admin/mitra/{id}/status` - Update mitra status
- `POST /api/admin/mitra/{id}/block` - Block mitra
- `POST /api/admin/mitra/{id}/unblock` - Unblock mitra

### Customer Management
- `GET /api/admin/customers` - Get all customers
- `GET /api/admin/customers/{id}` - Get customer detail
- `PUT /api/admin/customers/{id}/status` - Update customer status
- `POST /api/admin/customers/{id}/block` - Block customer
- `POST /api/admin/customers/{id}/unblock` - Unblock customer

### Pesanan Management
- `GET /api/admin/pesanan` - Get all orders
- `GET /api/admin/pesanan/{id}` - Get order detail
- `PUT /api/admin/pesanan/{id}/status` - Update order status

### Laporan
- `GET /api/admin/laporan` - Get all reports (dummy data)

### Refund
- `GET /api/admin/refund` - Get all refunds (dummy data)
- `PUT /api/admin/refund/{id}/status` - Update refund status (dummy)

---

## 🛡️ Middleware & Authorization

### AdminAuthMiddleware
Middleware `admin.auth` memastikan:
- User sudah login (ada token)
- Token valid
- User memiliki role `admin`
- Status user adalah `active`

**Lokasi:** `backend/app/Http/Middleware/AdminAuthMiddleware.php`

---

## 📁 Struktur File

### Backend
```
backend/
├── app/
│   └── Http/
│       ├── Controllers/
│       │   └── Admin/          # ✨ Folder khusus admin controllers
│       │       ├── AuthController.php
│       │       ├── DashboardController.php
│       │       ├── MitraController.php
│       │       ├── CustomerController.php
│       │       ├── PesananController.php
│       │       ├── LaporanController.php
│       │       └── RefundController.php
│       └── Middleware/
│           └── AdminAuthMiddleware.php
├── routes/
│   └── api.php                 # Admin routes dengan prefix /api/admin
└── config/
    └── cors.php                # CORS configuration
```

### Frontend
```
superadmin/
├── src/
│   ├── pages/
│   │   ├── Index.tsx           # Login page
│   │   ├── Dashboard.tsx       # ✅ Updated with Laravel API
│   │   ├── VerifikasiMitra.tsx
│   │   ├── VerifikasiCustomer.tsx
│   │   ├── DaftarMitra.tsx
│   │   └── DaftarCustomer.tsx
│   ├── contexts/
│   │   ├── AdminContext.tsx    # ✅ Updated for Laravel
│   │   ├── MitraContext.tsx    # ✅ Already integrated
│   │   ├── CustomerContext.tsx # ✅ Already integrated
│   │   ├── PesananContext.tsx  # ✅ Already integrated
│   │   ├── LaporanContext.tsx  # ✅ Already integrated
│   │   └── RefundContext.tsx   # ✅ Already integrated
│   └── services/
│       └── api.ts              # ✅ Updated base URL & endpoints
└── ...
```

---

## ⚙️ Konfigurasi

### Backend CORS
File: `backend/config/cors.php`

```php
'allowed_origins' => [
    'http://localhost:5173',
    'http://127.0.0.1:5173',
],
```

### Frontend Base URL
File: `superadmin/src/services/api.ts`

```typescript
const API_BASE_URL = 'http://localhost:8000/api/admin';
```

---

## 🔄 Response Format

Semua API mengembalikan format konsisten:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Success message"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "error": "Detailed error (development only)"
}
```

---

## 🧪 Testing

### Cek Routes
```bash
cd backend
php artisan route:list --path=api/admin
```

### Test Login API
```bash
curl -X POST http://localhost:8000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nebeng.com","password":"admin123"}'
```

### Test Protected Endpoint
```bash
curl -X GET http://localhost:8000/api/admin/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## 📝 Notes

1. **Token Storage:** Token disimpan di localStorage dengan key `adminToken`
2. **Auto Redirect:** Jika token invalid/expired, akan auto redirect ke login
3. **Status Enum:** User status menggunakan `active` / `blocked` / `pending`
4. **Role Check:** Admin harus memiliki role `admin` di database
5. **Dummy Data:** Laporan & Refund masih menggunakan dummy data

---

## 🐛 Troubleshooting

### 1. CORS Error
- Pastikan backend sudah running di port 8000
- Cek `config/cors.php` sudah benar
- Clear browser cache

### 2. 401 Unauthorized
- Token mungkin sudah expired
- Logout dan login ulang
- Cek database: user role harus `admin` dan status `active`

### 3. 404 Not Found
- Pastikan route sudah terdaftar: `php artisan route:list`
- Cek base URL di `api.ts` sudah benar

### 4. Connection Refused
- Pastikan Laravel server running: `php artisan serve`
- Pastikan React dev server running: `npm run dev`

---

## 📚 Dokumentasi Lengkap

Lihat file:
- `ADMIN_PANEL_SETUP.md` - Setup guide
- `ADMIN_API_DOCS.md` - API documentation

---

**Last Updated:** Jan 2025  
**Version:** 1.0.0
