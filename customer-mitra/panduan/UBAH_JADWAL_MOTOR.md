# Ubah Jadwal Motor - Documentation

## Perubahan Backend

### 1. Fix Status Ride saat Reschedule
File yang diubah: `backend/app/Http/Controllers/Api/RescheduleController.php`

**Masalah:** Saat seat dikembalikan (naik dari 0 ke 2+), status ride tetap `inactive`  
**Solusi:** Tambahkan logic untuk update status berdasarkan `available_seats`:
- Jika `available_seats > 0` → status = `'active'`
- Jika `available_seats <= 0` → status = `'inactive'`

**Lokasi perubahan:**
- Method `confirmPayment()` - 3 tempat update seats
- Method `approve()` - 1 tempat update seats

```php
// Contoh implementasi:
$requestedTarget->available_seats = max(0, intval($requestedTarget->available_seats) - $diff);
$requestedTarget->status = intval($requestedTarget->available_seats) > 0 ? 'active' : 'inactive';
$requestedTarget->save();
```

## Perubahan Frontend

### 1. Support Motor di Halaman Ubah Jadwal
File yang diubah: `frontend/lib/screens/customer/ubah_jadwal/ubah_jadwal_page.dart`

**Perubahan:**
1. **Icon dinamis** - Menampilkan icon motor (two_wheeler) atau mobil (directions_car) sesuai booking_type
2. **Default vehicle** - Menggunakan "Motor Supra X" untuk motor, "Mobil Avanza" untuk mobil
3. **Title dinamis** - "Nebeng Motor" atau "Nebeng Mobil" sesuai booking_type

### 2. Halaman yang Sudah Mendukung Motor

Semua halaman ubah jadwal sudah support motor karena menggunakan `booking_type`:

1. **UbahJadwalPage** - Halaman input tanggal ubah jadwal
   - ✅ Icon motor/mobil
   - ✅ Info kendaraan motor
   - ✅ Tombol "Ubah Jadwal"

2. **UbahJadwalListPage** - List jadwal alternatif
   - ✅ Date selector
   - ✅ Card ride dengan detail lengkap
   - ✅ Button "Selengkapnya"

3. **UbahJadwalDetailPage** - Detail konfirmasi ubah jadwal
   - ✅ Info penumpang
   - ✅ Payment flow
   - ✅ Tombol konfirmasi

4. **Payment Pages** - Halaman pembayaran
   - ✅ Detail pembayaran
   - ✅ Virtual account
   - ✅ Success page

## Cara Menggunakan

### Dari Riwayat Booking (Customer)

1. Buka **Riwayat** page
2. Pilih booking motor yang ingin diubah
3. Tap tombol **"Ubah Jadwal"**
4. Pilih tanggal baru
5. Tap **"Ubah Jadwal"**
6. Pilih dari list jadwal yang tersedia
7. Tap **"Selengkapnya"** pada jadwal yang dipilih
8. Review detail dan konfirmasi
9. Lakukan pembayaran jika ada selisih harga

### API Flow

1. **GET** `/api/bookings/{id}/reschedule/available-rides?date=YYYY-MM-DD&booking_type=motor`
   - Mendapatkan list jadwal motor yang tersedia

2. **POST** `/api/bookings/{id}/reschedule`
   ```json
   {
     "requested_target_id": 5,
     "booking_type": "motor",
     "requested_target_type": "motor",
     "reason": "Ganti jadwal"
   }
   ```

3. **POST** `/api/reschedule/{requestId}/confirm-payment`
   ```json
   {
     "payment_txn_id": "payment_123"
   }
   ```

## Testing Checklist

- [ ] Booking motor dengan 2 seats, reschedule ke tanggal lain
- [ ] Verifikasi ride lama status jadi `active` (seats kembali)
- [ ] Verifikasi ride baru status jadi `inactive` jika seats habis
- [ ] Verifikasi icon motor muncul di halaman ubah jadwal
- [ ] Verifikasi info kendaraan motor ditampilkan dengan benar
- [ ] Verifikasi flow payment untuk reschedule motor
- [ ] Test reschedule dari motor ke motor lain di tanggal berbeda
- [ ] Test reschedule dari motor ke motor yang sama (should error)

## Screenshot Flow

Halaman-halaman sesuai dengan gambar yang diberikan:

1. **Halaman Kiri (ubah_jadwal_page.dart)**
   - Header: NEBENG + Kode Pemesanan
   - Card info booking motor dengan icon
   - Date picker
   - Button "Ubah Jadwal"

2. **Halaman Kanan (ubah_jadwal_list_page.dart)**
   - Header dengan origin → destination
   - Date selector horizontal
   - List card jadwal alternatif
   - Setiap card menampilkan:
     - Tanggal dan harga
     - Origin → Destination dengan alamat
     - Waktu perjalanan
     - Sisa kursi
     - Button "Selengkapnya"

## Notes

- Backend API sudah mendukung `booking_type: motor` di semua endpoint reschedule
- Frontend sudah handle conditional rendering untuk motor dan mobil
- Status ride akan otomatis update saat seats berubah
- Payment flow sama untuk motor dan mobil (selisih harga + admin fee)
