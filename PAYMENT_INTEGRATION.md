# Payment Integration dengan Xendit

## Overview
Integrasi payment menggunakan Xendit Virtual Account dengan custom UI yang menyerupai BRI Virtual Account. System mendukung berbagai metode pembayaran termasuk BRI, BCA, Mandiri, BNI, Permata, Cash, QRIS, dan Dana.

## Backend Setup

### 1. Instalasi Dependencies
Xendit PHP SDK sudah terinstall:
```bash
composer require xendit/xendit-php
```

### 2. Konfigurasi Environment
Tambahkan kredensial Xendit ke file `.env`:

```env
XENDIT_SECRET_KEY=your-xendit-secret-key-here
XENDIT_PUBLIC_KEY=your-xendit-public-key-here
XENDIT_WEBHOOK_TOKEN=your-xendit-webhook-token-here
```

**Cara mendapatkan API Key:**
1. Daftar/login ke [Xendit Dashboard](https://dashboard.xendit.co/)
2. Pilih mode Test untuk development atau Live untuk production
3. Navigasi ke Settings > Developers > API Keys
4. Copy Secret Key dan Public Key
5. Untuk Webhook Token, buat token random yang secure (misal: `openssl rand -hex 32`)

### 3. Database Migration
Migration untuk tabel payments sudah dibuat dan dijalankan:
```bash
php artisan migrate
```

### 4. API Endpoints

#### Create Payment
```http
POST /api/v1/payments
Content-Type: application/json

{
  "ride_id": 1,
  "user_id": 1,
  "booking_number": "FR-2345678997543234",
  "payment_method": "bri",
  "amount": 50000,
  "admin_fee": 15000
}
```

**Response Success:**
```json
{
  "success": true,
  "message": "Payment created successfully",
  "data": {
    "payment": {
      "id": 1,
      "ride_id": 1,
      "user_id": 1,
      "booking_number": "FR-2345678997543234",
      "payment_method": "bri",
      "amount": "50000.00",
      "admin_fee": "15000.00",
      "total_amount": "65000.00",
      "virtual_account_number": "908880855812673933",
      "bank_code": "BRI",
      "status": "pending",
      "expires_at": "2026-01-08T05:51:04.000000Z"
    },
    "virtual_account_number": "908880855812673933",
    "bank_code": "BRI",
    "expires_at": "2026-01-08T05:51:04.000000Z"
  }
}
```

#### Check Payment Status
```http
GET /api/v1/payments/{id}/status
```

**Response:**
```json
{
  "success": true,
  "data": {
    "payment_id": 1,
    "status": "pending",
    "booking_number": "FR-2345678997543234",
    "virtual_account_number": "908880855812673933",
    "total_amount": "65000.00",
    "expires_at": "2026-01-08T05:51:04.000000Z",
    "paid_at": null
  }
}
```

#### Webhook Callback
```http
POST /api/v1/payments/webhook
X-Callback-Token: your-xendit-webhook-token-here
Content-Type: application/json

{
  "external_id": "PAYMENT-FR-2345678997543234-1704688264",
  "status": "COMPLETED",
  "account_number": "908880855812673933",
  "amount": 65000
}
```

### 5. Setup Xendit Webhook
1. Login ke Xendit Dashboard
2. Navigasi ke Settings > Webhooks
3. Tambahkan Webhook URL: `https://yourdomain.com/api/v1/payments/webhook`
4. Set Webhook Token sesuai dengan `XENDIT_WEBHOOK_TOKEN` di `.env`
5. Aktifkan event: `virtual_account.payment`

## Frontend Setup (Flutter)

### 1. Dependencies
Dependencies yang dibutuhkan sudah ada di `pubspec.yaml`:
```yaml
dependencies:
  http: ^0.13.6
  intl: ^0.18.1
```

### 2. File Structure
```
frontend/lib/
├── models/
│   └── payment_model.dart
├── services/
│   └── payment_service.dart
└── screens/customer/nebeng_motor/pages/
    ├── payment_method_page.dart
    ├── payment_waiting_page.dart
    └── payment_success_page.dart
```

### 3. Flow Pembayaran

#### Step 1: Pilih Metode Pembayaran
User memilih metode pembayaran di `PaymentMethodPage`

#### Step 2: Klik Bayar
- Untuk Cash: Langsung ke halaman success
- Untuk Virtual Account: Hit API `/api/v1/payments` untuk create virtual account

#### Step 3: Payment Waiting Page
- Menampilkan countdown timer (1 jam)
- Menampilkan nomor virtual account
- Auto-check payment status setiap 5 detik
- User dapat manual check status
- Jika payment berhasil, auto redirect ke success page

#### Step 4: Payment Success Page
- Menampilkan detail pembayaran
- Rincian biaya
- Detail perjalanan

### 4. Konfigurasi Base URL
Edit file `frontend/lib/services/payment_service.dart`:
```dart
static const String baseUrl = 'http://your-backend-url/api/v1';
```

## Testing Payment Flow

### 1. Test dengan Xendit Test Mode
Xendit menyediakan test mode untuk development. Di test mode, Anda bisa:
- Membuat virtual account tanpa uang real
- Simulate payment dari dashboard Xendit
- Test webhook callbacks

### 2. Simulate Payment
1. Buat payment dari Flutter app
2. Copy nomor virtual account yang digenerate
3. Login ke Xendit Dashboard (Test Mode)
4. Navigasi ke Virtual Accounts > Transactions
5. Cari VA number yang baru dibuat
6. Klik "Simulate Payment"
7. App akan otomatis detect pembayaran berhasil

### 3. Test Webhook Locally
Untuk test webhook di local development:
1. Install ngrok: `brew install ngrok` (Mac) atau download dari ngrok.com
2. Expose local server: `ngrok http 8000`
3. Copy HTTPS URL yang digenerate
4. Set webhook URL di Xendit Dashboard ke: `https://your-ngrok-url.ngrok.io/api/v1/payments/webhook`

## Production Checklist

- [ ] Ganti Xendit API Key ke mode LIVE
- [ ] Set environment APP_ENV=production
- [ ] Update base URL di Flutter ke production URL
- [ ] Set webhook URL ke production domain
- [ ] Implement proper error handling dan logging
- [ ] Add transaction monitoring
- [ ] Setup email notification untuk payment success
- [ ] Implement payment expiration cleanup job
- [ ] Add rate limiting pada payment endpoints
- [ ] Secure webhook endpoint dengan proper token validation

## Supported Payment Methods

| Method | Code | Virtual Account | Status |
|--------|------|----------------|--------|
| BRI VA | `bri` | ✅ | Active |
| BCA VA | `bca` | ✅ | Active |
| Mandiri VA | `mandiri` | ✅ | Active |
| BNI VA | `bni` | ✅ | Active |
| Permata VA | `permata` | ✅ | Active |
| Cash | `cash` | ❌ | Active |
| QRIS | `qris` | ⚠️ | Coming Soon |
| Dana | `dana` | ⚠️ | Coming Soon |

## Troubleshooting

### Payment Creation Failed
- Check Xendit API key validity
- Verify network connectivity
- Check Laravel logs: `tail -f storage/logs/laravel.log`

### Webhook Not Received
- Verify webhook URL is accessible from internet
- Check webhook token matches
- Check Xendit Dashboard webhook logs

### Payment Status Not Updating
- Verify webhook is properly configured
- Check database payment status
- Check if external_id matches between Xendit and database

## Security Notes

1. **Never commit credentials**: Add `.env` to `.gitignore`
2. **Use HTTPS**: Always use HTTPS in production
3. **Validate webhook**: Always verify callback token
4. **Rate limiting**: Implement rate limiting on payment endpoints
5. **Idempotency**: Handle duplicate webhook callbacks properly

## Support

- Xendit Documentation: https://docs.xendit.co/
- Xendit Dashboard: https://dashboard.xendit.co/
- Support Email: support@xendit.co
