# Storage Foto Verifikasi KTP

## Lokasi Penyimpanan

Foto-foto verifikasi disimpan di Laravel storage dengan struktur sebagai berikut:

### 1. Foto Wajah
- **Path**: `storage/app/public/verifikasi/wajah/`
- **Format nama**: `{user_id}_{timestamp}.{extension}`
- **Contoh**: `storage/app/public/verifikasi/wajah/1_1705661234.jpg`

### 2. Foto KTP
- **Path**: `storage/app/public/verifikasi/ktp/`
- **Format nama**: `{user_id}_{timestamp}.{extension}`
- **Contoh**: `storage/app/public/verifikasi/ktp/1_1705661234.jpg`

### 3. Foto Wajah + KTP
- **Path**: `storage/app/public/verifikasi/wajah_ktp/`
- **Format nama**: `{user_id}_{timestamp}.{extension}`
- **Contoh**: `storage/app/public/verifikasi/wajah_ktp/1_1705661234.jpg`

## Akses Foto

### Symbolic Link
Untuk mengakses foto dari browser, pastikan symbolic link sudah dibuat:

```bash
cd backend
php artisan storage:link
```

Ini akan membuat symbolic link dari `storage/app/public` ke `public/storage`.

### URL Akses
Setelah symbolic link dibuat, foto bisa diakses via:
```
http://localhost:8000/storage/verifikasi/ktp/{user_id}_{timestamp}.jpg
```

## Database Status

### Status Enum
Status verifikasi menggunakan enum dengan 3 nilai:
- **pending**: Menunggu review admin
- **approved**: Disetujui admin
- **rejected**: Ditolak admin

### Mapping Frontend-Backend
```
Database (Backend) → Frontend
---------------------------------
approved           → verified
pending            → pending
rejected           → rejected
null/tidak ada     → not_verified
```

### Field Database
Table: `verifikasi_ktp_customers`

| Field | Type | Description |
|-------|------|-------------|
| photo_wajah | string | Path foto wajah |
| photo_ktp | string | Path foto KTP |
| photo_ktp_wajah | string | Path foto wajah+KTP |
| status | enum | pending/approved/rejected |
| reviewer_id | bigint | ID admin yang review |
| reviewed_at | timestamp | Waktu review |

## Validasi Upload

### Ukuran & Format
- **Max size**: 5MB (5120 KB)
- **Format**: JPEG, PNG, JPG
- **Validasi**: Di backend menggunakan Laravel validation

### Penanganan File Lama
Saat user upload foto baru:
1. Foto lama di storage akan dihapus otomatis
2. Foto baru disimpan dengan timestamp baru
3. Database diupdate dengan path foto baru

## Keamanan

### 1. Authentication
- Semua endpoint verifikasi memerlukan Bearer token
- Token di-hash dengan SHA256 sebelum lookup di database

### 2. Authorization
- User hanya bisa upload/view data verifikasi miliknya sendiri
- Cek ownership: `getUserFromToken()` method

### 3. Storage Permission
Pastikan direktori storage memiliki permission yang benar:
```bash
chmod -R 775 storage
chmod -R 775 bootstrap/cache
```

## Troubleshooting

### Foto tidak bisa diakses
1. Cek apakah symbolic link sudah dibuat: `php artisan storage:link`
2. Cek permission folder storage: `chmod -R 775 storage`
3. Cek apakah file benar-benar ada di `storage/app/public/verifikasi/`

### Status tidak update di frontend
1. Cek database: pastikan status adalah `approved` (bukan `verified`)
2. Clear cache aplikasi dan reload
3. Cek response API: `GET /api/v1/customer/verification`

### Upload gagal
1. Cek ukuran file (max 5MB)
2. Cek format file (harus jpeg/png/jpg)
3. Cek permission folder storage
4. Cek log Laravel: `storage/logs/laravel.log`
