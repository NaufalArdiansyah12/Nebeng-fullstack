# Chat Notification Feature

## Overview
Sistem notifikasi otomatis untuk pesan chat baru antara Customer dan Mitra menggunakan Firebase Cloud Messaging (FCM).

## How It Works

### 1. Backend Services

**ChatNotificationService** (`app/Services/ChatNotificationService.php`)
- Mengirim notifikasi FCM ke user yang menerima pesan
- Menyimpan notifikasi ke database
- Data payload mencakup: type, conversation_id, sender_id, sender_name

**ChatController** (`app/Http/Controllers/Api/ChatController.php`)
- Endpoint: `POST /api/v1/chat/notify`
- Menerima request dari Flutter setelah pesan dikirim
- Memanggil ChatNotificationService

### 2. Frontend Integration

**ChatService** (`lib/services/shared/chat_service.dart`)
- Method `sendMessage()` otomatis memanggil API notifikasi
- Menentukan recipient_id berdasarkan conversation data
- Notifikasi dikirim setelah pesan berhasil disimpan ke Firestore

**Notification Handlers** (`lib/main.dart`)
- Foreground: Menampilkan local notification
- Background: Handle saat app di background
- Terminated: Handle saat app ditutup total

### 3. API Endpoint

```
POST /api/v1/chat/notify
```

**Request Body:**
```json
{
  "sender_id": 1,
  "recipient_id": 2,
  "sender_name": "John Doe",
  "message_text": "Halo, apakah masih tersedia?",
  "conversation_id": "firebase_conversation_id"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Notification sent successfully"
}
```

## Flow Diagram

```
Customer sends message
        ↓
Flutter ChatService.sendMessage()
        ↓
Message saved to Firestore
        ↓
Call POST /api/v1/chat/notify
        ↓
Backend ChatNotificationService
        ↓
1. Save to notifications table
2. Send FCM to recipient's device
        ↓
Mitra receives notification
```

## Features

✅ Automatic notification when message is sent
✅ Works for both Customer → Mitra and Mitra → Customer
✅ Notification saved to database (inbox)
✅ FCM push notification (if user has token)
✅ Handles foreground, background, and terminated states
✅ Message preview in notification (max 100 chars)

## Configuration

### Backend
Ensure `.env` has FCM service account configured:
```env
FCM_SERVICE_ACCOUNT=/path/to/service-account.json
```

### Frontend
No additional configuration needed. The app automatically:
- Registers FCM token on login
- Updates token on refresh
- Handles notification display

## Testing

### Test sending notification manually:
```bash
curl -X POST http://localhost:8000/api/v1/chat/notify \
  -H "Content-Type: application/json" \
  -d '{
    "sender_id": 1,
    "recipient_id": 2,
    "sender_name": "Test User",
    "message_text": "Test message",
    "conversation_id": "test_conv_123"
  }'
```

### Check logs:
```bash
# Backend logs
tail -f backend/storage/logs/laravel.log | grep -i "chat"

# Flutter logs
flutter logs | grep -i "chat\|notification"
```

## Database Schema

**notifications table:**
- user_id: recipient user ID
- type: 'chat_message'
- title: "Pesan dari {sender_name}"
- message: message text (truncated to 100 chars)
- data: JSON payload with conversation_id, sender info
- is_read: boolean
- created_at, updated_at

## Notes

- Notification failures don't block message sending
- If user has no FCM token, notification is saved to DB only
- Users can view notification history in their inbox
- Clicking notification should open the chat (navigation TBD)

