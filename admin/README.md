# 🚀 Admin Panel - Nebeng Fullstack

Admin Panel untuk Nebeng sudah dimigrasi dari Express.js backend ke **Laravel backend**.

## 🎯 Prerequisites

- **Laravel Backend** harus sudah berjalan di `http://localhost:8000`
- Node.js atau Bun terinstall
- Admin account di database

## ⚡ Quick Start

### 1. Setup & Run (Otomatis)

```bash
./start.sh
```

Script ini akan:
- ✓ Check dependencies
- ✓ Install packages
- ✓ Verify .env configuration
- ✓ Check Laravel backend
- ✓ Start dev server

### 2. Manual Setup

```bash
# Install dependencies
npm install  # atau: bun install

# Copy .env (jika belum ada)
cp .env.example .env

# Start dev server
npm run dev  # atau: bun run dev
```

### 3. Start Laravel Backend

```bash
cd ../backend
php artisan serve
```

## 🔐 Login

Buka browser: `http://localhost:5173`

**Default admin account:**
```
Email: admin@nebeng.com
Password: password123
```

⚠️ **PENTING**: Ganti password setelah login pertama!

## 🧪 Test API

Test semua endpoint admin API:

```bash
./test-api.sh
```

Script ini akan test:
- Login
- Token verification
- Profile
- Dashboard statistics
- Customers list
- Mitra list
- Pesanan list
- Logout

## 📚 Dokumentasi

Dokumentasi lengkap ada di [BACKEND_MIGRATION.md](./BACKEND_MIGRATION.md):

- ✓ Daftar semua API endpoints
- ✓ Authentication flow
- ✓ Response format
- ✓ Troubleshooting guide
- ✓ Testing checklist

## 🛠️ Development

### Build untuk Production

```bash
npm run build  # atau: bun run build
```

### Preview Production Build

```bash
npm run preview  # atau: bun run preview
```

## 📦 Tech Stack

- **Frontend**: React + TypeScript + Vite
- **UI Library**: shadcn/ui + Tailwind CSS
- **State Management**: React Context API
- **HTTP Client**: Axios
- **Backend**: Laravel 11

## 🔗 Links

- Admin Panel: `http://localhost:5173`
- Laravel API: `http://localhost:8000/api/admin`
- API Routes: `../backend/routes/api.php`
- Controllers: `../backend/app/Http/Controllers/Admin/`

## 📞 Support

Jika ada masalah:

1. Check Laravel logs: `backend/storage/logs/laravel.log`
2. Check browser console untuk frontend errors
3. Test API dengan `./test-api.sh`
4. Baca troubleshooting di [BACKEND_MIGRATION.md](./BACKEND_MIGRATION.md)

---

**Status:** ✅ Production Ready  
**Backend:** Laravel 11  
**Last Updated:** February 14, 2026

