# Dokumentasi Login Multi-User Type

## Overview
Sistem login sekarang mendukung 2 tipe user yang berbeda:
1. **User** - dari tabel `users` (customer, mitra, admin)
2. **PosMitra** - dari tabel `posmitra_users`

Kedua tabel ini memiliki kolom `email` yang bisa saja sama, jadi perlu ada cara untuk membedakan mana yang login.

### Auto-Detection
Backend akan **otomatis mendeteksi** tipe user:
- Pertama cek di tabel `users`
- Jika tidak ditemukan, cek di tabel `posmitra_users`
- Response akan include field `role: 'posmitra'` untuk pos mitra users

**Artinya:** Frontend **tidak perlu** mengirim parameter `user_type` - backend akan handle secara otomatis!

## Perubahan Database

### Migration
File: `2026_02_07_000001_add_user_type_to_api_tokens_table.php`
- Menambahkan kolom `user_type` di tabel `api_tokens`
- Values: `'user'` atau `'posmitra'`
- Default: `'user'`

### Model ApiToken
- Menambahkan `user_type` ke fillable
- Menambahkan relasi `posMitraUser()`
- Menambahkan method `getAuthenticatedUser()` untuk mendapatkan user yang tepat

## Endpoint Login

### 1. Login Standard (Support Kedua Tipe)
**Endpoint:** `POST /api/v1/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "user_type": "user"  // optional, default: "user"
}
```

**user_type values:**
- `"user"` - Login sebagai user dari tabel users (customer, mitra, admin)
- `"posmitra"` - Login sebagai pos mitra dari tabel posmitra_users

**Response Success (User):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "user_type": "user",
      "reward_points": 100,
      "average_rating": 4.5,
      "total_ratings": 10,
      "role": "customer"
    },
    "token": "randomtoken123..."
  }
}
```

**Response Success (PosMitra):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Pos Mitra A",
      "email": "posmitra@example.com",
      "user_type": "posmitra",
      "location_id": 5,
      "balance": 50000
    },
    "token": "randomtoken123..."
  }
}
```

**Response Error:**
```json
{
  "success": false,
  "message": "Email atau password salah"
}
```

### 2. Login Khusus PosMitra
**Endpoint:** `POST /api/v1/auth/login/posmitra`

**Request Body:**
```json
{
  "email": "posmitra@example.com",
  "password": "password123"
}
```

Endpoint ini otomatis akan mencari di tabel `posmitra_users` saja, tidak perlu parameter `user_type`.

**Response Success:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "name": "Pos Mitra A",
      "email": "posmitra@example.com",
      "user_type": "posmitra",
      "location_id": 5,
      "balance": 50000
    },
    "token": "randomtoken123..."
  }
}
```

## Endpoint Me (Get Current User)
**Endpoint:** `GET /api/v1/auth/me`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:** Akan mengembalikan data user berdasarkan `user_type` yang tersimpan di token.

## Contoh Penggunaan

### Frontend Flutter/Mobile

#### Login User Biasa (Customer/Mitra)
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'email': email,
    'password': password,
    'user_type': 'user', // atau biarkan kosong untuk default
  }),
);
```

#### Login Pos Mitra (Opsi 1 - Pakai endpoint khusus)
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/login/posmitra'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'email': email,
    'password': password,
  }),
);
```

#### Login Pos Mitra (Opsi 2 - Pakai endpoint standard)
```dart
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'email': email,
    'password': password,
    'user_type': 'posmitra',
  }),
);
```

### Frontend Web (React/Vue/Angular)

#### Login User
```javascript
const response = await axios.post('/api/v1/auth/login', {
  email: email,
  password: password,
  user_type: 'user' // optional
});
```

#### Login Pos Mitra
```javascript
const response = await axios.post('/api/v1/auth/login/posmitra', {
  email: email,
  password: password
});
```

## Validasi & Keamanan

### Validasi Email Duplikat
Sistem sekarang aman untuk email yang sama di kedua tabel karena:
1. Setiap login harus specify `user_type` (atau default ke 'user')
2. Token menyimpan `user_type` sehingga sistem tahu harus cek ke tabel mana
3. Tidak ada konflik karena setiap request authenticated akan cek token dengan user_type yang benar

### Best Practices
1. **Frontend harus tahu** user type sebelum login (misalnya dari halaman login yang berbeda atau dropdown selector)
2. **Gunakan endpoint khusus** `/auth/login/posmitra` untuk pos mitra agar lebih jelas dan tidak perlu parameter tambahan
3. **Simpan user_type** di local storage bersama dengan token untuk reference frontend
4. **Validasi token** di setiap request akan otomatis cek user_type yang tepat

## Migration Existing Data

Jika ada token yang sudah ada sebelum update ini:
- Semua token existing akan memiliki `user_type = 'user'` (default)
- Pos mitra yang sudah login perlu login ulang untuk mendapatkan token dengan `user_type = 'posmitra'`

## Troubleshooting

### Email sama di kedua tabel
✅ **Solved!** Tidak masalah karena sistem akan cek berdasarkan `user_type`.

### User tidak bisa login
1. Pastikan `user_type` parameter benar
2. Cek apakah email ada di tabel yang sesuai (`users` atau `posmitra_users`)
3. Verify password benar

### Token invalid setelah update
Normal jika ada token lama sebelum migration. User harus login ulang.

## Notes
- Logout tetap sama, tidak ada perubahan
- Change password dan update profile perlu update juga jika ingin support pos mitra (currently hanya support users table)
- Method `me()` sudah support kedua tipe user
