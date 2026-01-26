# Dokumentasi Fitur Tracking Backend & Frontend

## Backend Changes

### 1. BookingController.php
**File:** `/backend/app/Http/Controllers/Api/BookingController.php`

**Method Baru:**
- `show($id)` - Mendapatkan detail booking dengan informasi tracking status
  - Response includes: tracking_status, countdown, last_location
  - Status: scheduled, waiting, in_progress, completed, cancelled

- `updateStatus($id)` - Update status booking
  - Allowed statuses: pending, paid, confirmed, in_progress, completed, cancelled
  - Dapat diakses oleh customer atau driver

### 2. BookingLocationController.php
**File:** `/backend/app/Http/Controllers/Api/BookingLocationController.php`

**Perubahan:**
- Auto-update status dari 'paid'/'confirmed' ke 'in_progress' saat driver mulai bergerak
- Log tambahan untuk tracking status changes

### 3. BookingTrackingController.php (BARU)
**File:** `/backend/app/Http/Controllers/Api/BookingTrackingController.php`

**Endpoints:**
- `GET /api/v1/bookings/{id}/tracking` - Comprehensive tracking info
  - Location data (lat, lng, timestamp)
  - Ride information (origin, destination, times)
  - Driver information (name, phone, photo, rating)
  - Vehicle information (type, brand, model, plate)
  - Tracking status dengan countdown timer
  - Waiting duration

- `POST /api/v1/bookings/{id}/start-trip` - Driver marks trip as started
  - Updates status to 'in_progress'
  - Records trip_started_at timestamp

- `POST /api/v1/bookings/{id}/complete-trip` - Driver marks trip as completed
  - Updates status to 'completed'
  - Records trip_completed_at timestamp

### 4. Routes (api.php)
**File:** `/backend/routes/api.php`

**Routes Baru:**
```php
Route::put('/bookings/{id}/status', [BookingController::class, 'updateStatus']);
Route::get('/bookings/{id}/tracking', [BookingTrackingController::class, 'show']);
Route::post('/bookings/{id}/start-trip', [BookingTrackingController::class, 'startTrip']);
Route::post('/bookings/{id}/complete-trip', [BookingTrackingController::class, 'completeTrip']);
```

## Frontend Changes

### 1. CustomerBookingDetailPage
**File:** `/frontend/lib/screens/customer/booking_detail_page.dart`

**Features:**
- Dynamic UI berdasarkan status booking:
  - **Waiting**: Countdown timer, jadwal keberangkatan, info mitra lengkap
  - **In Progress**: Progress indicator, info driver & kendaraan, rute perjalanan
  - **Completed**: Icon check, perjalanan selesai
  - **Cancelled**: Icon cancel, pesanan dibatalkan

- Auto countdown timer yang update setiap detik
- Deteksi otomatis status berdasarkan waktu keberangkatan
- Tombol batalkan pesanan dengan konfirmasi
- Integrasi dengan API untuk update status

### 2. ApiService
**File:** `/frontend/lib/services/api_service.dart`

**Methods Baru:**
```dart
// Update booking status
Future<Map<String, dynamic>> updateBookingStatus({
  required int bookingId,
  required String status,
  required String token,
})

// Send driver location update
Future<bool> updateBookingLocation({
  required int bookingId,
  required String token,
  required double lat,
  required double lng,
  DateTime? timestamp,
  double? accuracy,
  double? speed,
})

// Get comprehensive tracking info
Future<Map<String, dynamic>> getBookingTracking({
  required int bookingId,
  required String token,
})

// Driver start trip
Future<Map<String, dynamic>> startTrip({
  required int bookingId,
  required String token,
})

// Driver complete trip
Future<Map<String, dynamic>> completeTrip({
  required int bookingId,
  required String token,
})
```

## Tracking Status Flow

```
pending -> paid -> confirmed -> in_progress -> completed
                               └─> cancelled
```

### Status Descriptions:
1. **pending**: Booking dibuat, belum dibayar
2. **paid**: Pembayaran berhasil
3. **confirmed**: Booking dikonfirmasi driver
4. **in_progress**: Perjalanan sedang berlangsung
5. **completed**: Perjalanan selesai
6. **cancelled**: Booking dibatalkan

## Tracking Status Determination (Auto):
- **scheduled**: Waktu keberangkatan > 1 jam
- **waiting**: Waktu keberangkatan <= 1 jam (countdown aktif)
- **in_progress**: Waktu keberangkatan sudah lewat
- **completed**: Status booking = 'completed'
- **cancelled**: Status booking = 'cancelled'

## Usage Example

### Frontend - Update Status
```dart
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('api_token');

await ApiService.updateBookingStatus(
  bookingId: bookingId,
  status: 'cancelled',
  token: token!,
);
```

### Frontend - Get Tracking Info
```dart
final trackingData = await ApiService.getBookingTracking(
  bookingId: bookingId,
  token: token!,
);

// Access data
final location = trackingData['location']; // {lat, lng, timestamp}
final driver = trackingData['driver']; // {name, phone, photo}
final status = trackingData['tracking_status']; // scheduled, waiting, in_progress
final countdown = trackingData['countdown']; // {days, hours, minutes}
```

### Driver - Start/Complete Trip
```dart
// Start trip
await ApiService.startTrip(bookingId: bookingId, token: driverToken);

// Complete trip
await ApiService.completeTrip(bookingId: bookingId, token: driverToken);
```

### Driver - Update Location
```dart
await ApiService.updateBookingLocation(
  bookingId: bookingId,
  token: driverToken,
  lat: currentLat,
  lng: currentLng,
  accuracy: locationAccuracy,
  speed: currentSpeed,
);
```

## Security
- Semua endpoint memerlukan Bearer token authentication
- Driver hanya bisa update booking miliknya
- Customer hanya bisa melihat booking miliknya
- Validasi permission di setiap endpoint

## Database Fields Used
- `status`: Status booking
- `last_lat`, `last_lng`: Lokasi terakhir driver
- `last_location_at`: Timestamp lokasi terakhir
- `trip_started_at`: Waktu mulai perjalanan
- `trip_completed_at`: Waktu selesai perjalanan
- `waiting_start_at`: Waktu mulai menunggu di pickup point

## Testing
1. Test update status booking
2. Test countdown timer di UI
3. Test pembatalan booking
4. Test tracking location updates
5. Test start/complete trip
6. Test tampilan UI untuk setiap status
