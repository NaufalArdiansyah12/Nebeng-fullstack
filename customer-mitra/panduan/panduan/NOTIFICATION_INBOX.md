# Notification Inbox System

Sistem notifikasi dengan penyimpanan database untuk menampilkan riwayat notifikasi di aplikasi mobile.

## Features

✅ **Database Storage** - Semua notifikasi disimpan di database untuk persistensi  
✅ **Automatic Saving** - BookingNotificationService otomatis menyimpan ke database saat mengirim FCM  
✅ **Read/Unread Status** - Track status baca notifikasi  
✅ **Pagination Support** - List notifikasi dengan pagination  
✅ **Filter & Sort** - Notifikasi diurutkan dari terbaru  
✅ **Mark as Read** - Tandai satu atau semua notifikasi sebagai dibaca  
✅ **Delete** - Hapus notifikasi individual atau semua yang sudah dibaca  

## Database Schema

**Table:** `notifications`

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| user_id | bigint | Foreign key to users table |
| type | varchar(50) | Notification type (booking_status_update, promo, etc) |
| title | varchar(255) | Notification title |
| body | text | Notification message body |
| icon | varchar(10) | Emoji icon for notification |
| booking_id | bigint | Optional foreign key to booking |
| booking_number | varchar(50) | Booking reference number |
| status | varchar(50) | Booking status related to notification |
| data | json | Additional metadata |
| is_read | boolean | Read status (default: false) |
| read_at | timestamp | When notification was read |
| created_at | timestamp | When notification was created |
| updated_at | timestamp | Last update time |

**Indexes:**
- `user_id` - Fast lookup by user
- `is_read` - Fast unread count queries
- `created_at` - Sorting by date

## Backend API Endpoints

Base URL: `/api/v1`  
Authentication: Bearer token (custom ApiToken)

### 1. Get All Notifications

```http
GET /notifications?page=1&per_page=20
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Notifications retrieved successfully",
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "user_id": 1,
        "type": "booking_status_update",
        "title": "Pembayaran Berhasil! 🎉",
        "body": "Halo John, pembayaran untuk booking NB-MTR-001 telah berhasil.",
        "icon": "🎉",
        "booking_id": 123,
        "booking_number": "NB-MTR-001",
        "status": "paid",
        "data": {"booking_id": "123", "status": "paid"},
        "is_read": false,
        "read_at": null,
        "created_at": "2026-02-02T02:15:23.000000Z",
        "updated_at": "2026-02-02T02:15:23.000000Z"
      }
    ],
    "first_page_url": "http://api.example.com/api/v1/notifications?page=1",
    "last_page": 3,
    "next_page_url": "http://api.example.com/api/v1/notifications?page=2",
    "per_page": 20,
    "total": 45
  }
}
```

### 2. Get Unread Count

```http
GET /notifications/unread-count
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Unread count retrieved successfully",
  "data": {
    "unread_count": 5
  }
}
```

### 3. Mark Notification as Read

```http
POST /notifications/{id}/read
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification marked as read",
  "data": {
    "id": 1,
    "is_read": true,
    "read_at": "2026-02-02T02:19:19.000000Z",
    ...
  }
}
```

### 4. Mark All as Read

```http
POST /notifications/read-all
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

### 5. Delete Notification

```http
DELETE /notifications/{id}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Notification deleted successfully"
}
```

### 6. Clear All Read Notifications

```http
DELETE /notifications/clear-read
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Read notifications cleared successfully"
}
```

## BookingNotificationService Integration

Service ini otomatis menyimpan notifikasi ke database saat mengirim push notification.

```php
use App\Services\BookingNotificationService;

// Send notification (saves to DB + sends FCM)
BookingNotificationService::sendStatusNotification(
    $booking,
    'paid', // new status
    ['extra_data' => 'value'] // optional extra data
);
```

**Flow:**
1. Create notification record in database
2. Send FCM push notification (if user has token)
3. Log success/error

**Status Messages Supported:**
- `paid` - Pembayaran berhasil
- `confirmed` / `dijemput` - Booking dikonfirmasi
- `menuju_penjemputan` - Driver menuju penjemputan
- `sudah_di_penjemputan` / `arrived` - Driver sudah tiba
- `sedang_dalam_perjalanan` / `in_progress` / `menuju_tujuan` - Perjalanan dimulai
- `sudah_sampai_tujuan` / `near_destination` - Hampir sampai
- `completed` / `done` / `selesai` - Perjalanan selesai
- `cancelled` / `dibatalkan` - Booking dibatalkan
- `expired` / `kadaluarsa` - Booking kadaluarsa
- `pending` - Menunggu pembayaran
- `refunded` / `dikembalikan` - Pembayaran dikembalikan

## Flutter Frontend

### Model: `notification_model.dart`

```dart
class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? icon;
  final int? bookingId;
  final String? bookingNumber;
  final String? status;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
}
```

### API Service: `notification_api_service.dart`

```dart
import 'package:your_app/services/notification_api_service.dart';

// Fetch notifications
final response = await NotificationApiService.fetchNotifications(
  token: token,
  page: 1,
  perPage: 20,
);

// Get unread count
final count = await NotificationApiService.getUnreadCount(token: token);

// Mark as read
await NotificationApiService.markAsRead(
  token: token,
  notificationId: notificationId,
);

// Mark all as read
await NotificationApiService.markAllAsRead(token: token);

// Delete notification
await NotificationApiService.deleteNotification(
  token: token,
  notificationId: notificationId,
);
```

### UI Page: `notification_page.dart`

Features:
- ✅ Pull to refresh
- ✅ Infinite scroll pagination
- ✅ Swipe to delete
- ✅ Tap to mark as read
- ✅ Visual indicator for unread (blue border + dot)
- ✅ Time ago display
- ✅ Empty state
- ✅ Error handling
- ✅ Menu for "Mark All as Read"

## Testing

### Create Test Notification

```bash
cd backend
php artisan tinker
```

```php
$user = \App\Models\User::find(1);
\App\Models\Notification::create([
    'user_id' => $user->id,
    'type' => 'booking_status_update',
    'title' => 'Test Notification 🎉',
    'body' => 'This is a test notification',
    'icon' => '🎉',
    'booking_number' => 'TEST-001',
    'status' => 'paid',
    'data' => json_encode(['test' => true]),
    'is_read' => false,
]);
```

### Test API Endpoints

```bash
# Get token
TOKEN=$(curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","password":"password"}' \
  | jq -r '.data.token')

# Get notifications
curl -X GET "http://localhost:8000/api/v1/notifications" \
  -H "Authorization: Bearer $TOKEN" | jq

# Get unread count
curl -X GET "http://localhost:8000/api/v1/notifications/unread-count" \
  -H "Authorization: Bearer $TOKEN" | jq

# Mark as read
curl -X POST "http://localhost:8000/api/v1/notifications/1/read" \
  -H "Authorization: Bearer $TOKEN" | jq
```

## Migration

Run migration to create notifications table:

```bash
php artisan migrate
```

Migration file: `database/migrations/2026_02_02_020839_create_notifications_table.php`

## Notes

- Notifications are stored even if user has no FCM token (for in-app viewing)
- Old notifications can be auto-deleted with a scheduled job (not implemented yet)
- Notification types can be extended beyond booking status updates
- Data field allows storing custom metadata for each notification type
- Read status tracking helps show unread count badges in app

## Future Enhancements

- [ ] Auto-cleanup old read notifications (30+ days)
- [ ] Notification preferences (mute types)
- [ ] Rich media notifications (images, actions)
- [ ] Notification categories/filters
- [ ] Push notification preferences
- [ ] Analytics for notification open rates
