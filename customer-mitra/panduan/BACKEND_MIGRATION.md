# 🔄 Migrasi Backend: Express → Laravel

## 📋 Ringkasan Perubahan

Admin Panel Nebeng telah berhasil dimigrasi dari **Express.js backend** ke **Laravel backend** yang sudah ada di project ini.

### ✅ Status: SELESAI

---

## 🎯 Alasan Migrasi

1. **Konsolidasi Backend**: Menggunakan satu backend (Laravel) untuk semua aplikasi
2. **Menghilangkan Duplikasi**: Tidak perlu maintain 2 backend terpisah
3. **Konsistensi Data**: Semua data admin, customer, dan mitra di satu database
4. **Efisiensi Development**: Tim hanya perlu fokus pada 1 teknologi backend

---

## 📂 Struktur Backend Laravel

### Admin API Endpoints

Semua endpoint admin sekarang menggunakan prefix `/api/admin`:

#### 🔐 Authentication
- `POST /api/admin/auth/login` - Login admin
- `POST /api/admin/auth/logout` - Logout admin
- `GET /api/admin/auth/verify` - Verify token
- `GET /api/admin/auth/profile` - Get admin profile
- `PUT /api/admin/auth/profile` - Update admin profile

#### 📊 Dashboard
- `GET /api/admin/dashboard?month=2&year=2026` - Get statistics

#### 👥 Customer Management
- `GET /api/admin/customers` - List all customers
- `GET /api/admin/customers/pending-verification` - Pending verifications
- `GET /api/admin/customers/blocked` - Blocked customers
- `GET /api/admin/customers/{id}` - Customer detail
- `POST /api/admin/customers/{id}/verify` - Verify customer
- `POST /api/admin/customers/{id}/block` - Block customer
- `POST /api/admin/customers/{id}/unblock` - Unblock customer

#### 🚗 Mitra Management
- `GET /api/admin/mitra` - List all mitra
- `GET /api/admin/mitra/{id}` - Mitra detail
- `POST /api/admin/mitra/{id}/verify` - Verify mitra
- `POST /api/admin/mitra/{id}/reject` - Reject mitra
- `POST /api/admin/mitra/{id}/block` - Block mitra
- `POST /api/admin/mitra/{id}/unblock` - Unblock mitra
- `GET /api/admin/mitra/{id}/vehicles` - Get mitra vehicles

#### 🚙 Vehicles Management
- `GET /api/admin/vehicles` - List all vehicles
- `GET /api/admin/vehicles/{id}` - Vehicle detail

#### 📦 Pesanan/Booking Management
- `GET /api/admin/pesanan` - List all orders
- `GET /api/admin/pesanan/statistics` - Order statistics
- `GET /api/admin/pesanan/{id}` - Order detail

#### 📢 Laporan Management
- `GET /api/admin/laporan` - List all reports
- `GET /api/admin/laporan/statistics` - Report statistics
- `GET /api/admin/laporan/{id}` - Report detail
- `POST /api/admin/laporan` - Create report
- `PUT /api/admin/laporan/{id}/status` - Update status
- `POST /api/admin/laporan/{id}/resolve` - Resolve report

#### 💰 Refund Management
- `GET /api/admin/refund` - List all refunds
- `GET /api/admin/refund/statistics` - Refund statistics
- `GET /api/admin/refund/{id}` - Refund detail
- `POST /api/admin/refund/{id}/approve` - Approve refund
- `POST /api/admin/refund/{id}/reject` - Reject refund
- `PUT /api/admin/refund/{id}/status` - Update status

---

## 🛠️ Setup & Konfigurasi

### 1. Backend (Laravel)

#### Start Laravel Backend

```bash
cd backend
php artisan serve
```

Laravel akan berjalan di `http://localhost:8000`

#### Middleware

Admin routes dilindungi dengan middleware `admin.auth` yang:
- Memeriksa Bearer token
- Validasi token di table `api_tokens`
- Memastikan user memiliki role `admin`
- Memastikan status user `active`

File: `backend/app/Http/Middleware/AdminAuthMiddleware.php`

#### Controllers

Semua controller admin ada di:
```
backend/app/Http/Controllers/Admin/
├── AuthController.php
├── DashboardController.php
├── CustomerController.php
├── MitraController.php
├── PesananController.php
├── LaporanController.php
├── RefundController.php
└── UserManagementController.php
```

#### Routes

Admin routes didefinisikan di `backend/routes/api.php`:

```php
Route::prefix('api/admin')->group(function () {
    // Public routes
    Route::post('/auth/login', [AdminAuthController::class, 'login']);
    
    // Protected routes (require admin.auth middleware)
    Route::middleware('admin.auth')->group(function () {
        // ... all protected admin routes
    });
});
```

### 2. Frontend (Admin Panel)

#### Environment Variables

File: `admin/.env`

```env
VITE_API_URL=http://localhost:8000/api/admin
```

#### API Service

File: `admin/src/services/api.ts`

Service ini sudah dikonfigurasi untuk:
- Connect ke Laravel backend
- Auto-attach Bearer token dari localStorage
- Handle error responses (401, 403, 404, 500)
- Export API functions yang ready to use

```typescript
import { adminApi, dashboardApi, customerApi, mitraApi, 
         pesananApi, laporanApi, refundApi } from '@/services/api';

// Login
const response = await adminApi.login(email, password);
localStorage.setItem('token', response.data.token);

// Get dashboard stats
const stats = await dashboardApi.getStatistics(month, year);

// Get customers
const customers = await customerApi.getAll({ status: 'verified' });

// Block customer
await customerApi.block(customerId, 'Reason for blocking');
```

