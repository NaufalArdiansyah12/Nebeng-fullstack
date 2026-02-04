# 📱 Integrasi Tarik Saldo di Flutter

## Cara Menggunakan

### 1. Import Dependencies
Pastikan dependencies berikut sudah ada di `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  intl: ^0.18.1
```

### 2. Navigasi ke Halaman Tarik Saldo

Dari halaman profil mitra atau menu, tambahkan navigasi:

```dart
// Contoh: Tambahkan di profil mitra
ListTile(
  leading: Icon(Icons.account_balance_wallet),
  title: Text('Tarik Saldo'),
  trailing: Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarikSaldoPage(),
      ),
    );
  },
)
```

### 3. Import File yang Diperlukan

```dart
import 'package:customer_mitra/screens/mitra/withdrawal/tarik_saldo_page.dart';
```

### 4. Struktur File

Pastikan struktur folder sebagai berikut:

```
lib/
├── models/
│   └── withdrawal_model.dart
├── services/
│   └── withdrawal_service.dart
└── screens/
    └── mitra/
        └── withdrawal/
            ├── tarik_saldo_page.dart
            ├── pin_verification_page.dart
            ├── withdrawal_progress_page.dart
            └── withdrawal_success_page.dart
```

## Flow Aplikasi

```
[Profil Mitra] 
    ↓ Tap "Tarik Saldo"
[TarikSaldoPage] - Input jumlah
    ↓ Tap "Lanjut"
[PinVerificationPage] - Input PIN 6 digit
    ↓ Submit (auto)
[WithdrawalProgressPage] - Lihat progress real-time
    ↓ Auto-navigate saat completed
[WithdrawalSuccessPage] - Konfirmasi berhasil
    ↓ Tap "Kembali"
[Home/Profil]
```

## API Configuration

Pastikan `ApiService.baseUrl` sudah dikonfigurasi dengan benar di `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Sesuaikan dengan server
}
```

## Testing di Flutter

### Prerequisite
1. Backend Laravel sudah running
2. Database sudah di-migrate dan seed
3. User mitra sudah login

### Test Case 1: Happy Path
```
1. Login sebagai mitra@example.com / password
2. Navigasi ke Tarik Saldo
3. Lihat saldo: Rp 200.000
4. Input jumlah: 50.000
5. Tap Lanjut
6. Input PIN: 123456
7. Tunggu progress (otomatis completed ~20 detik)
8. Lihat halaman success
```

### Test Case 2: Validasi Saldo
```
1. Login sebagai mitra
2. Input jumlah > saldo (contoh: 1.500.000)
3. Error: "Jumlah saldo tidak mencukupi"
```

### Test Case 3: PIN Salah
```
1. Login sebagai mitra
2. Input jumlah: 50.000
3. Input PIN salah: 999999
4. Error: "PIN yang Anda masukkan salah"
```

## Customization

### Mengubah Minimal Penarikan
Di `backend/app/Http/Controllers/Mitra/WithdrawalController.php`:
```php
$request->validate([
    'amount' => 'required|numeric|min:50000', // Ubah nilai min
]);
```

Di `lib/screens/mitra/withdrawal/tarik_saldo_page.dart`:
```dart
if (amount < 50000) {  // Ubah nilai minimal
  setState(() {
    _validationError = 'Minimal penarikan Rp 50.000';
  });
}
```

### Mengubah Warna Tema
Di setiap file page, ganti:
```dart
const Color(0xFF1E3A8A)  // Biru navy default
```

Dengan warna tema aplikasi Anda.

### Menambahkan Biaya Admin
Di `backend/app/Http/Controllers/Mitra/WithdrawalController.php`:
```php
// Calculate admin fee
$adminFee = $request->amount * 0.01; // 1% fee
$totalAmount = $request->amount - $adminFee;
```

## Troubleshooting

### Error: Unable to load balance info
**Cause:** Backend tidak running atau URL salah  
**Solution:** 
```bash
cd backend
php artisan serve
```

### Error: Token tidak ditemukan
**Cause:** User belum login  
**Solution:** Pastikan proses login berhasil dan token tersimpan di SharedPreferences

### Error: Bank tidak terverifikasi
**Cause:** User belum verifikasi bank  
**Solution:** 
```bash
cd backend
php artisan db:seed --class=WithdrawalSeeder
```

### Progress tidak update
**Cause:** Timer tidak berjalan  
**Solution:** Pastikan `withdrawal_progress_page.dart` me-mount dengan benar

## Production Checklist

- [ ] Update `ApiService.baseUrl` ke production URL
- [ ] Implementasi proper error handling
- [ ] Tambahkan loading indicators
- [ ] Implementasi retry mechanism
- [ ] Tambahkan analytics tracking
- [ ] Test di berbagai ukuran layar
- [ ] Test koneksi internet lambat
- [ ] Test dengan real bank integration
- [ ] Implementasi notification untuk setiap tahapan
- [ ] Tambahkan terms & conditions

## Support

Jika ada pertanyaan atau issue:
1. Cek dokumentasi di `backend/panduan/TARIK_SALDO_MITRA.md`
2. Test API menggunakan `backend/test_withdrawal.sh`
3. Cek logs di `backend/storage/logs/laravel.log`
