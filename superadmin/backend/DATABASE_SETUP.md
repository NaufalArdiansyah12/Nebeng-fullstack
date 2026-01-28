# Setup Database Nebeng-Bro

Database sudah dikonfigurasi untuk terhubung ke `nebeng-bro`. Ikuti langkah-langkah di bawah:

## ✅ Persyaratan
- MySQL Server sudah terinstall dan berjalan
- Database `nebeng-bro` sudah dibuat
- Node.js & npm/bun sudah terinstall

## 🚀 Langkah-Langkah Setup

### 1. Navigasi ke folder backend
```bash
cd backend
```

### 2. Install dependencies
```bash
npm install
# atau
bun install
```

### 3. Inisialisasi Database (Buat tabel & sample data)
```bash
npm run init-db
# atau
bun run init-db
```

Output yang diharapkan:
```
📦 Connecting to MySQL server...
✅ Connected to MySQL server
📄 Reading schema from: ...
🚀 Executing 8 SQL statements...
✅ [1/8] CREATE DATABASE IF NOT EXISTS...
✅ [2/8] CREATE TABLE IF NOT EXISTS users...
... (dan seterusnya)
✅ Database initialization completed successfully!
```

### 4. Test Koneksi Database
```bash
npm run test-db
# atau
bun run test-db
```

Output yang diharapkan:
```
🔍 Testing database connection...
✅ Connected to database successfully!
📊 MySQL Version: 8.0.x
📋 Tables in database "nebeng-bro":
   1. admin
   2. kendaraan_mitra
   3. laporan
   4. pesanan
   5. refund
   6. users
   7. verifikasi_ktp_customers
   8. verifikasi_ktp_mitras
📊 Data Summary:
   users: 3 rows
   ... (dan seterusnya)
✅ All tests passed! Database is ready to use.
```

### 5. Jalankan Backend Server
```bash
npm run dev
# atau
bun run dev
```

Output yang diharapkan:
```
Server is running on port 3001
✅ API Health Check: http://localhost:3001/api/health
```

## 📋 Tabel Database

Database `nebeng-bro` memiliki 8 tabel:

| Tabel | Deskripsi | Foreign Keys |
|-------|-----------|--------------|
| **users** | Data user (admin, mitra, customer) | - |
| **admin** | Profil admin | user_id → users |
| **kendaraan_mitra** | Data kendaraan mitra | mitra_id → users |
| **verifikasi_ktp_mitras** | KTP verification untuk mitra | mitra_id → users |
| **verifikasi_ktp_customers** | KTP verification untuk customer | user_id → users |
| **pesanan** | Order/Pesanan | customer_id, mitra_id → users, kendaraan_id → kendaraan_mitra |
| **laporan** | Laporan/Komplain | pesanan_id → pesanan, customer_id, mitra_id → users |
| **refund** | Refund/Pengembalian dana | pesanan_id → pesanan, customer_id, mitra_id → users |

## 🔌 Konfigurasi Koneksi

File `.env` di folder `backend`:
```
NODE_ENV=development
PORT=3001
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=nebeng-bro
DB_PORT=3306
```

Sesuaikan nilai-nilai di atas dengan konfigurasi MySQL Anda jika berbeda.

## 🐛 Troubleshooting

### Error: "connect ECONNREFUSED"
- Pastikan MySQL Server sudah berjalan
- Check DB_HOST dan DB_PORT di `.env`

### Error: "Unknown database 'nebeng-bro'"
- Buat database manual: `CREATE DATABASE IF NOT EXISTS nebeng-bro;`
- Atau jalankan `npm run init-db` untuk auto-create

### Error: "Access denied for user 'root'@'localhost'"
- Update DB_USER dan DB_PASSWORD di `.env` sesuai dengan MySQL Anda
- Test dengan `npm run test-db`

## 📚 API Endpoints

Setelah server berjalan, akses:
- **Health Check**: `GET http://localhost:3001/api/health`
- **Admin Routes**: `http://localhost:3001/api/admin`
- **Customer Routes**: `http://localhost:3001/api/customers`
- **Mitra Routes**: `http://localhost:3001/api/mitra`
- **Pesanan Routes**: `http://localhost:3001/api/pesanan`
- **Laporan Routes**: `http://localhost:3001/api/laporan`
- **Refund Routes**: `http://localhost:3001/api/refund`
- **Verifikasi Routes**: `http://localhost:3001/api/verifikasi`

---

✅ Setup selesai! Database `nebeng-bro` sudah siap digunakan.
