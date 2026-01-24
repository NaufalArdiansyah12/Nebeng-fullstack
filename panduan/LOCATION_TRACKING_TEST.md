# Location Tracking - Testing Guide

## 🎯 Fitur yang Diimplementasikan

### Mitra Side (Driver)
✅ Auto tracking lokasi saat status in_progress/active/paid/confirmed
✅ Interval dinamis: 5 detik (bergerak), 1 menit (diam)
✅ Deteksi pergerakan: >1 meter atau speed >0.1 m/s
✅ Kirim lokasi ke API: POST /api/v1/bookings/{id}/location
✅ Update database: last_lat, last_lng, last_location_at
✅ Visual indicator dengan status real-time

### Customer Side
✅ Polling lokasi dari database dengan interval dinamis
✅ Interval: 5 detik (driver bergerak), 1 menit (driver diam)
✅ Deteksi pergerakan: >10 meter atau speed >1.0 m/s
✅ Tampilan map dengan marker driver
✅ Visual indicator status driver

## 🧪 Cara Testing di Emulator

### 1. Setup Awal
```bash
# Terminal 1 - Backend
cd backend
php artisan serve

# Terminal 2 - Frontend
cd frontend
flutter run
```

### 2. Test Flow Lengkap

#### A. Login sebagai Mitra
1. Buka aplikasi di emulator
2. Login sebagai mitra (driver_id = 2)
3. Buka halaman "Tebengan Saya"
4. Pilih booking dengan status "in_progress" atau "paid"

#### B. Monitoring di Mitra Side
5. Lihat indicator tracking:
   - 🧍 DIAM (orange) = update 1 menit
   - 🏃 BERGERAK (green) = update 5 detik
6. Perhatikan log di terminal:
   ```
   📍 First position captured - setting to STATIONARY
   🚗 Movement check - Distance: X.XXm, Speed: X.XXm/s, IsMoving: true/false
   ✅ Lokasi terkirim ke database: -7.xxx, 110.xxx (BERGERAK/DIAM)
   ```

#### C. Simulasi Pergerakan
7. Di emulator, klik ⋮ (More) > Location
8. Ubah GPS coordinates:
   - Dari: -7.6333606, 110.7122182
   - Ke: -7.6333700, 110.7122300 (perubahan ~11 meter)
9. Klik "Send"
10. Tunggu 5 detik, cek indicator berubah ke 🏃 BERGERAK

#### D. Verifikasi Database
11. Buka database (phpMyAdmin atau CLI)
```sql
SELECT id, last_lat, last_lng, last_location_at, status 
FROM booking_motor 
WHERE id = 2 
ORDER BY last_location_at DESC;
```
12. Cek apakah last_lat dan last_lng ter-update sesuai GPS baru

#### E. Test di Customer Side
13. Login sebagai customer (user yang booking)
14. Buka "Riwayat Perjalanan"
15. Pilih booking yang sama (id = 2)
16. Lihat map menampilkan lokasi driver
17. Perhatikan indicator:
    - "Update: 5 detik" (driver bergerak)
    - "Update: 1 menit" (driver diam)

## 📊 Expected Results

### Mitra Side Logs
```
✅ Status valid, starting tracking...
📍 Getting current position...
📍 Position: -7.6333606, 110.7122182
📍 First position captured - setting to STATIONARY
✅ Method 1: Found booking ID from widget.item[id]: 1
🚀 Sending location to server - BookingID: 1
✅ Lokasi terkirim ke database: -7.6333606, 110.7122182 (DIAM)
```

Setelah ubah lokasi:
```
📍 Getting current position...
📍 Position: -7.6333700, 110.7122300
🚗 Movement check - Distance: 11.23m, Speed: 0.00m/s, IsMoving: true
🔄 Movement status changed: MOVING ✅
✅ Lokasi terkirim ke database: -7.6333700, 110.7122300 (BERGERAK)
```

### Database Result
```
id | last_lat    | last_lng     | last_location_at        | status
2  | -7.6333700  | 110.7122300  | 2026-01-24 08:35:42    | in_progress
```

### Customer Side
- Map menampilkan marker di koordinat terbaru
- Indicator menunjukkan "🟢 Driver bergerak - Update: 5 detik"
- Polling interval berubah otomatis sesuai status driver

## 🐛 Troubleshooting

### Masalah: Indicator tidak berubah
**Solusi**: 
- Pastikan perubahan GPS >1 meter
- Cek log "Movement check" muncul
- Verifikasi setState() dipanggil

### Masalah: Lokasi tidak tersimpan di database
**Solusi**:
- Cek log "✅ Lokasi terkirim ke database"
- Verifikasi booking ID ditemukan
- Cek API token valid
- Pastikan backend running

### Masalah: Customer tidak melihat update
**Solusi**:
- Pastikan status booking = in_progress
- Cek polling interval di log customer
- Verifikasi API tracking endpoint: GET /api/v1/bookings/{id}/tracking

## 🎉 Success Criteria

✅ Mitra: Lokasi tersimpan ke database setiap 5 detik (bergerak) / 1 menit (diam)
✅ Mitra: Indicator UI berubah sesuai status pergerakan
✅ Database: Kolom last_lat, last_lng, last_location_at ter-update real-time
✅ Customer: Melihat lokasi driver ter-update di map
✅ Customer: Polling interval berubah dinamis (5 detik/1 menit)
✅ Backend: Log tracking updates di laravel.log

## 📝 Notes

- Threshold emulator: 1 meter (lebih sensitif untuk testing)
- Threshold production: bisa dinaikan ke 10 meter untuk akurasi lebih baik
- Speed threshold: 0.1 m/s (emulator), bisa dinaikan ke 1.0 m/s (production)
- Customer threshold lebih tinggi (10m, 1.0m/s) untuk menghindari false positive
