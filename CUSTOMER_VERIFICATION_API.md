# Customer Verification API Documentation

## Overview
API untuk verifikasi identitas customer menggunakan foto wajah, KTP, atau kombinasi keduanya.

## Base URL
```
http://localhost:8000/api/v1
```

## Authentication
Semua endpoint memerlukan Bearer token di header:
```
Authorization: Bearer {token}
```

## Endpoints

### 1. Get Verification Status
Mendapatkan status verifikasi customer saat ini.

**Endpoint:** `GET /customer/verification/status`

**Response Success:**
```json
{
  "success": true,
  "data": {
    "has_verification": true,
    "status": "pending",
    "verifikasi_wajah": true,
    "verifikasi_ktp": false,
    "verifikasi_wajah_ktp": false,
    "nama_lengkap": "John Doe",
    "nik": "1234567890123456",
    "tanggal_lahir": "1990-01-01",
    "alamat": "Jl. Example No. 123",
    "reviewed_at": null,
    "created_at": "2026-01-19T10:00:00.000000Z",
    "updated_at": "2026-01-19T10:00:00.000000Z"
  }
}
```

### 2. Get Verification Details
Mendapatkan detail lengkap verifikasi customer termasuk URL foto.

**Endpoint:** `GET /customer/verification`

**Response Success:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "nama_lengkap": "John Doe",
    "nik": "1234567890123456",
    "tanggal_lahir": "1990-01-01",
    "alamat": "Jl. Example No. 123",
    "photo_wajah": "http://localhost:8000/storage/verifikasi/wajah/1_1234567890.jpg",
    "photo_ktp": null,
    "photo_ktp_wajah": null,
    "status": "pending",
    "reviewed_at": null,
    "created_at": "2026-01-19T10:00:00.000000Z",
    "updated_at": "2026-01-19T10:00:00.000000Z"
  }
}
```

### 3. Upload Face Photo
Upload foto wajah untuk verifikasi.

**Endpoint:** `POST /customer/verification/upload-face`

**Content-Type:** `multipart/form-data`

**Request Body:**
- `photo` (file, required): File foto wajah (jpeg, png, jpg, max 5MB)

**Response Success:**
```json
{
  "success": true,
  "message": "Foto wajah berhasil diupload",
  "data": {
    "photo_url": "http://localhost:8000/storage/verifikasi/wajah/1_1234567890.jpg",
    "status": "pending"
  }
}
```

### 4. Upload KTP Photo
Upload foto KTP untuk verifikasi.

**Endpoint:** `POST /customer/verification/upload-ktp`

**Content-Type:** `multipart/form-data`

**Request Body:**
- `photo` (file, required): File foto KTP (jpeg, png, jpg, max 5MB)
- `nama_lengkap` (string, required): Nama lengkap sesuai KTP
- `nik` (string, required): NIK 16 digit
- `tanggal_lahir` (date, required): Tanggal lahir format YYYY-MM-DD
- `alamat` (string, required): Alamat lengkap

**Response Success:**
```json
{
  "success": true,
  "message": "Foto KTP berhasil diupload",
  "data": {
    "photo_url": "http://localhost:8000/storage/verifikasi/ktp/1_1234567890.jpg",
    "status": "pending"
  }
}
```

### 5. Upload Face and KTP Photo
Upload foto selfie dengan KTP untuk verifikasi.

**Endpoint:** `POST /customer/verification/upload-face-ktp`

**Content-Type:** `multipart/form-data`

**Request Body:**
- `photo` (file, required): File foto wajah dengan KTP (jpeg, png, jpg, max 5MB)
- `nama_lengkap` (string, required): Nama lengkap sesuai KTP
- `nik` (string, required): NIK 16 digit
- `tanggal_lahir` (date, required): Tanggal lahir format YYYY-MM-DD
- `alamat` (string, required): Alamat lengkap

**Response Success:**
```json
{
  "success": true,
  "message": "Foto wajah dan KTP berhasil diupload",
  "data": {
    "photo_url": "http://localhost:8000/storage/verifikasi/wajah_ktp/1_1234567890.jpg",
    "status": "pending"
  }
}
```

### 6. Submit Verification
Submit verifikasi untuk direview oleh admin.

**Endpoint:** `POST /customer/verification/submit`

**Response Success:**
```json
{
  "success": true,
  "message": "Verifikasi berhasil disubmit. Tunggu proses review dari admin.",
  "data": {
    "status": "pending"
  }
}
```

## Status Types

- `pending`: Menunggu review dari admin
- `approved`: Verifikasi disetujui
- `rejected`: Verifikasi ditolak

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Silakan upload minimal satu dokumen verifikasi."
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Data verifikasi tidak ditemukan."
}
```

### 422 Validation Error
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "photo": ["The photo field is required."],
    "nik": ["The nik must be 16 characters."]
  }
}
```

### 500 Server Error
```json
{
  "success": false,
  "message": "Gagal mengupload foto: Error message"
}
```

## Flutter Integration Example

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../services/verifikasi_service.dart';

// Get verification status
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('auth_token');
final status = await VerifikasiService.getVerificationStatus(token!);

// Upload face photo
final response = await VerifikasiService.uploadFacePhoto(
  token: token,
  photo: File('/path/to/photo.jpg'),
);

// Upload KTP photo
final response = await VerifikasiService.uploadKtpPhoto(
  token: token,
  photo: File('/path/to/ktp.jpg'),
  namaLengkap: 'John Doe',
  nik: '1234567890123456',
  tanggalLahir: '1990-01-01',
  alamat: 'Jl. Example No. 123',
);
```

## Database Schema

Table: `verifikasi_ktp_customers`

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key to users table |
| nama_lengkap | varchar | Nama lengkap sesuai KTP |
| nik | varchar | NIK 16 digit |
| tanggal_lahir | date | Tanggal lahir |
| alamat | text | Alamat lengkap |
| photo_wajah | varchar | Path foto wajah |
| photo_ktp | varchar | Path foto KTP |
| photo_ktp_wajah | varchar | Path foto wajah dengan KTP |
| status | enum | pending, approved, rejected |
| reviewer_id | bigint | ID admin yang review |
| reviewed_at | timestamp | Waktu review |
| meta | json | Metadata tambahan |
| created_at | timestamp | Waktu dibuat |
| updated_at | timestamp | Waktu diupdate |

## Notes

1. Foto akan disimpan di storage dengan path:
   - Face: `storage/verifikasi/wajah/{user_id}_{timestamp}.{ext}`
   - KTP: `storage/verifikasi/ktp/{user_id}_{timestamp}.{ext}`
   - Face+KTP: `storage/verifikasi/wajah_ktp/{user_id}_{timestamp}.{ext}`

2. Maksimal ukuran foto adalah 5MB

3. Format foto yang didukung: jpeg, png, jpg

4. Setiap user hanya bisa memiliki 1 record verifikasi. Update akan mengganti data yang sudah ada.

5. Status default saat upload adalah `pending`.
