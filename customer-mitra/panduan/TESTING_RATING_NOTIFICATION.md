# Testing Rating Notification

## Problem
Notifikasi rating tidak muncul di halaman notifikasi mitra saat customer memberikan rating.

## Solution
Telah ditambahkan kode untuk mengirim notifikasi di `RatingController::store()` setelah rating berhasil dibuat.

## Changes Made

### 1. RatingController.php
- Added import: `use App\Services\MitraNotificationService;`
- Added notification sending after rating is created:
```php
// Send notification to driver/mitra
try {
    $driver = User::find($request->driver_id);
    if ($driver) {
        $rating->load(['user', 'driver']);
        $booking = $this->getBooking($request->booking_id, $request->booking_type);
        if ($booking) {
            $rating->booking = $booking;
            $rating->booking_id = $booking->id;
        }
        MitraNotificationService::sendRatingReceivedNotification($rating, $driver);
    }
} catch (\Exception $e) {
    Log::error('Failed to send rating notification', ['error' => $e->getMessage()]);
}
```

## How to Test

### Method 1: Via Mobile App (Recommended)

1. **Login sebagai Customer:**
   - Buka app sebagai customer
   - Pastikan ada booking yang sudah completed

2. **Berikan Rating:**
   - Buka riwayat booking
   - Pilih booking yang completed
   - Klik "Beri Rating"
   - Isi rating (1-5 bintang) dan review
   - Submit

3. **Login sebagai Mitra (Driver):**
   - Logout dari customer
   - Login sebagai mitra (driver dari booking tadi)
   - Tap icon notifikasi di home page
   - Seharusnya muncul notifikasi rating baru dengan icon ⭐

### Method 2: Via Laravel Tinker

```bash
cd /home/naufal/project/nebeng-fullstack/backend

# Run test script
php artisan tinker
```

Kemudian paste script ini di tinker:
```php
use App\Models\Rating;
use App\Models\User;
use App\Services\MitraNotificationService;

// Find mitra and customer
$driver = User::where('role', 'mitra')->first();
$customer = User::where('role', 'customer')->first();

// Create test rating
$rating = Rating::create([
    'booking_id' => 1,
    'booking_type' => 'motor',
    'user_id' => $customer->id,
    'driver_id' => $driver->id,
    'rating' => 5,
    'review' => 'Test rating - Driver sangat baik!',
]);

$rating->load(['user', 'driver']);

// Send notification
MitraNotificationService::sendRatingReceivedNotification($rating, $driver);

// Check notification
\App\Models\Notification::where('user_id', $driver->id)
    ->where('type', 'rating_received')
    ->latest()
    ->first();
```

### Method 3: Via API (cURL)

```bash
# 1. Submit rating sebagai customer
curl -X POST http://localhost:8000/api/v1/ratings \
  -H "Authorization: Bearer YOUR_CUSTOMER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": 1,
    "booking_type": "motor",
    "driver_id": 2,
    "rating": 5,
    "review": "Driver sangat baik!"
  }'

# 2. Check notifications sebagai driver
curl -X GET http://localhost:8000/api/v1/notifications \
  -H "Authorization: Bearer YOUR_DRIVER_TOKEN"

# 3. Check unread count
curl -X GET http://localhost:8000/api/v1/notifications/unread-count \
  -H "Authorization: Bearer YOUR_DRIVER_TOKEN"
```

### Method 4: Via Bash Script

```bash
cd /home/naufal/project/nebeng-fullstack/backend
chmod +x test_rating_notification.sh
./test_rating_notification.sh
```

## Verification Checklist

- [ ] Rating berhasil dibuat di database (table `driver_ratings`)
- [ ] Notifikasi tersimpan di database (table `notifications`)
- [ ] Notifikasi memiliki:
  - `user_id` = driver ID
  - `type` = 'rating_received'
  - `title` = "Rating Baru ⭐" atau "Rating Diterima"
  - `icon` = "⭐"
  - `is_read` = false
- [ ] FCM push notification terkirim (jika driver punya FCM token)
- [ ] Notifikasi muncul di halaman notifikasi mobile app
- [ ] Badge unread count ter-update di home page
- [ ] Tap notifikasi bisa navigate ke halaman yang sesuai

## Troubleshooting

### Notifikasi tidak muncul di app:

1. **Check Laravel Log:**
```bash
tail -f storage/logs/laravel.log | grep -i "rating"
```

2. **Check Database:**
```sql
SELECT * FROM notifications 
WHERE type = 'rating_received' 
ORDER BY created_at DESC 
LIMIT 5;
```

3. **Check FCM Token:**
```sql
SELECT id, name, email, fcm_token 
FROM users 
WHERE id = [DRIVER_ID];
```

4. **Check API Response:**
   - Pastikan response dari `/api/v1/ratings` POST request sukses
   - Pastikan `success = true`
   - Tidak ada error di response

### Error "Failed to send rating notification":

1. Check apakah `MitraNotificationService` class ada
2. Check apakah driver user ada di database
3. Check Laravel log untuk error details
4. Pastikan table `notifications` ada dan dapat ditulis

### Notifikasi tersimpan tapi tidak ada push:

- Ini normal jika driver belum punya FCM token
- Notifikasi tetap akan muncul di in-app notification
- FCM token diset otomatis saat login di mobile app

## Expected Notification Data

```json
{
  "id": 123,
  "user_id": 2,
  "type": "rating_received",
  "title": "Rating Baru ⭐",
  "body": "Ahmad memberikan rating ⭐⭐⭐⭐⭐ untuk perjalanan Anda! \"Driver sangat ramah dan tepat waktu\"",
  "icon": "⭐",
  "booking_id": 1,
  "booking_number": "BKG-2026020700123",
  "data": {
    "rating_id": "456",
    "rating_value": "5",
    "customer_name": "Ahmad",
    "review": "Driver sangat ramah dan tepat waktu",
    "type": "rating_received"
  },
  "is_read": false,
  "read_at": null,
  "created_at": "2026-02-07T08:41:23.000000Z"
}
```

## Related Files

- `/backend/app/Http/Controllers/Api/RatingController.php` - Rating submission endpoint
- `/backend/app/Services/MitraNotificationService.php` - Notification service
- `/backend/app/Models/Rating.php` - Rating model
- `/backend/app/Models/Notification.php` - Notification model
- `/customer-mitra/frontend/lib/screens/mitra/notification_page.dart` - Frontend notification page

## Next Steps

Setelah fix ini, semua notifikasi mitra seharusnya berfungsi:
- ✅ Vehicle approved/rejected
- ✅ Withdrawal success/failed  
- ✅ New booking
- ✅ Booking cancelled
- ✅ Booking completed
- ✅ Payment received
- ✅ **Rating received** (FIXED)
