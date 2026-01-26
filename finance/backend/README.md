# Backend Laravel - Finance Tugas

## Setup

1. **Install Dependencies**
   ```bash
   composer install
   ```

2. **Setup Environment**
   - Copy `.env.example` ke `.env` (atau buat file `.env` baru)
   - Konfigurasi database di `.env`:
     ```env
     DB_CONNECTION=mysql
     DB_HOST=127.0.0.1
     DB_PORT=3306
     DB_DATABASE=nebeng_bro
     DB_USERNAME=root
     DB_PASSWORD=
     ```
   - Konfigurasi email untuk reset password (lihat `MAIL_SETUP.md` untuk detail):
     ```env
     MAIL_MAILER=smtp
     MAIL_HOST=smtp.gmail.com
     MAIL_PORT=587
     MAIL_USERNAME=your-email@gmail.com
     MAIL_PASSWORD=your-app-password
     MAIL_ENCRYPTION=tls
     MAIL_FROM_ADDRESS=your-email@gmail.com
     MAIL_FROM_NAME="${APP_NAME}"
     FRONTEND_URL=http://localhost:5173
     ```

3. **Generate Application Key**
   ```bash
   php artisan key:generate
   ```

4. **Run Migrations** (jika diperlukan)
   ```bash
   php artisan migrate
   ```

5. **Start Server**
   ```bash
   php artisan serve
   ```

Server akan berjalan di `http://127.0.0.1:8000`

## API Endpoints

### Dashboard
- `GET /api/pendapatan` - Total pendapatan
- `GET /api/pendapatan/chart` - Chart pendapatan per bulan

### Bookings
- `GET /api/bookings/chart` - Chart pesanan
- `GET /api/bookings/transactions` - Semua transaksi booking

### Transactions
- `GET /api/transactions/{id}` - Detail transaksi

### Users
- `GET /api/users/count-by-role` - Jumlah user per role
- `GET /api/users/mitra` - Daftar user mitra
- `POST /api/users/login` - Login admin
- `GET /api/users/{id}` - Get user by ID
- `GET /api/users/profile/{id}` - Get profile user
- `PUT /api/users/profile/{id}` - Update profile
- `PUT /api/users/account/{id}` - Update account (email/password)

## CORS Configuration

CORS sudah dikonfigurasi untuk mengizinkan request dari:
- `http://localhost:5173` (Vite dev server)
- `http://localhost:3000`
- `http://127.0.0.1:5173`
- `http://127.0.0.1:3000`

Konfigurasi ada di `config/cors.php`

## Database

Database yang digunakan: MySQL
- Database name: `nebeng_bro`
- Host: `localhost` (127.0.0.1)
- Username: `root`
- Password: (kosong)

Pastikan database sudah dibuat sebelum menjalankan aplikasi.

## Email Configuration

Untuk setup email Gmail untuk fitur reset password, lihat file `MAIL_SETUP.md` untuk panduan lengkap.

**Quick Setup:**
1. Buat App Password di Google Account (Security > App passwords)
2. Tambahkan konfigurasi email di `.env` (lihat contoh di atas)
3. Clear config cache: `php artisan config:clear`
