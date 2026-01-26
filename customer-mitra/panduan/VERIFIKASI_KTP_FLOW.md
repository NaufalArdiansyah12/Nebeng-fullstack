# Flow Verifikasi KTP Customer

## Alur Lengkap

### 1. Entry Point
- User membuka halaman **Profile**
- Klik menu **"Verifikasi Akun"**

### 2. Intro Page (`verifikasi_intro_page.dart`)
- Menampilkan ilustrasi keamanan
- Penjelasan singkat tentang verifikasi
- Tombol: **Verifikasi** (lanjut), **Kembali** (batal)

### 3. Type Selection (`verifikasi_type_page.dart`)
- Pilih tipe verifikasi:
  - **Verifikasi Wajah** → ke `verifikasi_upload_page.dart`
  - **Verifikasi e-KTP** → ke `verifikasi_form_page.dart`
  - **Verifikasi Wajah & e-KTP** → ke `verifikasi_form_page.dart`

### 4A. Verifikasi Wajah Saja
**Upload Page** (`verifikasi_upload_page.dart`)
- Panduan foto wajah
- Ambil foto via kamera/galeri
- Upload ke endpoint: `POST /api/v1/customer/verification/upload-face-photo`
- Success → `verifikasi_success_page.dart`

### 4B. Verifikasi KTP / Wajah+KTP
**Form Page** (`verifikasi_form_page.dart`)
- Input data KTP:
  - NIK (16 digit, hanya angka)
  - Nama Lengkap
  - Jenis Kelamin (dropdown: Laki-laki/Perempuan)
  - Tanggal Lahir (date picker, format dd/mm/yyyy)
- Validasi form
- Tombol: **Berikutnya** (lanjut), **Kembali** (batal)
- Data dikirim ke → `verifikasi_ktp_upload_page.dart`

**KTP Upload Page** (`verifikasi_ktp_upload_page.dart`)
- Tampilkan sample mockup KTP
- Panduan upload:
  - ✅ Foto jelas dan tidak blur
  - ✅ Seluruh bagian KTP terlihat
  - ✅ Pencahayaan cukup
  - ❌ Foto terpotong atau blur
  - ❌ Foto terlalu gelap
  - ❌ KTP tertutup jari
- Modal bottom sheet untuk pilih sumber:
  - **Ambil Foto** (kamera)
  - **Pilih dari Galeri**
- Preview foto yang dipilih
- Upload ke endpoint:
  - KTP only: `POST /api/v1/customer/verification/upload-ktp-photo`
  - Face+KTP: `POST /api/v1/customer/verification/upload-face-ktp-photo`
- Success → `verifikasi_success_page.dart`

### 5. Success Page (`verifikasi_success_page.dart`)
- Animasi checkmark hijau
- Pesan sukses
- Tombol: **Lihat Status** → `verifikasi_status_page.dart`

### 6. Status Page (`verifikasi_status_page.dart`)
- Menampilkan status verifikasi:
  - **Pending** (kuning) - Sedang direview
  - **Verified** (hijau) - Disetujui
  - **Rejected** (merah) - Ditolak
- Data verifikasi yang disubmit
- Tombol: **Kembali ke Profile**

## API Endpoints

### 1. Get Status
```
GET /api/v1/customer/verification/status
Authorization: Bearer {token}
```

### 2. Upload Face Photo
```
POST /api/v1/customer/verification/upload-face-photo
Authorization: Bearer {token}
Content-Type: multipart/form-data

photo: File
```

### 3. Upload KTP Photo
```
POST /api/v1/customer/verification/upload-ktp-photo
Authorization: Bearer {token}
Content-Type: multipart/form-data

photo: File
nama_lengkap: String
nik: String (16 digit)
tanggal_lahir: String (yyyy-mm-dd)
alamat: String
```

### 4. Upload Face+KTP Photo
```
POST /api/v1/customer/verification/upload-face-ktp-photo
Authorization: Bearer {token}
Content-Type: multipart/form-data

photo: File (foto wajah dengan KTP)
nama_lengkap: String
nik: String (16 digit)
tanggal_lahir: String (yyyy-mm-dd)
alamat: String
```

### 5. Get Verification Details
```
GET /api/v1/customer/verification/detail
Authorization: Bearer {token}
```

## Database Schema

**Table: verifikasi_ktp_customers**

| Field | Type | Description |
|-------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key ke users |
| nama_lengkap | string | Nama sesuai KTP |
| nik | string(16) | Nomor Induk Kependudukan |
| tanggal_lahir | date | Tanggal lahir |
| alamat | text | Alamat sesuai KTP |
| photo_wajah | string | Path foto wajah |
| photo_ktp | string | Path foto KTP |
| photo_ktp_wajah | string | Path foto wajah+KTP |
| status | enum | pending/verified/rejected |
| reviewer_id | bigint | Admin yang review (nullable) |
| reviewed_at | timestamp | Waktu review (nullable) |
| meta | json | Data tambahan (nullable) |

## Validasi

### Form Validation
- **NIK**: Wajib, 16 digit angka
- **Nama Lengkap**: Wajib, minimal 3 karakter
- **Jenis Kelamin**: Wajib pilih
- **Tanggal Lahir**: Wajib pilih

### Image Validation
- **Format**: JPEG, PNG, JPG
- **Max Size**: 5MB
- **Requirement**: Jelas, tidak blur, pencahayaan cukup

## Authentication
- Menggunakan **custom ApiToken** (bukan Laravel Sanctum)
- Token disimpan di SharedPreferences dengan key: `api_token`
- Header: `Authorization: Bearer {token}`
- Backend: Lookup token dengan SHA256 hash di table `api_tokens`

## File Storage
- Base path: `storage/verifikasi/`
- Wajah: `storage/verifikasi/wajah/{user_id}_{timestamp}.{ext}`
- KTP: `storage/verifikasi/ktp/{user_id}_{timestamp}.{ext}`
- Wajah+KTP: `storage/verifikasi/wajah_ktp/{user_id}_{timestamp}.{ext}`

## UI Design References
Flow ini dibuat sesuai dengan mockup gambar yang disediakan:
1. Halaman form data KTP (NIK, Nama, Jenis Kelamin, Tanggal Lahir)
2. Halaman panduan upload dengan sample KTP dan checklist
3. Modal bottom sheet untuk pilih sumber foto (Kamera/Galeri)
