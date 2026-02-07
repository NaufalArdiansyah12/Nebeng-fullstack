# Backend Notifikasi Mitra

Dokumentasi sistem notifikasi untuk Mitra di backend Laravel.

## Overview

Sistem notifikasi mitra mengintegrasikan:
1. **Database Storage** - Notifikasi disimpan di tabel `notifications`
2. **FCM Push Notifications** - Real-time push via Firebase Cloud Messaging
3. **REST API** - Endpoint untuk fetch, mark as read, delete notifikasi

## Services

### MitraNotificationService

Service untuk mengirim berbagai jenis notifikasi ke mitra.

**Location**: `app/Services/MitraNotificationService.php`

#### Methods:

##### 1. Vehicle Notifications

```php
// Kirim notifikasi saat kendaraan disetujui
MitraNotificationService::sendVehicleApprovedNotification($vehicle);

// Kirim notifikasi saat kendaraan ditolak
MitraNotificationService::sendVehicleRejectedNotification($vehicle, $rejectionReason);
```

##### 2. Withdrawal Notifications

```php
// Kirim notifikasi saat penarikan berhasil
MitraNotificationService::sendWithdrawalSuccessNotification($withdrawal);

// Kirim notifikasi saat penarikan gagal
MitraNotificationService::sendWithdrawalFailedNotification($withdrawal, $failureReason);
```

##### 3. Booking Notifications

```php
// Kirim notifikasi booking baru
MitraNotificationService::sendNewBookingNotification($booking, $driver);

// Kirim notifikasi booking dibatalkan
MitraNotificationService::sendBookingCancelledNotification($booking, $driver);

// Kirim notifikasi booking selesai
MitraNotificationService::sendBookingCompletedNotification($booking, $driver, $earnings);
```

##### 4. Payment & Rating Notifications

```php
// Kirim notifikasi pembayaran diterima
MitraNotificationService::sendPaymentReceivedNotification($booking, $driver, $amount);

// Kirim notifikasi rating diterima
MitraNotificationService::sendRatingReceivedNotification($rating, $driver);
```

##### 5. General Notifications

```php
// Kirim pengumuman ke mitra
MitraNotificationService::sendAnnouncementToMitra($mitraUser, $title, $body, $icon, $extraData);

// Kirim promo ke mitra
MitraNotificationService::sendPromoToMitra($mitraUser, $title, $body, $extraData);
```

## Controllers

### 1. NotificationController

**Location**: `app/Http/Controllers/Api/NotificationController.php`

Handles notifikasi untuk customer DAN mitra (shared).

#### Endpoints:

```
GET    /api/v1/notifications              - Get all notifications (paginated)
GET    /api/v1/notifications/unread-count - Get unread notification count
POST   /api/v1/notifications/{id}/read    - Mark notification as read
POST   /api/v1/notifications/read-all     - Mark all notifications as read
DELETE /api/v1/notifications/{id}         - Delete notification
DELETE /api/v1/notifications/clear-read   - Clear all read notifications
```

### 2. VehicleController

**Location**: `app/Http/Controllers/Api/VehicleController.php`

Mengirim notifikasi saat approve/reject kendaraan.

#### Trigger Points:

```php
// Saat approve vehicle
public function approve(Request $request, $id) {
    $vehicle->update(['status' => 'approved', ...]);
    
    // Kirim notifikasi
    $vehicle->load('user');
    MitraNotificationService::sendVehicleApprovedNotification($vehicle);
}

// Saat reject vehicle
public function reject(Request $request, $id) {
    $vehicle->update(['status' => 'rejected', ...]);
    
    // Kirim notifikasi
    $vehicle->load('user');
    MitraNotificationService::sendVehicleRejectedNotification(
        $vehicle, 
        $request->rejection_reason
    );
}
```

### 3. WithdrawalAdminController

**Location**: `app/Http/Controllers/Api/WithdrawalAdminController.php`

Admin controller untuk approve/reject withdrawal dengan notifikasi.

#### Endpoints:

```
GET  /api/v1/admin/withdrawals               - Get all withdrawal requests
POST /api/v1/admin/withdrawals/{id}/approve  - Approve withdrawal
POST /api/v1/admin/withdrawals/{id}/complete - Complete withdrawal
POST /api/v1/admin/withdrawals/{id}/reject   - Reject withdrawal
```

#### Usage:

```php
// Approve withdrawal
public function approve(Request $request, $id) {
    $withdrawal->update(['status' => 'processing', ...]);
    
    // Kirim notifikasi sukses
    MitraNotificationService::sendWithdrawalSuccessNotification($withdrawal);
}

// Reject withdrawal
public function reject(Request $request, $id) {
    $withdrawal->update(['status' => 'rejected', ...]);
    $user->increment('balance', $withdrawal->amount); // Refund
    
    // Kirim notifikasi gagal
    MitraNotificationService::sendWithdrawalFailedNotification(
        $withdrawal, 
        $request->rejection_reason
    );
}
```

### 4. BookingNotificationService

**Location**: `app/Services/BookingNotificationService.php`

Enhanced dengan methods untuk notifikasi ke driver.

#### New Methods:

