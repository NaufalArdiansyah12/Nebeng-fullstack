# Penjelasan: Payment Request API vs Payment Method API

## Masalah Sebelumnya

### **Payment Method API (Yang Lama)**
- ❌ **TIDAK membuat transaksi di Xendit Dashboard**
- ❌ Hanya membuat Virtual Account number saja
- ❌ Tidak ada invoice/payment record di Xendit
- ❌ Tidak bisa tracking payment dari dashboard
- ⚠️ Webhook tetap jalan tapi tidak ada data transaksi di Xendit

```php
// Code lama - hanya bikin VA number
$paymentMethodApi->createPaymentMethod($params);
// Result: VA number dibuat tapi TIDAK ADA TRANSAKSI di dashboard
```

### **Payment Request API (Yang Baru - Sudah Diupdate)**
- ✅ **MEMBUAT transaksi lengkap di Xendit Dashboard**
- ✅ Membuat Virtual Account + Invoice sekaligus
- ✅ Ada payment record di Xendit yang bisa di-track
- ✅ Muncul di dashboard Xendit → Transactions
- ✅ Webhook lengkap dengan data transaksi

```php
// Code baru - bikin transaksi lengkap
$paymentRequestApi->createPaymentRequest($params);
// Result: VA number + Transaksi muncul di Xendit dashboard
```

---

## Apa yang Sudah Diubah

### 1. **Namespace dan Import**
```php
// SEBELUM (Payment Method API)
use Xendit\PaymentMethod\PaymentMethodApi;
use Xendit\PaymentMethod\PaymentMethodParameters;
use Xendit\PaymentMethod\VirtualAccountParameters;
use Xendit\PaymentMethod\VirtualAccountChannelProperties;

// SESUDAH (Payment Request API)
use Xendit\PaymentRequest\PaymentRequestApi;
use Xendit\PaymentRequest\PaymentRequestParameters;
use Xendit\PaymentRequest\PaymentMethodParameters;
use Xendit\PaymentRequest\VirtualAccountParameters;
use Xendit\PaymentRequest\VirtualAccountChannelProperties;
use Xendit\PaymentRequest\PaymentRequestCurrency;
```

### 2. **Struktur Parameter**
```php
// SEBELUM - Payment Method API
$params = new PaymentMethodParameters([
    'type' => 'VIRTUAL_ACCOUNT',
    'reusability' => 'ONE_TIME_USE',
    'reference_id' => $externalId,
    'virtual_account' => $virtualAccount,
]);

// SESUDAH - Payment Request API
$paymentMethod = new PaymentMethodParameters([
    'type' => 'VIRTUAL_ACCOUNT',
    'reusability' => 'ONE_TIME_USE',
    'virtual_account' => $virtualAccount,
]);

$params = new PaymentRequestParameters([
    'reference_id' => $externalId,
    'amount' => $totalAmount,           // ← PENTING: Amount ada di sini
    'currency' => PaymentRequestCurrency::IDR,
    'country' => 'ID',
    'payment_method' => $paymentMethod, // ← Payment method jadi nested
    'description' => "Payment for booking: $bookingNumber",
    'metadata' => [
        'ride_id' => $rideId,
        'user_id' => $userId,
        'booking_number' => $bookingNumber,
    ],
]);
```

### 3. **Response Structure**
```php
// SEBELUM - Payment Method API Response
$response = [
    'id' => 'pm_xxx',
    'type' => 'VIRTUAL_ACCOUNT',
    'virtual_account' => [
        'channel_code' => 'BRI',
        'virtual_account_number' => '908812751710037',
    ]
]

// SESUDAH - Payment Request API Response
$response = [
    'id' => 'pr_xxx',                    // Payment Request ID
    'reference_id' => 'PAYMENT-xxx',
    'amount' => 65000,
    'status' => 'PENDING',
    'payment_method' => [
        'id' => 'pm_xxx',
        'type' => 'VIRTUAL_ACCOUNT',
        'virtual_account' => [
            'channel_code' => 'BRI',
            'channel_properties' => [
                'virtual_account_number' => '908812751710037',
            ]
        ]
    ]
]
```

