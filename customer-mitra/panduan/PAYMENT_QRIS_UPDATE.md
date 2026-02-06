# Update Pembayaran QRIS & Penghapusan Tunai

## Perubahan yang Dilakukan

### 1. **Hapus Metode Pembayaran Tunai (Cash)**
- ❌ Opsi "Tunai" dihapus dari semua layanan:
  - Nebeng Motor
  - Nebeng Mobil
  - Nebeng Barang
- ❌ Cash payment handling dihapus dari backend dan frontend
- ✅ Semua pembayaran sekarang melalui platform dengan admin fee Rp 15.000

### 2. **Implementasi QRIS via Xendit**
- ✅ QRIS sekarang menggunakan **Xendit QR Code API** (REST API)
- ✅ Generate QR Code dinamis untuk setiap transaksi
- ✅ QR Code disimpan di database (kolom `qr_code_url`)
- ✅ Admin fee Rp 15.000 (sama dengan Virtual Account)

## Cara Kerja QRIS

### Flow Pembayaran QRIS:
1. **Customer pilih QRIS** → Klik "Pesan Sekarang"
2. **Sistem buat booking** terlebih dahulu
3. **Generate QR Code** via Xendit QR Code API (type: DYNAMIC)
4. **Tampilkan QR Code** ke customer (di PaymentWaitingPage)
5. **Customer scan QR Code** dengan aplikasi mobile banking/e-wallet
6. **Xendit kirim webhook** saat pembayaran berhasil (`qr_code.completed`)
7. **Status berubah** dari `pending` → `paid`
8. **Customer dapat notifikasi** pembayaran berhasil

### Backend Changes:

#### **PaymentService.php - createQRISPayment()**
```php
// Generate QRIS via Xendit REST API
$apiUrl = 'https://api.xendit.co/qr_codes';
$requestData = [
    'external_id' => $externalId,
    'type' => 'DYNAMIC',
    'callback_url' => config('app.url') . '/api/v1/webhooks/xendit',
    'amount' => $totalAmount,
];

// cURL request ke Xendit
$response = curl_exec($ch);
$qrCodeUrl = $response['qr_string']; // QR Code string (base64 atau URL)
```

**Kenapa pakai REST API langsung?**
- ✅ Lebih stabil dari Payment Request API
- ✅ Tidak perlu `for-user-id` header yang menyebabkan error
- ✅ Response lebih simple dan langsung
- ✅ Support di semua akun Xendit (tidak perlu sub-account)

#### **Webhook Handler**
Webhook sudah support QRIS dengan event:
- `qr_code.completed` → pembayaran berhasil
- `qr_code.failed` → pembayaran gagal

Handler akan:
1. Terima webhook dari Xendit
2. Update status payment: `pending` → `paid`
3. Update booking status: `pending` → `paid`
4. Kirim push notification ke customer
5. Decrease available_seats di ride

### Frontend Changes:

#### **payment_selection_page.dart** (Motor, Mobil, Barang)
```dart
// Removed 'cash' option
final List<Map<String, dynamic>> paymentMethods = [
  {
    'id': 'qris',
    'name': 'QRIS',
    'subtitle': 'Scan QR code untuk pembayaran instan',
  },
  // ... BRI, BCA, DANA
];
```

#### **payment_method_page.dart** (Motor, Mobil, Barang)
```dart
// Handle QRIS payment with QR code URL
if (widget.paymentMethod == 'qris') {
  final qrCodeUrl = result['data']['qr_code_url'];
  // Navigate to PaymentWaitingPage with QR code URL
}
```

## Testing

### Mode Development (Dummy Mode):
- Jika `PAYMENT_DUMMY_MODE=true` atau Xendit key tidak valid
- Generate dummy QR code URL untuk testing
- Format: `https://api.xendit.co/qr_codes/dummy_xxx.png`

### Mode Production:
- Set `PAYMENT_DUMMY_MODE=false` di `.env`
- Gunakan Xendit secret key yang valid
- QR Code real akan di-generate oleh Xendit
- Format response: `qr_string` berisi base64 image atau URL

## API Response Format

