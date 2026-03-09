# Migrasi API Endpoints - Admin & SuperAdmin

## Overview
Backend Express sekarang menggunakan route grouping untuk memisahkan endpoint Admin dan SuperAdmin dengan prefix yang berbeda.

## Perubahan URL

### ADMIN DASHBOARD (`admin/` folder)

**SEBELUM:**
```
http://localhost:3001/api/auth
http://localhost:3001/api/customers
http://localhost:3001/api/dashboard
http://localhost:3001/api/mitra
http://localhost:3001/api/pesanan
http://localhost:3001/api/laporan
http://localhost:3001/api/refund
http://localhost:3001/api/verifikasi
```

**SESUDAH:**
```
http://localhost:3001/api/admin/auth
http://localhost:3001/api/admin/customers
http://localhost:3001/api/admin/dashboard
http://localhost:3001/api/admin/mitra
http://localhost:3001/api/admin/pesanan
http://localhost:3001/api/admin/laporan
http://localhost:3001/api/admin/refund
http://localhost:3001/api/admin/verifikasi
```

**File Config:** `admin/.env`
```env
VITE_API_URL=http://localhost:3001/api/admin
```

---

### SUPERADMIN DASHBOARD (`superadmin/` folder)

**SEBELUM:**
```
http://localhost:3001/api/auth
http://localhost:3001/api/admin
http://localhost:3001/api/locations
http://localhost:3001/api/posmitra
http://localhost:3001/api/posmitra-users
http://localhost:3001/api/v1/banners
http://localhost:3001/api/reward
http://localhost:3001/api/location-qr-bypass
```

**SESUDAH:**
```
http://localhost:3001/api/superadmin/auth
http://localhost:3001/api/superadmin/admin
http://localhost:3001/api/superadmin/locations
http://localhost:3001/api/superadmin/posmitra
http://localhost:3001/api/superadmin/posmitra-users
http://localhost:3001/api/superadmin/banners
http://localhost:3001/api/superadmin/reward
http://localhost:3001/api/superadmin/location-qr-bypass
```

**File Config:** `superadmin/.env`
```env
VITE_API_URL=http://localhost:3001/api/superadmin
VITE_API_BASE_URL=http://localhost:3001
```

---

### SHARED ENDPOINTS (Mobile App & Both Dashboards)

URL tidak berubah:
```
http://localhost:3001/api/booking/:bookingType/:bookingId/complete-by-driver
```

---

## Setup Steps

### 1. Update Admin Dashboard

```bash
cd admin/

# Copy environment example jika belum ada .env
cp .env.example .env

# Edit .env dan set:
# VITE_API_URL=http://localhost:3001/api/admin

# Restart dev server
npm run dev
```

### 2. Update SuperAdmin Dashboard

```bash
cd superadmin/

# Copy environment example jika belum ada .env
cp .env.example .env

# Edit .env dan set:
# VITE_API_URL=http://localhost:3001/api/superadmin
# VITE_API_BASE_URL=http://localhost:3001

# Restart dev server
npm run dev
```

### 3. Backend Express (Sudah Updated)

Backend sudah dikonfigurasi dengan route grouping. Tidak perlu perubahan manual.

```bash
cd backend-express/
npm run dev
```

---

## Testing

### Test Admin Endpoints
```bash
# Login Admin
curl -X POST http://localhost:3001/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# Get Dashboard Stats
curl http://localhost:3001/api/admin/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test SuperAdmin Endpoints
```bash
# Login SuperAdmin
curl -X POST http://localhost:3001/api/superadmin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"superadmin@example.com","password":"password"}'

# Get QR Bypass Settings
curl http://localhost:3001/api/superadmin/location-qr-bypass \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Shared Endpoints
```bash
# Complete Trip (Mobile App)
curl -X POST http://localhost:3001/api/booking/motor/123/complete-by-driver \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Benefits

1. ✅ **Clear Separation** - Routes terpisah jelas antara Admin dan SuperAdmin
2. ✅ **No Conflicts** - Tidak ada bentrok endpoint karena prefix berbeda
3. ✅ **Easy Debugging** - Mudah trace request dari log berdasarkan prefix
4. ✅ **Scalable** - Mudah tambah middleware khusus per role
5. ✅ **Maintainable** - Struktur code lebih rapi dan mudah dipahami

---

## Troubleshooting

### Error: "Route not found" atau 404
- Pastikan `.env` file di `admin/` dan `superadmin/` sudah diupdate
- Restart dev server frontend setelah update `.env`
- Cek console browser untuk melihat URL yang dipanggil

### Error: CORS
- Backend Express sudah enable CORS untuk semua origin
- Jika masih error, cek konfigurasi CORS di `backend-express/server.ts`

### Token tidak terkirim
- Cek localStorage di browser: `localStorage.getItem('token')`
- Auth token otomatis ditambahkan oleh axios interceptor di `src/services/api.ts`
