# Nebeng - Fullstack Project

Aplikasi fullstack dengan Flutter (Frontend) dan Laravel (Backend).

## Struktur Project

```
nebeng-fullstack/
├── frontend/          # Flutter Application
│   ├── lib/
│   ├── pubspec.yaml
│   └── ...
└── backend/           # Laravel API
    ├── app/
    ├── routes/
    └── ...
```

## Setup & Installation

### Backend (Laravel)

1. Masuk ke folder backend:
```bash
cd /home/naufal/project/nebeng-fullstack/backend
```

2. Install dependencies:
```bash
composer install
```

3. Copy .env file:
```bash
cp .env.example .env
```

4. Generate application key:
```bash
php artisan key:generate
```

5. Jalankan server:
```bash
php artisan serve
```

Server akan berjalan di: `http://localhost:8000`

### Frontend (Flutter)

1. Masuk ke folder frontend:
```bash
cd /home/naufal/project/nebeng-fullstack/frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Update baseUrl di `lib/services/api_service.dart` sesuai kebutuhan:
   - Development: `http://localhost:8000/api/v1`
   - Android Emulator: `http://10.0.2.2:8000/api/v1`
   - iOS Simulator: `http://localhost:8000/api/v1`
   - Real Device: `http://YOUR_IP:8000/api/v1`

4. Jalankan aplikasi:
```bash
flutter run
```

## API Endpoints

Base URL: `http://localhost:8000/api/v1`

### Available Endpoints:

- **GET** `/health` - Health check
- **GET** `/users` - Get all users
- **GET** `/users/{id}` - Get user by ID
- **POST** `/users` - Create new user
  - Body: `{ "name": "string", "email": "string" }`

## Testing API

Gunakan halaman `ApiTestPage` untuk test koneksi API:
1. Jalankan backend Laravel
2. Jalankan aplikasi Flutter
3. Tekan tombol untuk test berbagai endpoint

## Development Tips

### Menjalankan keduanya bersamaan:

Terminal 1 (Backend):
```bash
cd /home/naufal/project/nebeng-fullstack/backend && php artisan serve
```

Terminal 2 (Frontend):
```bash
cd /home/naufal/project/nebeng-fullstack/frontend && flutter run
```

### CORS Configuration

CORS middleware sudah dikonfigurasi di `app/Http/Middleware/Cors.php` untuk mengizinkan request dari Flutter.

## Project Structure

### Flutter (Frontend)
```
lib/
├── main.dart
├── screens/
│   ├── detail_page.dart
│   └── api_test_page.dart
├── services/
│   └── api_service.dart
└── repositories/
    └── user_repository.dart
```

### Laravel (Backend)
```
app/
├── Http/
│   ├── Controllers/
│   │   └── Api/
│   │       └── UserController.php
│   └── Middleware/
│       └── Cors.php
└── ...
routes/
└── api.php
```

## Notes

- Pastikan backend Laravel berjalan sebelum menjalankan Flutter app
- Untuk testing di real device, gunakan IP address komputer Anda
- CORS sudah dikonfigurasi untuk development, adjust untuk production
