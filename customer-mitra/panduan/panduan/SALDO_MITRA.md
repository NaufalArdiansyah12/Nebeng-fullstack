# Panduan Sistem Saldo Mitra

## Deskripsi
Sistem saldo mitra memungkinkan setiap mitra untuk melihat saldo mereka yang ditampilkan pada halaman beranda aplikasi mobile. Saldo ini tersimpan di database dan dapat diambil melalui API.

## Struktur Database

### Tabel: `users`
Kolom baru yang ditambahkan:
- `balance` (DECIMAL 15,2) - Menyimpan saldo mitra dengan default value 0.00

### Migration
File: `database/migrations/2026_02_03_061619_add_balance_to_users_table.php`

```php
Schema::table('users', function (Blueprint $table) {
    $table->decimal('balance', 15, 2)->default(0)->after('password');
});
```

## Backend API

### Endpoint: Get Balance
**URL:** `GET /api/v1/balance`

**Headers:**
```
Accept: application/json
Authorization: Bearer {token}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Saldo berhasil diambil",
  "data": {
    "balance": 250000.00,
    "formatted_balance": "Rp 250.000"
  }
}
```

**Response Error (404):**
```json
{
  "success": false,
  "message": "User tidak ditemukan"
}
```

### Controller
File: `app/Http/Controllers/Api/UserController.php`

Method: `getBalance(Request $request)`

## Frontend (Flutter)

### API Service
File: `lib/services/api/profile_service.dart`

Method baru:
```dart
static Future<Map<String, dynamic>> getBalance({
  required String token,
}) async
```

File: `lib/services/api_service.dart`
```dart
static Future<Map<String, dynamic>> getBalance({required String token}) =>
    ProfileService.getBalance(token: token);
```

### UI - Halaman Beranda Mitra
File: `lib/screens/mitra/home_page.dart`

#### State Variables Baru:
- `double _balance = 0.0;` - Menyimpan nilai saldo
- `bool _isBalanceVisible = true;` - Status visibility saldo

#### Fitur:
1. **Fetch Balance dari API** - Dipanggil di method `_loadData()`
2. **Toggle Visibility** - Tombol eye icon untuk show/hide saldo
3. **Format Rupiah** - Menampilkan saldo dengan format "Rp 250.000,00"
4. **Hidden Mode** - Menampilkan "Rp ••••••" saat disembunyikan

## Testing

### Update Saldo via Tinker
```bash
php artisan tinker

# Update saldo untuk mitra tertentu
$user = User::where('role', 'mitra')->first();
$user->balance = 250000;
$user->save();
```

### Test API via cURL
```bash
curl -X GET "http://localhost:8000/api/v1/balance" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## Cara Penggunaan

1. **Di Backend:**
   - Jalankan migration: `php artisan migrate`
   - Saldo akan otomatis diset ke 0 untuk semua user
   - Update saldo mitra sesuai kebutuhan

2. **Di Frontend:**
   - Buka aplikasi sebagai Mitra
   - Login dengan akun mitra
   - Lihat saldo di card berwarna biru di halaman beranda
   - Klik icon mata untuk show/hide saldo

## Pengembangan Selanjutnya

Beberapa fitur yang bisa ditambahkan:
1. **Tarik Saldo** - Fitur untuk withdraw balance
2. **Riwayat Penarikan** - History transaksi penarikan
3. **Auto Update Balance** - Update otomatis setelah trip selesai
4. **Notifikasi** - Notifikasi saat saldo bertambah/berkurang
5. **Minimum Withdrawal** - Batas minimal penarikan saldo
