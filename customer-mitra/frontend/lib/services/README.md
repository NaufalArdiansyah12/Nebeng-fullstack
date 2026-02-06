# Services Directory

Direktori ini berisi semua service API yang digunakan dalam aplikasi, diorganisir berdasarkan kategori pengguna dan fitur.

## Struktur Folder

```
services/
├── customer/          # API services khusus untuk Customer
├── mitra/            # API services khusus untuk Mitra
├── posmitra/         # API services khusus untuk PosMitra
├── shared/           # API services yang digunakan bersama
├── api_service.dart  # Legacy service wrapper (akan di-deprecate)
└── api_service_old.dart  # Old version backup
```

## Kategori Services

### 🛒 Customer Services (`/customer`)
Services yang digunakan oleh pengguna customer/penumpang:

- **booking_service.dart** - Booking perjalanan (mobil, motor, barang)
- **credit_service.dart** - Manajemen kredit customer
- **payment_service.dart** - Pembayaran booking
- **rating_service.dart** - Rating dan review untuk driver
- **reschedule_service.dart** - Reschedule booking yang sudah ada
- **reward_service.dart** - Reward points dan redeem
- **saved_passenger_service.dart** - Penumpang tersimpan (untuk booking cepat)

**Import:**
```dart
import 'package:frontend/services/customer/booking_service.dart';
// atau gunakan barrel export:
import 'package:frontend/services/customer/customer_services.dart';
```

### 🚗 Mitra Services (`/mitra`)
Services yang digunakan oleh mitra/driver:

- **ride_service.dart** - Membuat dan manajemen perjalanan/ride
- **vehicle_service.dart** - Manajemen kendaraan mitra
- **verifikasi_service.dart** - Verifikasi dokumen mitra (KTP, SIM, STNK)
- **withdrawal_service.dart** - Penarikan saldo mitra ke rekening

**Import:**
```dart
import 'package:frontend/services/mitra/withdrawal_service.dart';
// atau gunakan barrel export:
import 'package:frontend/services/mitra/mitra_services.dart';
```

### 🏪 PosMitra Services (`/posmitra`)
Services yang digunakan oleh PosMitra:

- **posmitra_service.dart** - Dashboard, transaksi, topup, dan semua operasi PosMitra

**Import:**
```dart
import 'package:frontend/services/posmitra/posmitra_service.dart';
// atau gunakan barrel export:
import 'package:frontend/services/posmitra/posmitra_services.dart';
```

### 🔄 Shared Services (`/shared`)
Services yang digunakan bersama oleh semua role (Customer, Mitra, PosMitra):

- **api_config.dart** - Konfigurasi base URL dan environment
- **auth_service.dart** - Autentikasi (login, register, logout)
- **chat_service.dart** - Fitur chat/messaging
- **location_service.dart** - Location tracking dan maps
- **notification_api_service.dart** - API untuk notifikasi
- **notification_service.dart** - Local notification handling
- **phone_verification_service.dart** - Verifikasi nomor telepon (OTP)
- **profile_service.dart** - Manajemen profil user
- **verification_service.dart** - Verifikasi umum

**Import:**
```dart
import 'package:frontend/services/shared/auth_service.dart';
// atau gunakan barrel export:
import 'package:frontend/services/shared/shared_services.dart';
```

## Best Practices

### 1. Import Service
Gunakan relative path atau package import:

```dart
// Relative import (jika dalam folder yang sama)
import '../shared/api_config.dart';

// Package import (recommended untuk clean code)
import 'package:frontend/services/customer/booking_service.dart';

// Barrel exports (untuk import multiple services)
import 'package:frontend/services/customer/customer_services.dart';
```

### 2. Error Handling
Semua service sudah memiliki error handling built-in:

```dart
try {
  final result = await BookingService.createBooking(
    rideId: rideId,
    userId: userId,
    seats: seats,
    bookingNumber: bookingNumber,
  );
  // Handle success
} catch (e) {
  // Handle error - error sudah di-throw dari service
  print('Error: $e');
}
```

### 3. Authentication
Services yang memerlukan autentikasi biasanya memerlukan token:

```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('api_token');

if (token != null) {
  final vehicles = await VehicleService.fetchVehicles(token: token);
}
```

## Migration Notes

Jika Anda memiliki kode lama yang menggunakan path `services/api/`, update import Anda:

**Sebelum:**
```dart
import '../../../services/api/booking_service.dart';
import '../../../services/api/vehicle_service.dart';
import '../../../services/payment_service.dart';
```

**Sesudah:**
```dart
import '../../../services/customer/booking_service.dart';
import '../../../services/mitra/vehicle_service.dart';
import '../../../services/customer/payment_service.dart';
```

## Testing

Untuk testing service, gunakan mock atau stub:

```bash
flutter test test/services/
```

## Environment Configuration

Base URL dikonfigurasi di `shared/api_config.dart`:
- Development: http://localhost:8000 (atau 10.0.2.2 untuk Android emulator)
- Production: https://api.nebeng.app

## Contact

Jika ada pertanyaan atau issue terkait services, hubungi tim backend atau buat issue di repository.
