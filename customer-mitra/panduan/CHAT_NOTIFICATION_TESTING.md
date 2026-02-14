# Chat Notification Testing Guide

## Prerequisites
1. Backend Laravel running (`php artisan serve`)
2. Flutter app running on device/emulator
3. User harus sudah login dan punya FCM token

## Step-by-Step Testing

### 1. Verify FCM Tokens
Check yang user punya FCM token di database:
```bash
cd backend
php artisan tinker --execute='$users = \App\Models\User::whereNotNull("fcm_token")->get(["id", "name", "role", "fcm_token"]); foreach($users as $u) { echo "ID: {$u->id} - {$u->name} ({$u->role}) - Token: " . substr($u->fcm_token, 0, 30) . "...\n"; }'
```

### 2. Test Manual Notification (Backend)
Test kirim notifikasi manual ke user tertentu:
```bash
curl -X GET "http://localhost:8000/api/v1/chat/notify/test?recipient_id=2" -H "Accept: application/json" | jq '.'
```

Expected response:
```json
{
  "success": true,
  "message": "Test notification sent",
  "recipient_id": "2"
}
```

### 3. Test dari Flutter App

#### A. Hot Restart App
```bash
# Hot restart untuk memuat perubahan NotificationService
flutter run --hot
```

Atau tekan `R` di terminal Flutter

#### B. Test Chat Message
1. Login sebagai **Customer** di device 1 (atau emulator)
2. Login sebagai **Mitra** di device 2 (atau emulator lain)
3. Buka halaman chat antara keduanya
4. Kirim pesan dari Customer → Mitra
5. Mitra harus menerima notifikasi

### 4. Check Flutter Logs
Monitor logs untuk melihat proses:
```bash
flutter logs | grep -i "chat\|notification\|fcm"
```

Expected logs when sending message:
```
📤 Sending chat notification to backend...
   Sender: 1 (Customer Name)
   Recipient: 2
   Message: Hello...
   URL: http://10.0.2.2:8000/api/v1/chat/notify
   Response status: 200
   Response body: {"success":true,"message":"Notification sent successfully"}
✅ Chat notification sent successfully
```

Expected logs when receiving notification (foreground):
```
📨 FCM message received in foreground
   Data: {type: chat_message, conversation_id: ..., sender_name: ...}
   Title: Pesan dari Customer Name
   Body: Hello from customer
   Type: Chat Message
📢 Showing notification: Pesan dari Customer Name
```

### 5. Check Backend Logs
```bash
tail -f backend/storage/logs/laravel.log | grep -i "chat\|fcm"
```

Expected logs:
```
[INFO] 📨 Chat notification request received
[INFO] Chat notification saved to database
[INFO] FCM v1 request
[INFO] FCM v1 response
[INFO] FCM v1 sent
[INFO] ✅ Chat notification sent successfully
```

## Debugging Issues

### Issue 1: Notifikasi tidak muncul di device
**Check:**
1. User punya FCM token? 
   ```bash
   php artisan tinker --execute='\App\Models\User::find(USER_ID)->fcm_token'
   ```

2. FCM service account configured?
   ```bash
   # Check .env
   grep FCM_SERVICE_ACCOUNT backend/.env
   
   # File exists?
   ls -lah backend/storage/app/nebeng1-firebase-adminsdk-*.json
   ```

3. Notification channel created?
   - Uninstall & reinstall app
   - Or clear app data

### Issue 2: Backend error "Field 'body' doesn't have a default value"
**Fix:** Already fixed! Using 'body' field correctly now.

### Issue 3: API endpoint tidak dipanggil
**Check Flutter logs:**
```bash
flutter logs | grep "Sending chat notification"
```

If not showing:
- Hot restart app
- Check ApiConfig.baseUrl matches backend URL
- For emulator: use `http://10.0.2.2:8000`
- For real device: use local IP `http://192.168.x.x:8000`

### Issue 4: Notification muncul tapi tanpa sound
**Check:**
1. Do Not Disturb mode OFF
2. App notification permission enabled
3. Channel importance set to HIGH (already done)

## Test Commands Summary

```bash
# 1. Check users with FCM tokens
cd backend && php artisan tinker --execute='\App\Models\User::whereNotNull("fcm_token")->count()'

# 2. Test manual notification
curl -X GET "http://localhost:8000/api/v1/chat/notify/test?recipient_id=2" -H "Accept: application/json" | jq

# 3. Monitor backend logs
tail -f backend/storage/logs/laravel.log | grep -i chat

# 4. Monitor Flutter logs
flutter logs | grep -i "chat\|notification"

# 5. Check notification table
cd backend && php artisan tinker --execute='\App\Models\Notification::where("type", "chat_message")->latest()->first()'
```

## Expected Flow

1. User A sends message in chat
2. Flutter `ChatService.sendMessage()` saves to Firestore
3. Flutter calls `POST /api/v1/chat/notify`
4. Backend saves notification to `notifications` table
5. Backend sends FCM to User B's device
6. User B receives push notification
7. User B clicks notification → opens chat (if implemented)

## Success Criteria

✅ Backend test endpoint returns success
✅ Notification saved to database
✅ FCM sent without errors in logs
✅ Device receives and displays notification
✅ Notification has sound & vibration
✅ Chat messages trigger notifications automatically