### 4. **Webhook Structure**
```php
// SEBELUM - Payment Method Webhook
{
    "id": "pm_xxx",
    "status": "ACTIVE",
    "type": "VIRTUAL_ACCOUNT"
}

// SESUDAH - Payment Request Webhook
{
    "id": "pr_xxx",
    "reference_id": "PAYMENT-FR-xxx",
    "status": "SUCCEEDED",              // ← Status payment request
    "amount": 65000,
    "currency": "IDR",
    "payment_method": {
        "id": "pm_xxx",
        "type": "VIRTUAL_ACCOUNT",
        "virtual_account": {...}
    }
}
```

### 5. **Status Values**
```php
// Payment Method API statuses
- ACTIVE, INACTIVE, PENDING, EXPIRED

// Payment Request API statuses (NEW)
- PENDING         // Menunggu pembayaran
- REQUIRES_ACTION // Butuh aksi dari user
- SUCCEEDED       // Pembayaran berhasil ← INI YANG KITA PAKAI
- FAILED          // Pembayaran gagal
- EXPIRED         // Kedaluwarsa
```

---

## Testing dengan Real Xendit

### **Setup Webhook di Xendit Dashboard**

1. Login ke [Xendit Dashboard](https://dashboard.xendit.co/)
2. Pilih **Test Mode**
3. Navigasi ke **Settings** → **Webhooks**
4. **Add New Webhook**:
   - URL: `https://yourdomain.com/api/v1/payments/webhook`
   - Webhook Token: `wd8c8dGHR9DGeCyAJTX7VEDkb6qGWA04k7mOLdx443bYezml`
5. **Enable Events**:
   - ✅ `payment.succeeded`
   - ✅ `payment.failed`
   - ✅ `payment.pending`
   - ✅ `payment_request.succeeded` (PENTING!)

### **Testing Flow**

#### **Step 1: Create Payment**
```bash
curl -X POST http://127.0.0.1:8000/api/v1/payments \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": 1,
    "user_id": 1,
    "booking_number": "FR-1234567890",
    "payment_method": "bri",
    "amount": 50000,
    "admin_fee": 15000
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Payment created successfully",
  "data": {
    "payment": {
      "id": 1,
      "reference_id": "PAYMENT-FR-1234567890-1704688264",
      "virtual_account_number": "908812751710037",
      "bank_code": "BRI",
      "total_amount": "65000.00",
      "status": "pending",
      "expires_at": "2026-01-08T08:23:45.000000Z"
    }
  }
}
```

#### **Step 2: Cek di Xendit Dashboard**

✅ **SEKARANG TRANSAKSI AKAN MUNCUL!**

1. Login ke Xendit Dashboard
2. Navigasi ke **Transactions** → **Payment Requests**
3. Cari berdasarkan **reference_id**: `PAYMENT-FR-1234567890-1704688264`
4. Klik untuk lihat detail transaksi

**Yang akan terlihat:**
- Amount: Rp 65,000
- Status: PENDING
- Virtual Account Number: 908812751710037
- Bank: BRI
- Created: timestamp
- Expires: timestamp

#### **Step 3: Simulate Payment dari Xendit Dashboard**

1. **Dari halaman detail transaksi** di dashboard
2. Klik tombol **"Simulate Payment"**
3. Atau klik **"Mark as Paid"** (untuk test mode)
4. Xendit akan send webhook ke server Anda

#### **Step 4: Verify Webhook**

Check Laravel logs:
```bash
tail -f storage/logs/laravel.log
```

Log yang muncul:
```
[2026-01-08 08:30:00] local.INFO: Webhook received {...}
[2026-01-08 08:30:00] local.INFO: Processing webhook payload {...}
[2026-01-08 08:30:00] local.INFO: Webhook Success: Payment PAYMENT-FR-xxx marked as PAID
```

Check payment status:
```bash
curl http://127.0.0.1:8000/api/v1/payments/1/status
```

Response:
```json
{
  "success": true,
  "data": {
    "payment_id": 1,
    "status": "paid",        // ← Sudah berubah jadi 'paid'
    "paid_at": "2026-01-08T08:30:00.000000Z",
    "total_amount": "65000.00"
  }
}
```

---

## Simulasi Payment (Alternative Method)

### **Method 1: Via Xendit API (Recommended)**

Gunakan Xendit Simulate Payment endpoint:

```bash
curl --location --request POST \
  'https://api.xendit.co/v2/payment_requests/{payment_request_id}/simulations/payment' \
  --header 'Authorization: Basic eG5kX2RldmVsb3BtZW50X3hidzBHMWFtUGFWbnRaQ3J4aXpkWEhSWFkwaFQ0UDI3ZThaN3Y0UFUxYzVaWnlBQlduemt1eXJTMHRzaWI6' \
  --header 'Content-Type: application/json'
```

**Note:** 
- Ganti `{payment_request_id}` dengan ID dari response create payment
- Authorization header adalah Base64 dari: `secret_key:` (perhatikan `:` di akhir)

### **Method 2: Via Dashboard** (Paling Mudah)
1. Dashboard → Transactions → Payment Requests
2. Pilih transaksi yang ingin di-simulate
3. Klik "Simulate Payment" atau "Mark as Paid"

### **Method 3: Local Testing Endpoint**
Untuk development, gunakan endpoint testing internal:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/payments/test/1/simulate
```

---

## Keuntungan Payment Request API

### **Untuk Business**
- ✅ Track semua transaksi di satu tempat (Xendit Dashboard)
- ✅ Export data transaksi untuk accounting
- ✅ Lihat statistics dan reports
- ✅ Monitor payment success rate
- ✅ Customer support lebih mudah (ada payment ID di Xendit)

### **Untuk Developer**
- ✅ Debug lebih mudah (lihat transaksi di dashboard)
- ✅ Testing lebih realistis
- ✅ Webhook lebih reliable
- ✅ API lebih modern dan future-proof
- ✅ Support lebih banyak payment methods

### **Untuk Customer**
- ✅ Dapat konfirmasi payment dari Xendit
- ✅ Customer support lebih cepat
- ✅ Payment receipt available
- ✅ Refund process lebih mudah

---

## Migration Checklist

- [x] Update namespace dan imports
- [x] Update API initialization
- [x] Update parameter structure
- [x] Update response parsing
- [x] Update webhook handler
- [x] Update webhook status values
- [x] Test dengan dummy mode
- [x] Update documentation
- [ ] Test dengan real Xendit API (Test Mode)
- [ ] Setup webhook di Xendit Dashboard
- [ ] Test webhook integration
- [ ] Test semua bank codes (BRI, BCA, Mandiri, dll)
- [ ] Test payment expiration
- [ ] Test payment failure scenarios
- [ ] Production deployment

---

## Next Steps

1. **Set Real API Key**:
   ```env
   XENDIT_SECRET_KEY=xnd_development_xbw0G1amPaVntZuCrxizdXHRXY0hT4P27e8Z7v4PU1c5ZZyABWnzkuyrS0tsib
   PAYMENT_DUMMY_MODE=false
   ```

2. **Create Real Transaction**:
   - Hit create payment endpoint
   - Check Xendit Dashboard → Payment Requests
   - Verify transaksi muncul ✅

3. **Test Webhook**:
   - Simulate payment dari dashboard
   - Check Laravel logs
   - Verify payment status updated

4. **Production Ready**:
   - Ganti ke production API key
   - Update webhook URL
   - Deploy!

---

## Support

Jika ada pertanyaan atau issue:
- [Xendit Documentation](https://developers.xendit.co/api-reference/)
- [Payment Request API Guide](https://developers.xendit.co/api-reference/#create-payment-request)
- [Webhook Documentation](https://developers.xendit.co/api-reference/#webhooks)

🎉 **Sekarang transaksi Anda akan muncul di Xendit Dashboard!**
