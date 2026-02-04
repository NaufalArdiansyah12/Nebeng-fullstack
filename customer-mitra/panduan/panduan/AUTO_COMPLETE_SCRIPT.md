# Script Auto Complete Trips & Update Balance

## Deskripsi
Script untuk melengkapi (complete) trip booking dan otomatis menambahkan saldo ke mitra.

## File Script

### 1. `auto_complete_trips.sh`
**Fungsi:** Auto-complete trips yang sudah lewat waktu keberangkatannya

**Cara Pakai:**
```bash
cd backend
./auto_complete_trips.sh
```

**Fitur:**
- ✅ Cek semua booking (motor, mobil, barang, titip barang)
- ✅ Complete booking yang departure time sudah lewat
- ✅ Update saldo driver dengan amount dari payment (tanpa admin fee)
- ✅ Tampilkan detail setiap booking yang di-complete
- ✅ Bisa dijadikan cron job untuk otomasi

**Contoh Output:**
```
=== Nebeng Motor ===
✓ Completed: FR-1770088919-190 (motor)
  Driver: Kamado Tanjiro
  Amount: Rp 30.000
  Balance: Rp 250.000 → Rp 280.000

========================================
Total completed: 1 bookings
========================================
```

### 2. `complete_all_bookings.sh`
**Fungsi:** Complete SEMUA pending bookings (untuk testing)

**Cara Pakai:**
```bash
cd backend
./complete_all_bookings.sh
# Ketik "yes" untuk konfirmasi
```

**Fitur:**
- ✅ Complete semua booking tanpa cek waktu
- ✅ Update saldo driver otomatis
- ✅ Konfirmasi sebelum eksekusi (safety)
- ✅ Cocok untuk testing/development

**PERHATIAN:** Script ini akan complete SEMUA pending bookings!

## Cara Kerja

### Flow Auto Complete:
1. **Cari Booking** yang statusnya belum completed/selesai
2. **Cek Payment** apakah sudah paid
3. **Dapatkan Driver** dari ride/tebengan
4. **Update Status** → completed/selesai
5. **Tambah Saldo** driver dengan `payment.amount` (bukan total_amount)
6. **Log Detail** untuk tracking

### Kolom yang Digunakan:
- `payment.amount` → Harga murni (Rp 30.000) ✅
- `payment.total_amount` → Harga + admin (Rp 45.000) ❌

## Setup Cron Job (Opsional)

Untuk auto-complete setiap jam:

```bash
# Edit crontab
crontab -e

# Tambahkan line ini:
0 * * * * cd /path/to/backend && ./auto_complete_trips.sh >> /path/to/logs/auto_complete.log 2>&1
```

Ini akan:
- Jalan setiap jam di menit ke-0
- Complete trips yang sudah lewat
- Log ke file

## Testing Manual

### Test Script:
```bash
cd backend

# Lihat balance sebelum
php artisan tinker --execute="\$m = User::where('role','mitra')->first(); echo \$m->balance;"

# Jalankan script
./complete_all_bookings.sh

# Lihat balance sesudah
php artisan tinker --execute="\$m = User::where('role','mitra')->first(); echo \$m->balance;"
```

### Test via Tinker:
```bash
php artisan tinker
```

```php
// Lihat pending bookings
$bookings = Booking::whereNotIn('status', ['completed', 'cancelled'])->get();

// Complete manual
$booking = Booking::first();
$payment = Payment::where('booking_number', $booking->booking_number)->first();
$driver = $booking->ride->user;
$driver->balance += $payment->amount;
$driver->save();
$booking->status = 'completed';
$booking->save();
```

## Troubleshooting

### Script tidak bisa dijalankan
```bash
chmod +x auto_complete_trips.sh
chmod +x complete_all_bookings.sh
```

### Balance tidak bertambah
Cek:
1. Apakah payment sudah status 'paid'?
2. Apakah booking punya booking_number?
3. Apakah ride punya user_id (driver)?

### Melihat Log
```bash
# Di script, semua sudah echo
# Atau tambahkan redirect ke file:
./auto_complete_trips.sh >> auto_complete.log 2>&1
```

## Integrasi dengan Aplikasi

Saat ini, saldo juga auto-update via:
1. ✅ API endpoint `completeTrip` (dari aplikasi mobile)
2. ✅ Script manual (untuk testing/maintenance)

Jadi bisa dipilih mana yang cocok untuk use case Anda!
