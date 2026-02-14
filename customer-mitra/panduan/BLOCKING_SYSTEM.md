# User Blocking System Documentation

## Overview
Sistem user blocking memungkinkan admin untuk memblokir akses user (customer/mitra) yang melakukan pelanggaran ketentuan platform.

## Backend Implementation

### Database Schema
Tabel `users` ditambahkan 3 kolom baru:
- `status` (enum: 'active', 'blocked') - default: 'active'
- `blocked_reason` (text, nullable) - alasan pemblokiran
- `blocked_at` (timestamp, nullable) - waktu pemblokiran

### API Endpoints

#### 1. Block User
```
POST /api/v1/admin/users/{userId}/block
Authorization: Bearer {admin_token}
Content-Type: application/json

Request Body:
{
  "reason": "Alasan pemblokiran"
}

Response (200):
{
  "success": true,
  "message": "User berhasil diblokir",
  "data": {
    "id": 1,
    "name": "User Name",
    "email": "user@example.com",
    "status": "blocked",
    "blocked_reason": "Alasan pemblokiran",
    "blocked_at": "2024-02-12T10:30:00.000000Z"
  }
}
```

#### 2. Unblock User
```
POST /api/v1/admin/users/{userId}/unblock
Authorization: Bearer {admin_token}

Response (200):
{
  "success": true,
  "message": "User berhasil dibuka blokirnya",
  "data": {
    "id": 1,
    "name": "User Name",
    "email": "user@example.com",
    "status": "active"
  }
}
```

#### 3. Get User Status
```
GET /api/v1/admin/users/{userId}/status
Authorization: Bearer {admin_token}

Response (200):
{
  "success": true,
  "data": {
    "id": 1,
    "name": "User Name",
    "email": "user@example.com",
    "role": "customer",
    "status": "blocked",
    "blocked_reason": "Alasan pemblokiran",
    "blocked_at": "2024-02-12T10:30:00.000000Z"
  }
}
```

#### 4. Get All Blocked Users
```
GET /api/v1/admin/users/blocked?per_page=15
Authorization: Bearer {admin_token}

Response (200):
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "User Name",
      "email": "user@example.com",
      "status": "blocked",
      "blocked_reason": "Alasan pemblokiran",
      "blocked_at": "2024-02-12T10:30:00.000000Z"
    }
  ],
  "pagination": {
    "current_page": 1,
    "per_page": 15,
    "total": 10,
    "last_page": 1
  }
}
```

### Middleware
`CheckUserStatus` middleware memeriksa status user pada setiap request:
- Mengekstrak Bearer token dari header
- Hash token dengan SHA-256
- Query database untuk mendapatkan user
- Jika status = 'blocked', return 403 dengan detail

Middleware diterapkan pada routes yang memerlukan autentikasi:
- `/auth/logout`
- `/auth/change-password`
- `/auth/me`
- `/auth/update-profile`
- `/balance`
- `/saved-passengers`
- `/pin/*`
- `/phone-verification/*`
- `/rides` (POST)
- `/mitra/riwayat`

### Login Protection
`AuthController::login()` memeriksa status user setelah verifikasi password:
```php
if ($user->status === 'blocked') {
    return response()->json([
        'success' => false,
        'message' => 'Akun Anda telah diblokir',
        'blocked_reason' => $user->blocked_reason,
        'blocked_at' => $user->blocked_at,
    ], 403);
}
```

## Frontend Implementation (Flutter)

### Custom Exception
```dart
class UserBlockedException implements Exception {
  final String reason;
  final DateTime? blockedAt;
}
```

### Blocked User Page
`BlockedUserPage` widget menampilkan:
- Icon block merah
- Judul "Akun Anda Diblokir"
- Tanggal pemblokiran
- Card dengan alasan pemblokiran
- Card info customer support
- Tombol logout

### Login Integration
Login screen menangkap `UserBlockedException` dan redirect ke `BlockedUserPage`:
```dart
on UserBlockedException catch (e) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => BlockedUserPage(
        reason: e.reason,
        blockedAt: e.blockedAt,
      ),
    ),
  );
}
```

### HTTP Client Helper
`HttpClientHelper` mengecek response 403 secara global:
- Parse response body untuk blocked_reason
- Clear local storage
- Navigate ke BlockedUserPage

## Usage Examples

### Block a User (Admin Panel)
```dart
final response = await http.post(
  Uri.parse('$baseUrl/admin/users/$userId/block'),
  headers: {
    'Authorization': 'Bearer $adminToken',
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'reason': 'Melanggar ketentuan platform - spam booking',
  }),
);
```

### Check if User is Blocked
```dart
final response = await http.get(
  Uri.parse('$baseUrl/admin/users/$userId/status'),
  headers: {
    'Authorization': 'Bearer $adminToken',
  },
);

final data = json.decode(response.body);
if (data['data']['status'] == 'blocked') {
  print('User is blocked: ${data['data']['blocked_reason']}');
}
```

## Security Notes
1. **Admin Only**: Hanya user dengan role 'admin' yang dapat memblokir user
2. **Protected Roles**: Admin dan Finance tidak dapat diblokir
3. **Token Validation**: Middleware memvalidasi token sebelum memeriksa status
4. **Automatic Logout**: Blocked user otomatis logout dari semua device

## Testing
Gunakan script `test_blocking_system.sh` untuk testing:
```bash
cd backend
chmod +x test_blocking_system.sh
./test_blocking_system.sh
```

Update credentials di script sebelum menjalankan.

## Migration
```bash
php artisan migrate
```

Migration file: `2026_02_12_073437_add_status_and_blocked_reason_to_users_table.php`

## Files Modified

### Backend
- `database/migrations/2026_02_12_073437_add_status_and_blocked_reason_to_users_table.php` (NEW)
- `app/Models/User.php` - Added fillable fields
- `app/Http/Middleware/CheckUserStatus.php` (NEW)
- `app/Http/Controllers/Api/Admin/UserManagementController.php` (NEW)
- `app/Http/Controllers/Api/AuthController.php` - Added login check
- `bootstrap/app.php` - Registered middleware
- `routes/api.php` - Added routes and middleware

### Frontend
- `lib/screens/auth/blocked_user_page.dart` (NEW)
- `lib/services/shared/auth_service.dart` - Added UserBlockedException
- `lib/services/shared/http_client_helper.dart` (NEW)
- `lib/screens/auth/login_screen.dart` - Added blocked user handling

## Future Enhancements
1. Email notification saat user diblokir
2. Push notification untuk blocked users
3. Auto-logout dari semua devices
4. Appeal system untuk user yang diblokir
5. Temporary block dengan auto-unblock timer
6. Block history tracking
