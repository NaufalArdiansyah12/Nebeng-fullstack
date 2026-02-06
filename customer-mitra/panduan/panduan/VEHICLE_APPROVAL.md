# Vehicle Approval System

## Overview
Sistem approval kendaraan mitra memungkinkan admin untuk menyetujui atau menolak kendaraan yang didaftarkan oleh mitra.

## Database Schema

Tabel `kendaraan_mitra` memiliki kolom tambahan:
- `status` (enum): pending, approved, rejected - Status approval kendaraan
- `rejection_reason` (text, nullable): Alasan penolakan jika status rejected
- `approved_at` (timestamp, nullable): Waktu approval/rejection
- `approved_by` (foreign key to users, nullable): Admin yang melakukan approval/rejection

## API Endpoints

### 1. Approve Vehicle (Admin Only)
```
POST /api/v1/vehicles/{id}/approve
```

Headers:
```
Authorization: Bearer {admin_token}
Accept: application/json
```

Response Success:
```json
{
  "success": true,
  "message": "Vehicle approved successfully",
  "data": {
    "id": 1,
    "status": "approved",
    "approved_at": "2026-01-30T10:00:00.000000Z",
    "approved_by": 1
  }
}
```

### 2. Reject Vehicle (Admin Only)
```
POST /api/v1/vehicles/{id}/reject
```

Headers:
```
Authorization: Bearer {admin_token}
Accept: application/json
Content-Type: application/json
```

Body:
```json
{
  "rejection_reason": "Dokumen tidak lengkap"
}
```

Response Success:
```json
{
  "success": true,
  "message": "Vehicle rejected",
  "data": {
    "id": 1,
    "status": "rejected",
    "rejection_reason": "Dokumen tidak lengkap",
    "approved_at": "2026-01-30T10:00:00.000000Z",
    "approved_by": 1
  }
}
```

### 3. Get User Vehicles (Mitra)
```
GET /api/v1/vehicles
```

Headers:
```
Authorization: Bearer {mitra_token}
Accept: application/json
```

Response akan include field `status`:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "vehicle_type": "mobil",
      "name": "Avanza Hitam",
      "plate_number": "B 1234 XYZ",
      "status": "pending",
      "rejection_reason": null,
      "approved_at": null
    }
  ]
}
```

## Frontend Display

### Vehicles List Page (Mitra)
Halaman kendaraan mitra akan menampilkan:
- **Badge Status** dengan warna berbeda:
  - 🟠 **Pending** (Orange): "Menunggu Persetujuan"
  - 🟢 **Approved** (Green): "Disetujui"
  - 🔴 **Rejected** (Red): "Ditolak"

- Jika status **rejected**, akan muncul card tambahan yang menampilkan alasan penolakan

### Add Vehicle Success Message
Setelah mitra menambahkan kendaraan, akan muncul notifikasi:
> "Kendaraan berhasil ditambahkan! Menunggu persetujuan admin."

## Workflow

```
Mitra Tambah Kendaraan
    ↓
[Status: Pending]
    ↓
Admin Review
    ↓
    ├─→ Approve → [Status: Approved] ✓
    └─→ Reject → [Status: Rejected] ✗ (dengan alasan)
```

## Testing

### 1. Jalankan Migration
```bash
cd backend
php artisan migrate
```

### 2. Test Create Vehicle (as Mitra)
```bash
curl -X POST http://localhost:8000/api/v1/vehicles \
  -H "Authorization: Bearer {mitra_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "vehicle_type": "mobil",
    "name": "Test Car",
    "plate_number": "B 1234 XYZ",
    "brand": "Toyota",
    "model": "Avanza",
    "color": "Hitam",
    "year": 2020
  }'
```

### 3. Test Approve (as Admin)
```bash
curl -X POST http://localhost:8000/api/v1/vehicles/1/approve \
  -H "Authorization: Bearer {admin_token}" \
  -H "Accept: application/json"
```

### 4. Test Reject (as Admin)
```bash
curl -X POST http://localhost:8000/api/v1/vehicles/1/reject \
  -H "Authorization: Bearer {admin_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "rejection_reason": "Foto plat nomor tidak jelas"
  }'
```

## Notes
- Hanya admin yang bisa approve/reject kendaraan
- Saat kendaraan baru dibuat, default status adalah `pending`
- Mitra dapat melihat status approval dan alasan penolakan di aplikasi
- Kendaraan yang statusnya `rejected` tetap ada di database, tidak dihapus
