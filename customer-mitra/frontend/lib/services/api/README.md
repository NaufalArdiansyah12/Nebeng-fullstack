# API Services - Struktur Modular

Folder `services/api` berisi semua service untuk komunikasi dengan backend API.

## 📁 Struktur File

```
lib/services/
├── api/                         # Folder API services
│   ├── api_config.dart          # Konfigurasi base URL
│   ├── auth_service.dart        # Autentikasi & PIN
│   ├── profile_service.dart     # Manajemen profil user
│   ├── ride_service.dart        # Operasi ride/tebengan
│   ├── booking_service.dart     # Operasi booking
│   ├── vehicle_service.dart     # Manajemen kendaraan
│   ├── reward_service.dart      # Rewards & redemption
│   ├── location_service.dart    # Lokasi & tracking
│   ├── rating_service.dart      # Rating & review
│   ├── verification_service.dart # Verifikasi dokumen mitra
│   ├── reschedule_service.dart  # Reschedule booking
│   └── README.md                # Dokumentasi ini
├── api_service.dart             # Wrapper (backward compatibility)
├── payment_service.dart         # Service pembayaran
├── chat_service.dart            # Service chat
├── notification_service.dart    # Service notifikasi
└── verifikasi_service.dart      # Service verifikasi lama
```

## 📚 Deskripsi Setiap Service

### 1. **api_config.dart**
Base configuration untuk API.
- `ApiConfig.baseUrl` - Auto-detect platform (web/android/ios)

### 2. **auth_service.dart**
Autentikasi dan manajemen PIN.
- `login()` - Login dengan email/password
- `logout()` - Logout user
- `checkPin()` - Cek apakah user punya PIN
- `createPin()` - Buat PIN baru
- `verifyPin()` - Verifikasi PIN

### 3. **profile_service.dart**
Manajemen profil user.
- `getProfile()` - Get user profile
- `getUserById()` - Get user by ID
- `updateProfile()` - Update profile
- `uploadProfilePhoto()` - Upload foto profil
- `changePassword()` - Ubah password

### 4. **ride_service.dart**
Operasi ride/tebengan.
- `fetchRides()` - Fetch available rides
- `fetchMitraHistory()` - History ride mitra
- `createRide()` - Buat ride baru
- `getRidePassengers()` - Get daftar penumpang
- `fetchAvailableRides()` - Fetch rides untuk reschedule
- `startTrip()` - Mulai perjalanan
- `completeTrip()` - Selesaikan perjalanan

### 5. **booking_service.dart**
Operasi booking.
- `createBooking()` - Buat booking
- `fetchBookings()` - Fetch booking list
- `fetchBooking()` - Get booking detail
- `updateBookingStatus()` - Update status booking
- `cancelBooking()` - Cancel booking
- `getCancellationCount()` - Get jumlah pembatalan
- `getBookingTracking()` - Get tracking info

### 6. **vehicle_service.dart**
Manajemen kendaraan mitra.
- `fetchVehicles()` - Fetch kendaraan user
- `createVehicle()` - Tambah kendaraan baru
- `deleteVehicle()` - Hapus kendaraan

### 7. **payment_service.dart**
Pembayaran dan transaksi.
- `createPayment()` - Buat pembayaran
- `fetchTransactionHistory()` - History transaksi
- `checkRefundEligibility()` - Cek kelayakan refund
- `submitRefund()` - Submit refund request
- `getRefundHistory()` - History refund
- `getRefundDetail()` - Detail refund
- `confirmReschedulePayment()` - Konfirmasi pembayaran reschedule

### 8. **reward_service.dart**
Rewards dan redemption.
- `fetchRewards()` - Fetch available rewards
- `redeemReward()` - Redeem reward
- `fetchMyRedemptions()` - History redemption

### 9. **location_service.dart**
Lokasi dan tracking.
- `fetchLocations()` - Fetch master locations
- `reportMitraLocation()` - Report lokasi mitra
- `updateBookingLocation()` - Update lokasi saat trip
- `fetchBookingLocation()` - Get lokasi booking

### 10. **rating_service.dart**
Rating dan review.
- `submitRating()` - Submit rating
- `getRating()` - Get rating booking
- `getDriverRatings()` - Get semua rating driver

### 11. **verification_service.dart**
Verifikasi dokumen mitra.
- `submitKtpVerification()` - Submit verifikasi KTP
- `submitSimVerification()` - Submit verifikasi SIM
- `submitSkckVerification()` - Submit verifikasi SKCK
- `submitBankVerification()` - Submit verifikasi Bank
- `linkMitraVerifications()` - Link semua verifikasi
- `getMitraVerificationStatus()` - Get status verifikasi

### 12. **reschedule_service.dart**
Reschedule booking.
- `createReschedule()` - Buat request reschedule

## 🔧 Cara Menggunakan

### Import Melalui ApiService (Recommended)
```dart
import 'package:frontend/services/api_service.dart';

// Langsung gunakan service
final result = await AuthService.login(email, password);
final rides = await RideService.fetchRides();
```

### Import Service Langsung dari Folder api
```dart
import 'package:frontend/services/api/auth_service.dart';
import 'package:frontend/services/api/ride_service.dart';

final result = await AuthService.login(email, password);
final rides = await RideService.fetchRides();
```

### Contoh Penggunaan
```dart
// Login
try {
  final result = await AuthService.login('user@example.com', 'password');
  final token = result['token'];
  final user = result['user'];
} catch (e) {
  print('Login error: $e');
}

// Fetch Rides
try {
  final rides = await RideService.fetchRides(
    originLocationId: 1,
    destinationLocationId: 2,
    date: '2026-01-30',
  );
  print('Found ${rides.length} rides');
} catch (e) {
  print('Error: $e');
}

// Create Booking
try {
  final booking = await BookingService.createBooking(
    rideId: 123,
    userId: 456,
    seats: 2,
    bookingNumber: 'BK-001',
  );
  print('Booking created: ${booking['id']}');
} catch (e) {
  print('Error: $e');
}
```

## ⚠️ Breaking Changes

### Before (Old Structure)
```dart
import 'package:frontend/services/api_service.dart';

final result = await ApiService.login(email, password);
final rides = await ApiService.fetchRides();
```

### After (New Structure)
```dart
import 'package:frontend/services/api_service.dart';

final result = await AuthService.login(email, password);
final rides = await RideService.fetchRides();
```

## 🔄 Migration Guide

1. **Update Imports**: Ganti `ApiService` dengan service spesifik
2. **Update Method Calls**: Ganti `ApiService.methodName()` dengan `SpecificService.methodName()`
3. **Test**: Pastikan semua fungsi masih bekerja dengan baik

## 📝 Notes

- File `api_service_old.dart` adalah backup dari file lama (bisa dihapus setelah migrasi selesai)
- Semua service menggunakan `ApiConfig.baseUrl` untuk base URL
- Setiap service fokus pada satu domain/fitur tertentu
- Lebih mudah untuk maintenance dan testing
