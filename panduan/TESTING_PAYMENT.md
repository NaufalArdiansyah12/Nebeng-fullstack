# Testing Payment Flow

## Cara Testing Pembayaran

Karena saat ini menggunakan **Dummy Mode** (tidak menggunakan real Xendit API), ada beberapa cara untuk testing:

---

## **Metode 1: Simulasi Payment via API (Recommended)**

Ini cara paling mudah dan cepat untuk testing.

### Step 1: Lihat Payment ID
Setelah klik "Bayar" dan muncul halaman countdown, buka **Developer Console** di browser:
- Chrome/Edge: Press `F12` atau `Ctrl+Shift+I`
- Lihat **Network tab**
- Cari request ke `/api/v1/payments` 
- Lihat response, catat `payment.id` nya

Atau lihat dari URL check status yang dipanggil setiap 5 detik:
- Contoh: `http://127.0.0.1:8000/api/v1/payments/1/status`
- Payment ID adalah angka sebelum `/status` (dalam contoh: `1`)

### Step 2: Simulasi Pembayaran Berhasil
Gunakan curl atau Postman untuk hit endpoint simulasi:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/payments/test/1/simulate
```

Ganti `1` dengan payment ID yang sebenarnya.

**Response Success:**
```json
{
  "success": true,
  "message": "Payment simulated successfully",
  "data": {
    "id": 1,
    "status": "paid",
    "paid_at": "2026-01-08T07:23:45.000000Z",
    ...
  }
}
```

### Step 3: Otomatis Redirect
Setelah hit endpoint simulasi, dalam 5 detik halaman Flutter akan:
- ✅ Auto-detect payment berhasil
- ✅ Redirect ke halaman "Pembayaran Berhasil"

---

## **Metode 2: Update Manual via Database**

Jika lebih suka update langsung di database:

```bash
# Masuk ke directory backend
cd /home/naufal/project/nebeng-fullstack/backend

# Buka Laravel Tinker
php artisan tinker
```

Kemudian jalankan:

```php
// Cari payment berdasarkan booking number atau ID
$payment = App\Models\Payment::find(1); // atau
$payment = App\Models\Payment::where('booking_number', 'FR-1767853401882')->first();

// Update status menjadi paid
$payment->update([
    'status' => 'paid',
    'paid_at' => now()
]);

// Update ride payment status (optional)
$payment->ride->update(['payment_status' => 'paid']);

echo "Payment updated successfully!";
```

---

## **Metode 3: Lihat Semua Pending Payments**

Untuk melihat semua payment yang pending:

```bash
curl http://127.0.0.1:8000/api/v1/payments/test/pending
```

Response akan menampilkan semua payment dengan status `pending`:
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "booking_number": "FR-1767853401882",
      "virtual_account_number": "908812751710037",
      "status": "pending",
      "total_amount": "65000.00",
      "expires_at": "2026-01-08T08:23:45.000000Z",
      ...
    }
  ]
}
```

---

## **Testing Scenarios**

### ✅ **Scenario 1: Payment Success**
1. User klik "Bayar"
2. Muncul halaman countdown dengan VA number
3. **Simulasikan pembayaran** (gunakan Metode 1 atau 2)
4. Auto-redirect ke halaman success dalam 5 detik

### ⏰ **Scenario 2: Payment Expired**
1. User klik "Bayar"
2. Muncul halaman countdown
3. **Tunggu sampai countdown habis** (1 jam, atau ubah di code jadi 1 menit untuk testing)
4. Muncul dialog "Pembayaran Kedaluwarsa"

### 🔄 **Scenario 3: Manual Check Status**
1. User klik "Bayar"
2. Muncul halaman countdown
3. User klik tombol "**Cek Status Pembayaran**"
4. Jika belum bayar: muncul "Pembayaran belum diterima"
5. Jika sudah bayar: redirect ke halaman success

### 💰 **Scenario 4: Cash Payment**
1. User pilih metode pembayaran "**Tunai**"
2. Klik "Bayar"
3. Langsung redirect ke halaman success (tidak ada VA number)

---

## **Quick Testing Script**

Buat file bash script untuk testing cepat:

```bash
#!/bin/bash
# test-payment.sh

PAYMENT_ID=$1

if [ -z "$PAYMENT_ID" ]; then
    echo "Usage: ./test-payment.sh <payment_id>"
    echo ""
    echo "Getting pending payments..."
    curl -s http://127.0.0.1:8000/api/v1/payments/test/pending | jq '.data[] | {id, booking_number, status}'
    exit 1
fi

echo "Simulating payment success for Payment ID: $PAYMENT_ID"
curl -X POST http://127.0.0.1:8000/api/v1/payments/test/$PAYMENT_ID/simulate | jq '.'
```

Cara pakai:
```bash
chmod +x test-payment.sh
./test-payment.sh 1
```

---

## **Tips Development**

1. **Percepat Testing Expiration:**
   Edit `PaymentService.php` line yang set expiration:
   ```php
   // Dari:
   $expiresAt = Carbon::now()->addHour();
   
   // Jadi (1 menit untuk testing):
   $expiresAt = Carbon::now()->addMinute();
   ```

2. **Lihat Log:**
   ```bash
   tail -f storage/logs/laravel.log
   ```

3. **Clear Cache jika Update Code:**
   ```bash
   php artisan config:clear
   ```

4. **Check Database:**
   ```bash
   php artisan tinker
   >>> App\Models\Payment::latest()->first()
   ```

---

## **Untuk Production dengan Real Xendit**

Ketika siap production:

1. **Set Real Xendit API Key:**
   ```env
   XENDIT_SECRET_KEY=xnd_production_your_real_key
   PAYMENT_DUMMY_MODE=false
   ```

2. **Setup Webhook:**
   - Xendit Dashboard → Settings → Webhooks
   - URL: `https://yourdomain.com/api/v1/payments/webhook`
   - Token: sesuai dengan `XENDIT_WEBHOOK_TOKEN`

3. **Test Real Payment:**
   - Gunakan Xendit Test Mode dulu
   - Simulate payment dari Xendit Dashboard
   - Verify webhook received

---

## **Troubleshooting**

**Problem:** Halaman tidak auto-redirect setelah simulate
- **Solution:** Check browser console untuk error
- Verify status check API berjalan setiap 5 detik
- Check payment status di database: `status = 'paid'`

**Problem:** Countdown tidak jalan
- **Solution:** Check JavaScript console untuk error
- Verify `expiresAt` timestamp benar

**Problem:** VA number tidak muncul
- **Solution:** Check Laravel log untuk error
- Verify dummy mode active
- Check payment record di database

---

🎉 **Happy Testing!**
