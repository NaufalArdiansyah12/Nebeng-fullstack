# Fitur Verifikasi Nomor HP via Email OTP

## 📋 Overview

Fitur ini memungkinkan user untuk memverifikasi nomor HP mereka menggunakan kode OTP yang dikirim melalui **EMAIL** (bukan SMS). Ini adalah pendekatan yang lebih aman, murah, dan reliable.

## 🔄 Flow Verifikasi

1. **User mengakses menu Keamanan** di halaman Profile
2. **Klik "Nomor ponsel terverifikasi"**
3. **Input nomor HP** yang ingin diverifikasi
4. **Sistem mengirim OTP 6 digit** ke email user yang terdaftar
5. **User cek email** dan copy kode OTP
6. **Input OTP** di aplikasi
7. **Sistem verify** → Jika benar, nomor HP terverifikasi ✅

## 🛠️ Komponen yang Dibuat

### Backend (Laravel)

#### 1. **Database & Models**
- **Migration**: `2026_02_02_000001_add_phone_verified_to_users_table.php`
  - Menambahkan field `phone_verified` dan `phone_verified_at` ke tabel `users`
  
- **Migration**: `2026_02_02_000002_create_phone_otps_table.php`
  - Tabel untuk menyimpan OTP codes dengan expiry time, attempts tracking
  
- **Model**: `app/Models/PhoneOtp.php`
  - Helper methods: `isExpired()`, `isValid()`, `hasReachedMaxAttempts()`, `markAsUsed()`

#### 2. **Email Template**
- **Mail Class**: `app/Mail/PhoneVerificationOtp.php`
- **Blade View**: `resources/views/emails/phone-verification-otp.blade.php`
  - Email template yang cantik dengan styling modern

#### 3. **Controller & Routes**
- **Controller**: `app/Http/Controllers/Api/PhoneVerificationController.php`
  - `sendOtp()` - Kirim OTP ke email
  - `verifyOtp()` - Verify OTP yang diinput
  - `resendOtp()` - Kirim ulang OTP baru
  - `getPhoneStatus()` - Cek status verifikasi
  
- **Routes**: `routes/api.php`
  ```php
  POST /api/v1/phone-verification/send-otp
  POST /api/v1/phone-verification/verify-otp
  POST /api/v1/phone-verification/resend-otp
  GET  /api/v1/phone-verification/status
  ```

### Frontend (Flutter)

#### 1. **Service Layer**
- **Service**: `lib/services/api/phone_verification_service.dart`
  - Method untuk call semua API endpoints

#### 2. **UI Screens**

**Customer:**
- `lib/screens/customer/profile/phone_verification_page.dart`
- `lib/screens/customer/profile/otp_verification_page.dart`

**Mitra:**
- `lib/screens/mitra/profile/security/phone_verification_page.dart`
- `lib/screens/mitra/profile/security/otp_verification_page.dart`

#### 3. **Models**
- **Updated**: `lib/models/user_model.dart`
  - Menambahkan field `phone` dan `phoneVerified`

## 🔐 Security Features

### Backend Security
1. **OTP Hashing** - OTP di-hash menggunakan `bcrypt` sebelum disimpan
2. **Rate Limiting** - User hanya bisa request OTP setiap 60 detik
3. **Expiry Time** - OTP expire dalam 10 menit
4. **Max Attempts** - Maksimal 3x percobaan salah, setelah itu OTP di-invalidate
5. **Single Use** - OTP hanya bisa digunakan 1x
6. **Phone Uniqueness** - Nomor HP yang sudah terverifikasi tidak bisa digunakan user lain

### Frontend Security
1. **Token Validation** - Semua request menggunakan Bearer token
2. **Input Validation** - Validasi format nomor HP (10-15 digit)
3. **Countdown Timer** - 60 detik sebelum bisa resend OTP
4. **Auto-focus** - Auto move ke field berikutnya saat input OTP

## 📱 User Experience

### Phone Verification Screen
- ✅ Clean UI dengan icon yang jelas
- ✅ Form validation real-time
- ✅ Loading state untuk feedback
- ✅ Info box dengan catatan penting
- ✅ Auto-detect jika sudah terverifikasi

### OTP Input Screen
- ✅ 6 individual boxes untuk OTP digits
- ✅ Auto-focus ke field berikutnya
- ✅ Auto-verify saat semua field terisi
- ✅ Countdown timer untuk resend
- ✅ Remaining attempts indicator
- ✅ Success dialog dengan animasi

## 🎨 Design Consistency

- Warna primary: `#1E40AF` (Blue)
- Border radius: 12px untuk card/input
- Font: System default dengan weight variations
- Icons: Material Design Icons
- Spacing: Consistent 8px grid system

## 🚀 Testing

### Test Backend
```bash
cd backend

# Test send OTP
curl -X POST http://localhost:8000/api/v1/phone-verification/send-otp \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"phone": "081234567890"}'

# Cek email inbox untuk OTP code

# Test verify OTP
curl -X POST http://localhost:8000/api/v1/phone-verification/verify-otp \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"phone": "081234567890", "otp_code": "123456"}'
```

### Test Frontend
1. Run aplikasi: `flutter run`
2. Login sebagai user
3. Navigasi: Profile → Keamanan → Nomor ponsel terverifikasi
4. Input nomor HP → Kirim kode OTP
5. Cek email untuk kode OTP
6. Input OTP → Verify

## ⚙️ Configuration

### Email Configuration (Laravel)
Pastikan `.env` sudah dikonfigurasi:
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="${APP_NAME}"
```

### Flutter Dependencies
Dependencies yang digunakan (sudah ada di project):
- `http` - HTTP requests
- `shared_preferences` - Local storage
- `easy_localization` - Internationalization (customer)

## 📊 Database Schema

### Table: users (updated)
```sql
phone VARCHAR(20) NULLABLE
phone_verified BOOLEAN DEFAULT FALSE
phone_verified_at TIMESTAMP NULLABLE
```

### Table: phone_otps (new)
```sql
id BIGINT PRIMARY KEY
user_id BIGINT FOREIGN KEY
phone VARCHAR(20)
otp_code VARCHAR(255) -- hashed
attempts INT DEFAULT 0
expires_at TIMESTAMP
is_used BOOLEAN DEFAULT FALSE
created_at TIMESTAMP
updated_at TIMESTAMP
```

## ✅ Keuntungan Implementasi Ini

1. **Gratis** - Tidak perlu bayar SMS gateway
2. **Lebih Aman** - Email lebih secure, OTP di-hash
3. **Reliable** - Email delivery rate tinggi
4. **User-friendly** - Copy-paste OTP dari email
5. **Scalable** - Mudah di-maintain dan di-extend
6. **Professional** - Email template yang menarik

## 🔄 Future Enhancements

Possible improvements:
- [ ] Add phone verification badge di profile
- [ ] Reward points untuk user yang verify phone
- [ ] Notification preference untuk verified users
- [ ] 2FA menggunakan OTP via email
- [ ] Backup email untuk recovery

## 📝 Notes

- Migration sudah dijalankan: ✅
- Backend routes sudah terdaftar: ✅
- Frontend screens sudah terintegrasi: ✅
- Email template sudah siap: ✅
- Security measures sudah diimplementasi: ✅

---

**Status**: ✅ **READY FOR PRODUCTION**

Implementasi sudah lengkap dan siap digunakan!
