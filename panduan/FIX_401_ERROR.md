# Fix 401 Authentication Error - Mitra Riwayat Page

## Masalah
Halaman riwayat mitra kadang-kadang menampilkan error 401 (Unauthorized) dengan pesan:
```
Terjadi Kesalahan
Exception: Failed to fetch mitra history: 401
```

## Root Cause Analysis
Error 401 terjadi karena beberapa kemungkinan:
1. Token tidak tersimpan dengan benar di SharedPreferences
2. Token hilang/corrupt saat app restart
3. Backend menolak token yang dikirim

## Solusi yang Diimplementasikan

### 1. Frontend - Error Handling (riwayat_page.dart)

#### A. Penambahan Logging
```dart
print('Fetching riwayat with token: ${token != null ? "Token exists (${token.length} chars)" : "No token"}');
print('Error fetching mitra history: $e');
print('401 error detected - session expired');
```

#### B. Session Expired Handler
Menambahkan method `_handleSessionExpired()` yang:
- Menghapus token dari SharedPreferences
- Menampilkan dialog "Sesi Berakhir"
- Redirect ke halaman login
- Mencegah dialog muncul berkali-kali dengan flag `_isShowingSessionDialog`

#### C. Token Validation
Mengecek token sebelum API call:
```dart
if (token == null || token.isEmpty) {
  print('No token found, redirecting to login');
  _handleSessionExpired();
  return;
}
```

### 2. Backend - Enhanced Logging (MitraHistoryController.php)

Menambahkan logging untuk debugging:
```php
\Log::info('MitraHistory: Bearer token received', [...]);
\Log::warning('MitraHistory: No bearer token provided');
\Log::warning('MitraHistory: Invalid token', [...]);
\Log::warning('MitraHistory: Token expired', [...]);
\Log::info('MitraHistory: Authenticated user', ['user_id' => $userId]);
```

Menambahkan explicit check untuk token expiration:
```php
if ($apiToken->expires_at < now()) {
    \Log::warning('MitraHistory: Token expired', [...]);
    return response()->json(['success' => false, 'message' => 'Token expired'], 401);
}
```

## Testing

### 1. Verifikasi Token di Database
```bash
cd backend
php artisan tinker --execute="use App\Models\ApiToken; echo 'Total tokens: ' . ApiToken::count() . PHP_EOL; echo 'Expired tokens: ' . ApiToken::where('expires_at', '<', now())->count() . PHP_EOL;"
```

### 2. Test Manual dengan Token Invalid
1. Login sebagai mitra
2. Edit SharedPreferences dan corrupt/hapus token
3. Refresh halaman riwayat
4. Seharusnya muncul dialog "Sesi Berakhir" dan redirect ke login

### 3. Monitoring Logs

**Frontend (Flutter Console):**
```
Fetching riwayat with token: Token exists (64 chars)
Successfully fetched 5 items
```

atau jika error:
```
Error fetching mitra history: Exception: Failed to fetch mitra history: 401
401 error detected - session expired
Cleared session data, showing dialog
```

**Backend (Laravel Log):**
```bash
tail -f storage/logs/laravel.log | grep MitraHistory
```

Output normal:
```
MitraHistory: Bearer token received
MitraHistory: Authenticated user {"user_id":2}
```

Output error:
```
MitraHistory: No bearer token provided
# atau
MitraHistory: Invalid token
# atau
MitraHistory: Token expired
```

## User Experience

### Sebelum Fix
- Error message tidak jelas: "Exception: Failed to fetch mitra history: 401"
- User tidak tahu apa yang harus dilakukan
- Harus restart app atau clear cache manual

### Sesudah Fix
- Dialog informatif: "Sesi Anda telah berakhir. Silakan login kembali."
- Auto-redirect ke halaman login
- Token otomatis dibersihkan
- User bisa langsung login lagi

## File yang Dimodifikasi

1. `frontend/lib/screens/mitra/riwayat_page.dart`
   - Line 15: Tambah flag `_isShowingSessionDialog`
   - Line 47-54: Logging untuk token check
   - Line 68-76: Enhanced error handling dengan logging
   - Line 82-115: Method `_handleSessionExpired()` dengan flag prevention

2. `backend/app/Http/Controllers/Api/MitraHistoryController.php`
   - Line 18-47: Enhanced logging dan explicit token expiration check

## Next Steps (Optional Improvements)

1. **Token Refresh Mechanism**
   - Implement token refresh before expiration
   - Auto-renew token ketika mendekati expiry

2. **Retry Logic**
   - Auto-retry request sekali jika gagal
   - Refresh token dan retry sebelum logout

3. **Better Token Persistence**
   - Gunakan secure storage untuk token
   - Implement token encryption di SharedPreferences

4. **Monitoring Dashboard**
   - Track 401 errors di analytics
   - Alert jika banyak user mengalami 401

## Troubleshooting

### Problem: Dialog muncul berkali-kali
**Solution**: Flag `_isShowingSessionDialog` sudah mencegah ini

### Problem: Token hilang setelah app restart
**Solution**: Cek SharedPreferences initialization di app startup

### Problem: Backend log tidak muncul
**Solution**: 
```bash
cd backend
# Pastikan logging enabled
php artisan config:cache
# Set log level ke debug di .env
LOG_LEVEL=debug
```

### Problem: Frontend log tidak muncul di console
**Solution**: Run Flutter dengan verbose:
```bash
cd frontend
flutter run -v
```
