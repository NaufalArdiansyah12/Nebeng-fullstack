# Finance Tugas - Nebeng Finance Dashboard

Aplikasi dashboard finance untuk mengelola transaksi, mitra, dan pencairan dana.

## Tech Stack

- **Frontend**: React + TypeScript + Vite
- **Backend**: Laravel (PHP)
- **Database**: MySQL
- **UI**: shadcn-ui + Tailwind CSS

## Setup

### Frontend

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend akan berjalan di `http://localhost:8080`

### Backend Laravel

```bash
cd backend-laravel

# Install dependencies
composer install

# Setup environment
# Buat file .env dan konfigurasi database

# Generate application key
php artisan key:generate

# Start server
php artisan serve
```

Backend akan berjalan di `http://127.0.0.1:8000`

## Konfigurasi Database

Buat file `.env` di folder `backend-laravel`:

```env
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nebeng_bro
DB_USERNAME=root
DB_PASSWORD=
```

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

## Development

### Build untuk production

```bash
npm run build
```

### Preview production build

```bash
npm run preview
```

## License

ISC
