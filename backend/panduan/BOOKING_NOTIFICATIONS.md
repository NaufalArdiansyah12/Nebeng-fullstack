# Implementasi Notifikasi Status Booking

## Ringkasan Perubahan

Sistem notifikasi FCM telah ditingkatkan untuk mengirim notifikasi push tidak hanya saat pembayaran berhasil, tetapi juga setiap kali status booking berubah.

## File Baru

### `backend/app/Services/BookingNotificationService.php`
Service terpusat untuk menangani pengiriman notifikasi booking dengan pesan yang disesuaikan untuk setiap status.

**Status yang didukung:**
- `paid` - Pembayaran Berhasil 🎉
- `confirmed` / `dijemput` - Booking Dikonfirmasi ✅
- `menuju_penjemputan` - Driver Menuju Lokasi Penjemputan 🚗
- `sudah_di_penjemputan` / `arrived` - Driver Sudah Tiba 📍
- `sedang_dalam_perjalanan` / `in_progress` / `menuju_tujuan` - Perjalanan Dimulai 🛣️
- `sudah_sampai_tujuan` / `near_destination` - Hampir Sampai Tujuan 🎯
- `completed` / `done` / `selesai` - Perjalanan Selesai ✨
- `cancelled` / `dibatalkan` - Booking Dibatalkan ❌
- `expired` / `kadaluarsa` - Booking Kadaluarsa ⏰
- `pending` - Menunggu Pembayaran 💳
- `refunded` / `dikembalikan` - Pembayaran Dikembalikan 💰

## File yang Dimodifikasi

### 1. `backend/app/Services/PaymentService.php`
- Import `BookingNotificationService`
- Mengirim notifikasi saat pembayaran berhasil (status `paid`)
- Mengirim notifikasi untuk semua jenis booking (motor, mobil, barang, titip barang)

### 2. `backend/app/Http/Controllers/Api/BookingTrackingController.php`
- Import `BookingNotificationService`
- Mengirim notifikasi saat:
  - Auto-transition ke `menuju_penjemputan` (departure time passed)
  - Driver memulai trip (`startTrip`)
  - Driver menyelesaikan trip (`completeTrip`)

### 3. `backend/app/Http/Controllers/Api/BookingMobilTrackingController.php`
- Import `BookingNotificationService`
- Mengirim notifikasi saat:
  - Auto-transition ke `menuju_penjemputan`
  - Driver memulai trip
  - Driver menyelesaikan trip

### 4. `backend/app/Http/Controllers/Api/BookingBarangTrackingController.php`
- Import `BookingNotificationService`
- Mengirim notifikasi saat:
  - Driver memulai perjalanan ke tujuan (`menuju_tujuan`)
  - Driver menyelesaikan pengiriman (`selesai`)

### 5. `backend/app/Http/Controllers/Api/BookingMobilLocationController.php`
- Import `BookingNotificationService`
- Mengirim notifikasi otomatis saat:
  - Status berubah dari `paid`/`confirmed` ke `menuju_penjemputan` (driver mulai bergerak)
  - Driver tiba di lokasi penjemputan (`sudah_di_penjemputan`, dalam radius 10m)
  - Driver mulai perjalanan (`sedang_dalam_perjalanan`, >100m dari pickup)

## Cara Kerja

1. **Setiap kali status booking berubah**, controller memanggil:
   ```php
   BookingNotificationService::sendStatusNotification($booking, 'new_status');
   ```

2. **Service memeriksa**:
   - Apakah booking dan user valid
   - Apakah user memiliki FCM token
   - Status apa yang berubah

3. **Service membuat pesan** yang sesuai dengan status dan mengirimnya via FCM

4. **Data tambahan** dikirim bersama notifikasi:
   - `booking_id`
   - `booking_number`
   - `status`
   - `type: "booking_status_update"`

## Testing

### 1. Setelah Fix FCM Service Account (lihat FCM_FIX_GUIDE.md)

Pastikan service account key sudah valid dengan mengikuti panduan di [FCM_FIX_GUIDE.md](FCM_FIX_GUIDE.md)

### 2. Test Notifikasi

```bash
# Monitor log
tail -f backend/storage/logs/laravel.log | grep -i "notification\|fcm"

# Lakukan booking dan bayar
# Lakukan test status changes
```

**Cek log untuk:**
- `Booking status notification sent` → notifikasi terkirim
- `FCM v1 sent` → FCM berhasil mengirim
- `User has no FCM token` → user belum register token

### 3. Test Skenario

1. **Pembayaran berhasil** → notifikasi "Pembayaran Berhasil"
2. **Driver mulai perjalanan** → notifikasi "Driver Menuju Lokasi Penjemputan"
3. **Driver tiba** → notifikasi "Driver Sudah Tiba"
4. **Perjalanan dimulai** → notifikasi "Perjalanan Dimulai"
5. **Perjalanan selesai** → notifikasi "Perjalanan Selesai"

## Troubleshooting

### Notifikasi tidak muncul?

1. **Cek FCM token user di database:**
   ```sql
   SELECT id, name, fcm_token FROM users WHERE id = YOUR_USER_ID;
   ```
   Jika NULL, token belum terdaftar.

2. **Cek log Laravel:**
   ```bash
   tail -200 backend/storage/logs/laravel.log | grep -i "fcm\|notification"
   ```

3. **Verifikasi service account valid:**
   Ikuti validasi di [FCM_FIX_GUIDE.md](FCM_FIX_GUIDE.md)

4. **Restart workers setelah update:**
   ```bash
   php artisan queue:restart
   sudo systemctl restart php8.1-fpm
   ```

### Notifikasi hanya muncul kadang-kadang?

- **Root cause:** Service account key invalid/revoked
- **Solution:** Download service account baru dari Firebase Console

### User tidak menerima notifikasi di device?

- Pastikan app memiliki permission notifikasi
- Cek `flutter logs` atau `adb logcat` untuk error
- Pastikan `API_BASE_URL` benar (tidak `10.0.2.2` pada device fisik)

## Format Pesan Notifikasi

Semua notifikasi memiliki format:
- **Title**: Deskripsi singkat status (contoh: "Driver Sudah Tiba! 📍")
- **Body**: Penjelasan lengkap dengan nama user dan booking number
- **Data payload**:
  ```json
  {
    "booking_id": "123",
    "booking_number": "FR-1769849108-100",
    "status": "sudah_di_penjemputan",
    "type": "booking_status_update"
  }
  ```

## Ekstensibilitas

Untuk menambahkan status baru:

1. Edit `BookingNotificationService::getNotificationContent()`
2. Tambahkan case baru di switch statement
3. Tentukan title dan body yang sesuai
4. Deploy dan test

## Referensi

- [FCM Fix Guide](FCM_FIX_GUIDE.md) - Cara memperbaiki masalah FCM service account
- [PaymentService.php](app/Services/PaymentService.php) - Implementasi notifikasi payment
- [BookingTrackingController.php](app/Http/Controllers/Api/BookingTrackingController.php) - Implementasi notifikasi tracking
