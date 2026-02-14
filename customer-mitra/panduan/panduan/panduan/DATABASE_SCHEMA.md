# 🗄️ Database Schema Documentation

## Overview
Full MySQL database schema untuk Nebeng Admin aplikasi dengan semua tables, relationships, dan constraints.

## Tables

### 1. `admin` - Admin Users
Menyimpan profil admin aplikasi.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| nama_lengkap | VARCHAR(255) | Nama lengkap admin |
| email | VARCHAR(255) | Email unik |
| password | VARCHAR(255) | Password (hashed) |
| tempat_lahir | VARCHAR(100) | Tempat lahir |
| tanggal_lahir | DATE | Tanggal lahir |
| jenis_kelamin | ENUM | Laki-Laki / Perempuan |
| no_tlp | VARCHAR(20) | Nomor telepon |
| role | VARCHAR(50) | Role (default: Admin) |
| layanan | VARCHAR(100) | Layanan yang diatur |
| foto | LONGTEXT | Foto profil (base64) |
| created_at | TIMESTAMP | Waktu dibuat |
| updated_at | TIMESTAMP | Waktu diupdate |

### 2. `customer` - Customers
Menyimpan data customer yang mendaftar.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| kode | VARCHAR(50) | Kode unik customer (CST001) |
| nama | VARCHAR(255) | Nama |
| email | VARCHAR(255) | Email |
| no_tlp | VARCHAR(20) | Nomor telepon |
| status | ENUM | PENGAJUAN / TERVERIFIKASI / DITOLAK / DIBLOCK |
| tanggal_daftar | TIMESTAMP | Waktu pendaftaran |
| nama_lengkap | VARCHAR(255) | Nama lengkap |
| tempat_lahir | VARCHAR(100) | Tempat lahir |
| tanggal_lahir | DATE | Tanggal lahir |
| jenis_kelamin | ENUM | Laki-Laki / Perempuan |
| nik | VARCHAR(20) | NIK (KTP) |
| alamat | TEXT | Alamat lengkap |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

### 3. `mitra` - Drivers/Partners
Menyimpan data mitra/driver aplikasi.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| kode | VARCHAR(50) | Kode unik (MTR001) |
| nama | VARCHAR(255) | Nama |
| email | VARCHAR(255) | Email |
| no_tlp | VARCHAR(20) | Nomor telepon |
| layanan | ENUM | Motor / Mobil / Titip Barang / Barang |
| status | ENUM | PENGAJUAN / TERVERIFIKASI / DITOLAK / DIBLOCK |
| tanggal_daftar | TIMESTAMP | Waktu pendaftaran |
| nama_lengkap | VARCHAR(255) | Nama lengkap |
| tempat_lahir | VARCHAR(100) | Tempat lahir |
| tanggal_lahir | DATE | Tanggal lahir |
| jenis_kelamin | ENUM | Laki-Laki / Perempuan |
| nik | VARCHAR(20) | NIK (KTP) |
| foto_ktp | LONGTEXT | Foto KTP |
| no_sim | VARCHAR(50) | Nomor SIM |
| foto_sim | LONGTEXT | Foto SIM |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

### 4. `kendaraan_mitra` - Driver Vehicles
Menyimpan data kendaraan milik mitra.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| mitra_id | INT | Foreign key ke mitra |
| jenis_kendaraan | VARCHAR(50) | Motor / Mobil |
| merk_kendaraan | VARCHAR(100) | Merk (Honda, Toyota, dll) |
| plat_nomor | VARCHAR(20) | Plat nomor unik |
| tahun_pembuatan | INT | Tahun pembuatan |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

### 5. `pesanan` - Orders
Menyimpan data pesanan/order dari customer.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| no_order | VARCHAR(50) | Nomor order unik |
| customer_id | INT | FK ke customer |
| mitra_id | INT | FK ke mitra |
| layanan | VARCHAR(100) | Jenis layanan |
| status | ENUM | PROSES / SELESAI / BATAL |
| harga | DECIMAL(10,2) | Harga layanan |
| catatan_customer | TEXT | Catatan dari customer |
| tanggal_pesanan | TIMESTAMP | Waktu pesanan |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

### 6. `perjalanan` - Trip Details
Menyimpan detail perjalanan untuk setiap pesanan.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| pesanan_id | INT | FK ke pesanan |
| tanggal_perjalanan | DATE | Tanggal perjalanan |
| jarak | VARCHAR(50) | Jarak perjalanan |
| durasi | VARCHAR(50) | Durasi perjalanan |
| titik_jemput_lokasi | VARCHAR(255) | Lokasi penjemputan |
| titik_jemput_waktu | TIME | Waktu penjemputan |
| titik_jemput_alamat | TEXT | Alamat penjemputan |
| tujuan_lokasi | VARCHAR(255) | Lokasi tujuan |
| tujuan_waktu | TIME | Waktu tiba |
| tujuan_alamat | TEXT | Alamat tujuan |
| created_at | TIMESTAMP | Dibuat |