#### Start Admin Frontend

```bash
cd admin
npm install  # atau bun install
npm run dev  # atau bun run dev
```

Admin panel akan berjalan di `http://localhost:5173`

---

## 🔑 Authentication Flow

### 1. Login

**Request:**
```http
POST /api/admin/auth/login
Content-Type: application/json

{
  "email": "admin@nebeng.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login berhasil",
  "token": "random_60_char_token",
  "user": {
    "id": 1,
    "name": "Admin Name",
    "email": "admin@nebeng.com",
    "role": "admin"
  }
}
```

Frontend menyimpan token di localStorage:
```typescript
localStorage.setItem('token', response.data.token);
localStorage.setItem('user', JSON.stringify(response.data.user));
```

### 2. Authenticated Requests

Setiap request berikutnya akan include token di header:

```http
GET /api/admin/dashboard
Authorization: Bearer random_60_char_token
```

### 3. Logout

```http
POST /api/admin/auth/logout
Authorization: Bearer random_60_char_token
```

Token akan dihapus dari database dan localStorage.

---

## 📊 Response Format

Semua Laravel API response menggunakan format konsisten:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "pagination": {  // optional untuk list endpoints
    "current_page": 1,
    "per_page": 10,
    "total": 50,
    "last_page": 5
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errors": {  // optional untuk validation errors
    "field": ["Error detail"]
  }
}
```

---

## 🗑️ Express Backend Sudah Dihapus

Express backend yang sebelumnya ada di `admin/backend/` sudah **DIHAPUS**.

✅ Semua functionality sudah ada di Laravel backend di `backend/`.

---

## 🔐 Default Admin Account

Untuk login pertama kali, gunakan akun default admin:

```
Email: admin@nebeng.com
Password: password123
```

⚠️ **PENTING**: Segera ganti password setelah login pertama!

Untuk membuat admin baru atau reset password, gunakan:

```bash
cd backend
php artisan tinker

# Buat admin baru
$user = new App\Models\User();
$user->name = 'Admin Name';
$user->email = 'admin@example.com';
$user->password = bcrypt('password123');
$user->role = 'admin';
$user->status = 'active';
$user->save();

# Reset password admin
$user = App\Models\User::where('email', 'admin@nebeng.com')->first();
$user->password = bcrypt('newpassword123');
$user->save();
```

---

## 🧪 Testing

### 1. Test Login

```bash
curl -X POST http://localhost:8000/api/admin/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nebeng.com","password":"password123"}'
```

### 2. Test Dashboard (with token)

```bash
curl -X GET http://localhost:8000/api/admin/dashboard \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 3. Test dari Browser

1. Start Laravel backend: `php artisan serve`
2. Start admin frontend: `cd admin && npm run dev`
3. Buka browser: `http://localhost:5173`
4. Login dengan kredensial admin
5. Cek dashboard, customer list, mitra list, dll

---

## 🐛 Troubleshooting

### Problem: 401 Unauthorized

**Penyebab:**
- Token tidak ada atau invalid
- Token sudah expired (> 30 hari)
- User bukan admin atau status tidak active

**Solusi:**
- Logout dan login kembali
- Clear localStorage dan login ulang
- Cek token di database: `select * from api_tokens`

### Problem: CORS Error

**Penyebab:**
- Laravel CORS config tidak allow origin frontend

**Solusi:**

Edit `backend/config/cors.php`:

```php
'allowed_origins' => ['http://localhost:5173'],
```

### Problem: 500 Internal Server Error

**Penyebab:**
- Error di Laravel controller
- Database connection issue

**Solusi:**
- Cek Laravel logs: `backend/storage/logs/laravel.log`
- Cek database connection di `.env`
- Run migrations: `php artisan migrate`

---

## ✅ Checklist Verifikasi

Pastikan semua ini sudah berfungsi:

- [ ] Login admin berhasil
- [ ] Dashboard menampilkan statistik
- [ ] Customer list dapat diload
- [ ] Customer detail dapat dilihat
- [ ] Customer dapat di-block/unblock
- [ ] Mitra list dapat diload
- [ ] Mitra detail dapat dilihat
- [ ] Mitra dapat di-verify/reject/block/unblock
- [ ] Pesanan list dapat diload
- [ ] Laporan list dapat diload
- [ ] Refund list dapat diload
- [ ] Logout berhasil
- [ ] Token expired handling bekerja (redirect to login)

---

## 📚 Resources

- **Laravel Docs**: https://laravel.com/docs
- **API Routes**: `backend/routes/api.php`
- **Admin Controllers**: `backend/app/Http/Controllers/Admin/`
- **Admin Middleware**: `backend/app/Http/Middleware/AdminAuthMiddleware.php`
- **Frontend API Service**: `admin/src/services/api.ts`
- **Frontend Contexts**: `admin/src/contexts/`

---

## 🎉 Kesimpulan

✅ Admin panel sekarang **100% menggunakan Laravel backend**

✅ Express backend **tidak digunakan lagi**

✅ Semua fitur admin sudah tersedia di Laravel

✅ Authentication menggunakan Bearer token + api_tokens table

✅ Frontend sudah terintegrasi dengan Laravel API

---

**Updated:** February 14, 2026
**Status:** ✅ Production Ready
