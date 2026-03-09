# QR Bypass Feature - Express Backend Implementation

## Overview
Fitur QR Bypass sekarang menggunakan Express.js backend untuk SuperAdmin panel, bukan Laravel. Ini mengikuti arsitektur yang sudah ada dimana semua halaman admin menggunakan backend Express.

## Endpoints yang Diimplementasikan

### Express Backend (Port 3001)

#### 1. SuperAdmin - Manage QR Bypass Settings
```
GET /api/location-qr-bypass
```
- Mengambil semua lokasi dengan status bypass-nya
- Response:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Terminal Bungurasih",
      "city": "Surabaya",
      "address": "Jl. Raya Bungurasih",
      "qr_bypass_enabled": false,
      "notes": null
    }
  ]
}
```

```
PUT /api/location-qr-bypass/:locationId
```
- Update setting bypass untuk wilayah tertentu
- Body:
```json
{
  "qr_bypass_enabled": true,
  "notes": "Tidak ada petugas PosMitra di wilayah ini"
}
```
- Response:
```json
{
  "success": true,
  "message": "QR bypass setting updated successfully",
  "data": {
    "location_id": 1,
    "qr_bypass_enabled": true,
    "notes": "Tidak ada petugas PosMitra di wilayah ini"
  }
}
```

#### 2. Mitra - Check Bypass Status
```
GET /api/location-qr-bypass/:locationId/check
```
- Cek apakah wilayah tertentu memiliki bypass enabled
- Response:
```json
{
  "success": true,
  "data": {
    "location_id": 1,
    "location_name": "Terminal Bungurasih",
    "qr_bypass_enabled": true
  }
}
```

#### 3. Mitra - Complete Trip By Driver
```
POST /api/booking/:bookingType/:bookingId/complete-by-driver
```
- bookingType: `motor`, `mobil`, `barang`, `titip-barang`
- Menyelesaikan tebengan tanpa scan QR
- Validasi: hanya bisa digunakan jika status = "sudah_sampai_tujuan"
- Response:
```json
{
  "success": true,
  "message": "Trip completed successfully",
  "data": {
    "booking_id": 123,
    "status": "selesai",
    "completed_at": "2026-03-05T10:30:00.000Z"
  }
}
```

## Files yang Dibuat/Dimodifikasi

### Backend Express (admin/backend/)

#### New Files:
1. **src/routes/qr-bypass.routes.ts**
   - Route untuk manage QR bypass settings
   - GET untuk list locations
   - PUT untuk update bypass setting
   - GET check untuk mitra app

2. **src/routes/booking.routes.ts**
   - Route untuk complete trip by driver
   - POST endpoint dengan validasi status

#### Modified Files:
1. **server.ts**
   - Import route baru: `qrBypassRoutes`, `bookingRoutes`
   - Register routes:
     - `app.use('/api/location-qr-bypass', qrBypassRoutes)`
     - `app.use('/api/booking', bookingRoutes)`

### Frontend SuperAdmin (superadmin/src/)

#### Modified Files:
1. **pages/QRBypassSettings.tsx**
   - Update API_BASE_URL default: `http://localhost:3001` (Express)
   - Update endpoint URLs:
     - `GET /api/location-qr-bypass`
     - `PUT /api/location-qr-bypass/:locationId`

### Mobile App (customer-mitra/frontend/)

#### Modified Files:
1. **lib/screens/mitra/mitra_tracking_map/widgets/qr_only_screen.dart**
   - Update API_BASE_URL default: `http://10.0.2.2:3001` (Express)
   - Update endpoints:
     - Check bypass: `GET /api/location-qr-bypass/:locationId/check`
     - Complete trip: `POST /api/booking/:type/:id/complete-by-driver`

## Database

Tabel `location_qr_bypass_settings` sudah dibuat via Laravel migration:
```sql
CREATE TABLE location_qr_bypass_settings (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  location_id BIGINT UNSIGNED NOT NULL,
  qr_bypass_enabled BOOLEAN DEFAULT FALSE,
  notes TEXT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  UNIQUE KEY (location_id),
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);
```

Migration file: `backend/database/migrations/2026_03_05_021250_create_location_qr_bypass_settings_table.php`

## Setup & Run

### 1. Pastikan database migration sudah dijalankan
```bash
cd backend
php artisan migrate
```

### 2. Jalankan Express Backend
```bash
cd admin/backend
npm install
npm run dev  # atau: bun run dev
```

Server akan berjalan di: http://localhost:3001

### 3. Jalankan SuperAdmin Frontend
```bash
cd superadmin
npm install
npm run dev
```

### 4. Set Environment Variables

**SuperAdmin (.env):**
```env
VITE_API_BASE_URL=http://localhost:3001
```

**Flutter App:**
```dart
// Gunakan --dart-define saat build/run
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
```

## Testing

1. **SuperAdmin Panel:**
   - Buka: http://localhost:5173/dashboard/qr-bypass-settings
   - Toggle ON untuk satu wilayah
   - Tambahkan catatan
   - Verifikasi data tersimpan

2. **Mitra App:**
   - Buat tebengan dengan tujuan ke wilayah yang sudah di-enable bypass
   - Saat sampai tujuan, verifikasi muncul button "Selesaikan Tebengan"
   - Klik button dan pastikan status berubah menjadi "selesai"

3. **API Testing (Postman/Thunder Client):**
   ```bash
   # Get all locations with bypass settings
   GET http://localhost:3001/api/location-qr-bypass
   
   # Update bypass setting
   PUT http://localhost:3001/api/location-qr-bypass/1
   Body: {
     "qr_bypass_enabled": true,
     "notes": "Test notes"
   }
   
   # Check bypass status (for mitra)
   GET http://localhost:3001/api/location-qr-bypass/1/check
   
   # Complete trip by driver
   POST http://localhost:3001/api/booking/motor/123/complete-by-driver
   ```

## Keuntungan Menggunakan Express

1. ✅ **Konsisten dengan Arsitektur:** Semua admin panel sudah menggunakan Express
2. ✅ **TypeScript:** Type safety untuk development
3. ✅ **Single Backend:** Tidak perlu maintain dua backend berbeda untuk admin panel
4. ✅ **Mudah Deploy:** Express backend sudah ada infrastruktur deploy-nya

## Migration dari Laravel ke Express

Jika sebelumnya menggunakan Laravel endpoints, berikut mapping-nya:

| Laravel Endpoint | Express Endpoint |
|-----------------|------------------|
| `GET /api/v1/superadmin/location-qr-bypass` | `GET /api/location-qr-bypass` |
| `PUT /api/v1/superadmin/location-qr-bypass/:id` | `PUT /api/location-qr-bypass/:id` |
| `GET /api/v1/mitra/location/:id/bypass` | `GET /api/location-qr-bypass/:id/check` |
| `POST /api/v1/booking/:type/:id/complete-by-driver` | `POST /api/booking/:type/:id/complete-by-driver` |

## Notes

- Port Express: **3001** (default)
- Port Laravel: **8000** (masih digunakan untuk API lainnya)
- Database: **Shared** (MySQL - nebeng-bro)
- Migration: Tetap menggunakan Laravel migration untuk create tables
