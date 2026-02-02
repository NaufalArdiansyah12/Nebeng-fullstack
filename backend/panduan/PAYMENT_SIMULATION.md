# Payment Simulation Tools

Tools untuk mempermudah testing payment flow di development.

## 🛠️ Available Tools

### 1. Bash Script (Quick & Simple)

**File:** `simulate_payment.sh`

**Usage:**
```bash
# Interactive mode (akan tampilkan list pending payments)
./simulate_payment.sh

# Direct simulation dengan payment ID
./simulate_payment.sh 123
```

**Features:**
- ✅ List semua pending payments
- ✅ Interactive selection
- ✅ Simulate payment dengan 1 command
- ✅ Pretty formatted output

---

### 2. Artisan Commands (Advanced)

#### A. List Pending Payments

```bash
# List semua pending payments
php artisan payment:pending

# Watch mode (auto-refresh setiap 5 detik)
php artisan payment:pending --watch
```

**Output:**
```
📋 Pending Payments (3)

┌────┬──────────────┬───────────────┬────────┬──────────────┬─────────────────┬──────────────┬────────────┐
│ ID │ User         │ Booking       │ Method │ Amount       │ VA Number       │ Expires At   │ Created    │
├────┼──────────────┼───────────────┼────────┼──────────────┼─────────────────┼──────────────┼────────────┤
│ 1  │ John Doe     │ FR-123456789  │ BRI    │ Rp 65,000    │ 908812751710037 │ 2026-01-14   │ 01-13 14:30│
└────┴──────────────┴───────────────┴────────┴──────────────┴─────────────────┴──────────────┴────────────┘
```

#### B. Simulate Payment

```bash
# Interactive mode
php artisan payment:simulate

# Direct dengan payment ID
php artisan payment:simulate 123
```

**Output:**
```
✅ Payment simulated successfully!

Payment ID: 123
Booking: FR-123456789
Amount: Rp 65,000
Status: paid
Paid At: 2026-01-13 14:35:20
```

---

## 📋 Testing Workflow

### Quick Testing Flow:

1. **Start Laravel server:**
   ```bash
   php artisan serve
   ```

2. **Buat booking dari Flutter app** (atau Postman/curl)

3. **Check pending payments:**
   ```bash
   php artisan payment:pending
   # atau
   ./simulate_payment.sh
   ```

4. **Simulate payment:**
   ```bash
   php artisan payment:simulate 123
   # atau
   ./simulate_payment.sh 123
   ```

5. **Verify di app** - payment status harus berubah ke "paid"

---

## 🔄 Watch Mode (Real-time Monitoring)

Untuk monitor pending payments real-time:

```bash
php artisan payment:pending --watch
```

Output akan auto-refresh setiap 5 detik saat ada perubahan.

**Use case:** Jalankan di terminal terpisah sambil testing dari app.

---

## 🎯 API Endpoints (Alternative)

Jika prefer menggunakan HTTP requests:

### Get Pending Payments
```bash
curl http://127.0.0.1:8000/api/v1/payments/test/pending
```

### Simulate Payment
```bash
curl -X POST http://127.0.0.1:8000/api/v1/payments/test/123/simulate
```

---

## ⚠️ Important Notes

- ✅ Tools ini **hanya tersedia di development mode** (`APP_ENV=local`)
- ✅ Otomatis update **booking status** dan **ride payment_status**
- ✅ Support semua booking types: motor, mobil, barang, titip barang
- ✅ Compatible dengan PostgreSQL (Supabase) dan MySQL

---

## 🐛 Troubleshooting

**Script tidak executable:**
```bash
chmod +x simulate_payment.sh
```

**Command not found:**
```bash
php artisan config:clear
php artisan cache:clear
```

**Python not found (untuk bash script):**
Bash script akan fallback ke raw JSON output jika Python tidak tersedia.

---

## 📝 Examples

### Example 1: Complete Test Flow
```bash
# Terminal 1: Start server
php artisan serve

# Terminal 2: Watch payments
php artisan payment:pending --watch

# Terminal 3: Test dari app atau curl
# Setelah ada payment, simulate:
php artisan payment:simulate
```

### Example 2: Quick Bash Script
```bash
# One-liner untuk simulate payment pertama
./simulate_payment.sh $(curl -s http://127.0.0.1:8000/api/v1/payments/test/pending | grep -oP '"id":\K\d+' | head -1)
```

---

## 🚀 Tips

1. **Gunakan watch mode** saat development untuk monitor payments real-time
2. **Bash script lebih cepat** untuk quick testing
3. **Artisan command lebih informatif** dengan table formatting
4. **Combine dengan Postman** untuk create bookings + simulate payments dalam 1 collection

---

Happy Testing! 🎉