```php
// Kirim notifikasi booking baru ke driver
BookingNotificationService::sendNewBookingToDriver($booking);

// Kirim notifikasi payment received
BookingNotificationService::sendPaymentReceivedToDriver($booking, $driverEarnings);

// Kirim notifikasi booking cancelled
BookingNotificationService::sendBookingCancelledToDriver($booking);

// Kirim notifikasi booking completed
BookingNotificationService::sendBookingCompletedToDriver($booking, $earnings);
```

## Database Schema

### notifications table

```sql
CREATE TABLE notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    type VARCHAR(255) DEFAULT 'booking_status_update',
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    icon VARCHAR(255) NULL,
    booking_id BIGINT NULL,
    booking_number VARCHAR(255) NULL,
    status VARCHAR(255) NULL,
    data JSON NULL,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, is_read),
    INDEX idx_created_at (created_at)
);
```

## Notification Types

### Mitra Notification Types:

- `vehicle_approved` - Kendaraan disetujui
- `vehicle_rejected` - Kendaraan ditolak
- `withdrawal_success` - Penarikan berhasil
- `withdrawal_failed` - Penarikan gagal
- `new_booking` - Booking baru
- `booking_cancelled` - Booking dibatalkan
- `booking_completed` - Booking selesai
- `rating_received` - Rating diterima
- `payment_received` - Pembayaran diterima
- `announcement` - Pengumuman
- `promo` - Promo

## Integration Examples

### 1. Saat Booking Baru Dibuat

```php
// Di BookingController atau setelah booking created
use App\Services\BookingNotificationService;

$booking = Booking::create([...]);

// Kirim ke customer (existing)
BookingNotificationService::sendStatusNotification($booking, 'pending');

// Kirim ke driver/mitra (NEW)
BookingNotificationService::sendNewBookingToDriver($booking);
```

### 2. Saat Booking Selesai

```php
// Di BookingController saat status = 'completed'
$booking->update(['status' => 'completed']);

// Calculate earnings
$driverEarnings = $booking->price * 0.8; // 80% for driver

// Kirim ke customer
BookingNotificationService::sendStatusNotification($booking, 'completed');

// Kirim ke driver
BookingNotificationService::sendBookingCompletedToDriver($booking, $driverEarnings);
```

### 3. Saat Admin Approve Vehicle

```php
// Sudah otomatis di VehicleController::approve()
// Tidak perlu tambahan code
```

### 4. Saat Rating Diberikan

```php
// Di RatingController setelah rating created
use App\Services\MitraNotificationService;

$rating = Rating::create([
    'user_id' => $customer->id,
    'driver_id' => $driver->id,
    'booking_id' => $booking->id,
    'rating' => $request->rating,
    'review' => $request->review,
]);

// Kirim notifikasi ke driver
MitraNotificationService::sendRatingReceivedNotification($rating, $driver);
```

## Testing

### Manual Testing via API

```bash
# 1. Get notifications
curl -X GET http://localhost:8000/api/v1/notifications \
  -H "Authorization: Bearer YOUR_TOKEN"

# 2. Get unread count
curl -X GET http://localhost:8000/api/v1/notifications/unread-count \
  -H "Authorization: Bearer YOUR_TOKEN"

# 3. Mark as read
curl -X POST http://localhost:8000/api/v1/notifications/123/read \
  -H "Authorization: Bearer YOUR_TOKEN"

# 4. Mark all as read
curl -X POST http://localhost:8000/api/v1/notifications/read-all \
  -H "Authorization: Bearer YOUR_TOKEN"

# 5. Delete notification
curl -X DELETE http://localhost:8000/api/v1/notifications/123 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Testing Notification Sending

```php
// Di tinker atau test script
php artisan tinker

// Test vehicle approved
$vehicle = \App\Models\Vehicle::find(1);
\App\Services\MitraNotificationService::sendVehicleApprovedNotification($vehicle);

// Test withdrawal success
$withdrawal = \App\Models\Withdrawal::find(1);
\App\Services\MitraNotificationService::sendWithdrawalSuccessNotification($withdrawal);

// Test new booking
$booking = \App\Models\Booking::find(1);
$driver = \App\Models\User::find(2);
\App\Services\MitraNotificationService::sendNewBookingNotification($booking, $driver);
```

## Environment Variables

Pastikan FCM sudah dikonfigurasi di `.env`:

```env
FCM_SERVICE_ACCOUNT=/path/to/firebase-service-account.json
FCM_PROJECT_ID=your-project-id
```

## Logging

Semua notifikasi di-log di Laravel log:

```bash
# Lihat log
tail -f storage/logs/laravel.log

# Filter notifikasi saja
tail -f storage/logs/laravel.log | grep -i notification
```

## TODO / Future Enhancements

- [ ] Notification preferences per user
- [ ] Scheduled notifications (reminders, summaries)
- [ ] Notification templates
- [ ] Multi-language notifications
- [ ] Email notifications as fallback
- [ ] SMS notifications for critical events
- [ ] Notification analytics & tracking

## Notes

- Notifikasi menggunakan FCM untuk real-time push
- Semua notifikasi juga disimpan ke database untuk in-app notifications
- Token FCM user otomatis diupdate dari mobile app saat login
- Jika user tidak punya FCM token, notifikasi tetap tersimpan di DB