### 7. `pembayaran` - Payments
Menyimpan data pembayaran untuk pesanan.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| pesanan_id | INT | FK ke pesanan |
| tipe_pembayaran | VARCHAR(50) | Tipe pembayaran |
| no_transaksi | VARCHAR(100) | Nomor transaksi unik |
| biaya_penumpang | DECIMAL(10,2) | Biaya penumpang |
| biaya_admin | DECIMAL(10,2) | Biaya admin |
| total | DECIMAL(10,2) | Total pembayaran |
| tanggal_pembayaran | TIMESTAMP | Waktu pembayaran |
| created_at | TIMESTAMP | Dibuat |

### 8. `laporan` - Reports
Menyimpan laporan/komplain dari customer.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| pesanan_id | INT | FK ke pesanan |
| customer_id | INT | FK ke customer |
| mitra_id | INT | FK ke mitra |
| deskripsi_laporan | TEXT | Deskripsi laporan |
| status | ENUM | BARU / DIPROSES / SELESAI |
| tanggal_laporan | TIMESTAMP | Waktu laporan |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

### 9. `refund` - Refunds
Menyimpan data refund/pengembalian dana.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| pesanan_id | INT | FK ke pesanan |
| no_order | VARCHAR(50) | Nomor order |
| no_transaksi | VARCHAR(100) | Nomor transaksi refund |
| jumlah_refund | DECIMAL(10,2) | Jumlah refund |
| metode_refund | VARCHAR(100) | Metode refund |
| status | ENUM | PROSES / SELESAI / BATAL |
| tanggal_refund | TIMESTAMP | Waktu refund |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

### 10. `pengaturan` - Settings
Menyimpan pengaturan aplikasi.

| Column | Type | Description |
|--------|------|-------------|
| id | INT | Primary key |
| admin_id | INT | FK ke admin |
| kunci_setting | VARCHAR(100) | Kunci setting (config key) |
| nilai_setting | LONGTEXT | Nilai setting |
| created_at | TIMESTAMP | Dibuat |
| updated_at | TIMESTAMP | Diupdate |

## Relationships (Foreign Keys)

```
customer (1) -------- (*) pesanan
mitra (1) -------- (*) pesanan
pesanan (1) -------- (*) perjalanan
pesanan (1) -------- (*) pembayaran
pesanan (1) -------- (*) laporan
pesanan (1) -------- (*) refund
mitra (1) -------- (*) kendaraan_mitra
customer (1) -------- (*) laporan
mitra (1) -------- (*) laporan
admin (1) -------- (*) pengaturan
```

## Indexes

Primary keys dan indexes sudah dioptimasi untuk query performance:
- Email fields indexed (fast lookup)
- Status fields indexed (filtering)
- Foreign keys indexed (joins)
- Kode fields indexed (unique lookup)

## Sample Data

Database sudah include:
- **1 Admin** - Muhammad Abdul Kadir (Abdul000@gmail.com)
- **3 Customers** - Berbagai status (PENGAJUAN, TERVERIFIKASI, DITOLAK)
- **3 Mitra** - Berbagai layanan (Motor, Mobil, Titip Barang)
- **Kendaraan** - 2 vehicles untuk testing

## Charset & Collation

- **Charset**: utf8mb4 (Unicode support)
- **Collation**: utf8mb4_unicode_ci (Case-insensitive)
- Mendukung karakter Indonesia dan special characters

## Constraints

- **UNIQUE**: email, kode, nik (customer), no_sim, no_order, no_transaksi
- **NOT NULL**: Required fields untuk setiap table
- **ENUM**: Predefined values untuk status fields
- **CASCADE**: Foreign keys dengan ON DELETE CASCADE
- **TIMESTAMP**: Auto-created & updated timestamps

## Queries Umum

### Get all customers dengan orders
```sql
SELECT c.*, COUNT(p.id) as total_orders
FROM customer c
LEFT JOIN pesanan p ON c.id = p.customer_id
GROUP BY c.id;
```

### Get mitra dengan vehicle count
```sql
SELECT m.*, COUNT(k.id) as vehicle_count
FROM mitra m
LEFT JOIN kendaraan_mitra k ON m.id = k.mitra_id
GROUP BY m.id;
```

### Get recent orders dengan customer dan mitra
```sql
SELECT p.*, c.nama as customer_name, m.nama as mitra_name
FROM pesanan p
JOIN customer c ON p.customer_id = c.id
JOIN mitra m ON p.mitra_id = m.id
ORDER BY p.tanggal_pesanan DESC
LIMIT 10;
```

### Get laporan yang belum selesai
```sql
SELECT l.*, c.nama, m.nama
FROM laporan l
JOIN customer c ON l.customer_id = c.id
JOIN mitra m ON l.mitra_id = m.id
WHERE l.status != 'SELESAI'
ORDER BY l.tanggal_laporan DESC;
```
