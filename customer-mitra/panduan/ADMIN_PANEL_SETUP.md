# 🎉 Admin Panel - Laravel Backend Integration

## ✅ Setup Selesai!

Panel **Superadmin** telah berhasil diubah menjadi **Admin Panel** dengan backend **Laravel** (menggantikan Express.js).

---

## 📁 Struktur File yang Dibuat

### 1. Controllers Laravel (`backend/app/Http/Controllers/Admin/`)
```
Admin/
├── AuthController.php          # Login, logout, profile, update profile
├── DashboardController.php     # Dashboard statistics & overview
├── MitraController.php         # Kelola mitra, verifikasi, block/unblock
├── CustomerController.php      # Kelola customer, verifikasi, block/unblock
├── PesananController.php       # Kelola pesanan/booking
├── LaporanController.php       # Kelola laporan & komplain
└── RefundController.php        # Kelola refund requests
```

### 2. Middleware
- `AdminAuthMiddleware.php` - Auth khusus admin (remember_token based)
- Registered di `bootstrap/app.php` sebagai `admin.auth`

### 3. Routes (`backend/routes/api.php`)
Prefix: `/api/admin/` untuk semua endpoint admin

### 4. Frontend (`superadmin/src/services/api.ts`)
Base URL: `http://localhost:8000/api/admin`

### 5. Helper Scripts
- `create_admin.sh` - Buat user admin
- `test_admin_api.sh` - Test API endpoints

---

## 🚀 Cara Menjalankan

### Backend Laravel
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
./create_admin.sh
php artisan serve  # http://localhost:8000
```

### Frontend React
```bash
cd superadmin
npm install
npm run dev  # http://localhost:5173
```

---

## 🔑 Login Credentials

**Email:** `admin@nebeng.com`  
**Password:** `admin123`

---

## 📚 API Documentation Lengkap

Lihat file [ADMIN_API_DOCS.md](./ADMIN_API_DOCS.md) untuk detail lengkap semua endpoint.

---

## 🎯 Fitur Utama

✅ Authentication dengan Bearer Token  
✅ Dashboard dengan statistik real-time  
✅ Manajemen Mitra (CRUD, verify, block/unblock)  
✅ Manajemen Customer (CRUD, verify, block/unblock)  
✅ Manajemen Pesanan (list, detail, statistics)  
✅ Manajemen Laporan (list, resolve, statistics)  
✅ Manajemen Refund (approve, reject, statistics)  
✅ Middleware auth protection  
✅ Error handling & validation  

---

## 📞 Support

Jika ada masalah, cek:
1. `storage/logs/laravel.log` untuk error Laravel
2. Browser console untuk error frontend
3. Network tab untuk debug API calls

---

**Happy Coding!** 🚀