### QRIS Payment Response:
```json
{
  "success": true,
  "message": "Payment created successfully",
  "data": {
    "payment": {
      "id": 1,
      "payment_method": "qris",
      "amount": "50000.00",
      "admin_fee": "15000.00",
      "total_amount": "65000.00",
      "qr_code_url": "data:image/png;base64,iVBOR...",
      "status": "pending"
    },
    "qr_code_url": "data:image/png;base64,iVBOR...",
    "expires_at": "2026-02-03T02:29:45.000000Z"
  }
}
```

### Xendit QR Code API Response:
```json
{
  "id": "qr_123456",
  "external_id": "QRIS-FR-xxx-1234567890",
  "amount": 65000,
  "qr_string": "00020101021126...",  // <- QR Code content
  "callback_url": "https://yourapp.com/webhook",
  "type": "DYNAMIC",
  "status": "ACTIVE",
  "created": "2026-02-03T01:29:45.123Z",
  "updated": "2026-02-03T01:29:45.123Z"
}
```

## Metode Pembayaran Tersedia

1. **QRIS** - QR Code via Xendit (Rp 15.000 admin fee)
2. **BRI Virtual Account** - Transfer bank BRI (Rp 15.000 admin fee)
3. **BCA Virtual Account** - Transfer bank BCA (Rp 15.000 admin fee)
4. **DANA** - E-wallet DANA (Rp 15.000 admin fee)

## Error Fix History

### Error 1: Header 'for-user-id' is not in a valid XenPlatform sub-account ID format
**Root Cause:**
- Payment Request API memerlukan `for-user-id` header dengan format sub-account khusus
- Tidak semua akun Xendit punya akses ke sub-account feature

**Solution:**
- ✅ Switch dari Payment Request API ke **QR Code REST API**
- ✅ Menggunakan cURL direct request
- ✅ Lebih sederhana dan tidak perlu sub-account

## Next Steps

### Frontend Enhancement:
- [ ] Update `PaymentWaitingPage` untuk render QR Code image dari base64
- [ ] Tambah library untuk display QR Code (misalnya pakai `Image.network` atau `Image.memory`)
- [ ] Tambah instruksi scan QR Code untuk customer
- [ ] Auto-refresh status payment setiap 5 detik

### Backend Enhancement:
- [x] Handle Xendit webhook untuk QRIS payment ✅
- [x] Update payment status otomatis saat terima webhook ✅
- [x] Send push notification ke customer saat payment berhasil ✅

## Files Modified

### Backend:
- `backend/app/Services/PaymentService.php` 
  - ✅ Added `createQRISPayment()` method
  - ✅ Use Xendit QR Code REST API (cURL)
- `backend/app/Http/Controllers/Api/PaymentController.php` - Handle QRIS payment
- `backend/app/Models/Payment.php` - Added `qr_code_url` to fillable
- `backend/database/migrations/2026_02_03_012945_add_qr_code_url_to_payments_table.php` - New migration

### Frontend:
- `customer-mitra/frontend/lib/screens/customer/nebeng_motor/pages/payment_selection_page.dart`
- `customer-mitra/frontend/lib/screens/customer/nebeng_mobil/pages/payment_selection_page.dart`
- `customer-mitra/frontend/lib/screens/customer/nebeng_barang/pages/payment_selection_page.dart`
- `customer-mitra/frontend/lib/screens/customer/nebeng_motor/pages/payment_method_page.dart`
- `customer-mitra/frontend/lib/screens/customer/nebeng_mobil/pages/payment_method_page.dart`
- `customer-mitra/frontend/lib/screens/customer/nebeng_barang/pages/payment_method_page.dart`

## Webhook Events

### QRIS Webhook Events:
```json
// Event: qr_code.completed (Payment Success)
{
  "event": "qr_code.completed",
  "data": {
    "id": "qr_123456",
    "external_id": "QRIS-FR-xxx-1234567890",
    "amount": 65000,
    "status": "COMPLETED"
  }
}

// Event: qr_code.failed (Payment Failed)
{
  "event": "qr_code.failed",
  "data": {
    "id": "qr_123456",
    "external_id": "QRIS-FR-xxx-1234567890",
    "status": "FAILED"
  }
}
```

---
**Tanggal Update:** 3 Februari 2026  
**Status:** ✅ Fixed - Error resolved, menggunakan QR Code REST API
**Last Error:** ❌ Header 'for-user-id' error → ✅ Fixed dengan switch ke REST API
