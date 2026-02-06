# 💰 Panduan Tarik Saldo Mitra

## Overview
Fitur Tarik Saldo memungkinkan mitra untuk menarik saldo mereka ke rekening bank yang telah terverifikasi. Proses penarikan dilengkapi dengan verifikasi PIN dan tracking progress secara real-time.

## Database Schema

### Tabel: `withdrawals`
Menyimpan data penarikan saldo mitra.

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Primary key |
| user_id | BIGINT | Foreign key ke users |
| transaction_id | VARCHAR | ID transaksi unik (WD + timestamp) |
| amount | DECIMAL(15,2) | Jumlah yang ditarik |
| admin_fee | DECIMAL(15,2) | Biaya admin |
| total_amount | DECIMAL(15,2) | Total yang diterima |
| bank_name | VARCHAR | Nama bank |
| bank_account_number | VARCHAR | Nomor rekening |
| bank_account_name | VARCHAR | Nama pemilik rekening |
| status | ENUM | pending, verifying, approved, processing, transferring, completed, rejected, refunded |
| submitted_at | TIMESTAMP | Waktu pengajuan |
| verified_at | TIMESTAMP | Waktu verifikasi |
| approved_at | TIMESTAMP | Waktu persetujuan |
| processing_at | TIMESTAMP | Waktu pemrosesan |
| completed_at | TIMESTAMP | Waktu selesai |
| rejected_at | TIMESTAMP | Waktu penolakan |
| rejection_reason | TEXT | Alasan penolakan |
| notes | TEXT | Catatan tambahan |
| processed_by | BIGINT | Admin yang memproses |

### Update Tabel: `users`
Ditambahkan kolom:
- `pin` (VARCHAR, 6 digit, hashed) - PIN untuk verifikasi penarikan

## API Endpoints

### 1. Get Balance Info
**GET** `/api/v1/mitra/withdrawal/balance`

**Headers:**
```
Authorization: Bearer {token}
```

**Response Success (200):**
```json
{
  "success": true,
  "data": {
    "name": "Kamado Tanjiro",
    "balance": 200000,
    "bank_name": "BRI",
    "bank_account_number": "129519285192518417",
    "bank_account_name": "Kamado Tanjiro"
  }
}
```

### 2. Submit Withdrawal
**POST** `/api/v1/mitra/withdrawal/submit`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Body:**
```json
{
  "amount": 50000,
  "pin": "123456"
}
```

**Response Success (200):**
```json
{
  "success": true,
  "message": "Pengajuan pencairan berhasil diajukan",
  "data": {
    "withdrawal_id": 1,
    "transaction_id": "WD20260204123456789"
  }
}
```

**Response Error (400):**
```json
{
  "success": false,
  "message": "PIN yang Anda masukkan salah"
}
```

### 3. Get Withdrawal Detail
**GET** `/api/v1/mitra/withdrawal/{id}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "transaction_id": "WD20260204123456789",
    "amount": 50000,
    "admin_fee": 0,
    "total_amount": 50000,
    "bank_name": "BRI",
    "bank_account_number": "129519285192518417",
    "bank_account_name": "Kamado Tanjiro",
    "status": "processing",
    "submitted_at": "21 Okt 2024 | 09:00 WIB",
    "progress": [
      {
        "title": "Pengajuan Telah Diajukan",
        "description": "Proses Pencairan dana sedang berlangsung...",
        "date": "Senin, 21 Okt",
        "time": "09:00 WIB",
        "completed": true
      },
      ...
    ]
  }
}
```

### 4. Check Withdrawal Status
**GET** `/api/v1/mitra/withdrawal/{id}/status`

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "completed",
    "is_completed": true,
    "progress": [...]
  }
}
```

### 5. Get Withdrawal History
**GET** `/api/v1/mitra/withdrawal/history/list`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "transaction_id": "WD20260204123456789",
      "amount": 50000,
      "status": "completed",
      "bank_name": "BRI",
      "submitted_at": "21 Okt 2024"
    }
  ]
}
```

### 6. Set/Update PIN
**POST** `/api/v1/mitra/pin/set`

**Body:**
```json
{
  "pin": "123456",
  "pin_confirmation": "123456"
}
```

### 7. Verify PIN
**POST** `/api/v1/mitra/pin/verify`

**Body:**
```json
{
  "pin": "123456"
}
```

## Flutter Pages

### 1. Tarik Saldo Page (`tarik_saldo_page.dart`)
Halaman utama untuk input jumlah penarikan.

**Features:**
- Menampilkan informasi saldo dan rekening bank
- Input jumlah dengan format ribuan (1.500.000)
- Validasi minimal Rp 50.000
- Validasi saldo mencukupi
- Navigasi ke halaman PIN verification

**Navigate to:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TarikSaldoPage(),
  ),
);
```

### 2. PIN Verification Page (`pin_verification_page.dart`)
Halaman untuk input PIN 6 digit.

**Features:**
- Input PIN dengan 6 field terpisah
- Auto-focus ke field berikutnya
- Auto-submit saat PIN lengkap
- Obscure text untuk keamanan
- Error handling

### 3. Withdrawal Progress Page (`withdrawal_progress_page.dart`)
Halaman untuk menampilkan progress penarikan.

**Features:**
- Progress timeline dengan 5 tahapan
- Auto-refresh status setiap 3 detik
- Detail rincian dana
- Auto-navigate ke success page saat completed

**Progress Steps:**
1. Pengajuan Telah Diajukan
2. Memeriksa Pengajuan Anda
3. Pengajuan Disetujui
4. Pencairan Sedang Dikirim
5. Pencairan Telah DiTransfer

### 4. Withdrawal Success Page (`withdrawal_success_page.dart`)
Halaman konfirmasi penarikan berhasil.

**Features:**
- Tampilan success dengan icon
- Detail transaksi lengkap
- Informasi rekening tujuan
- Button kembali ke home

## Testing

### Setup Test Data
```bash
cd backend
php artisan migrate
php artisan db:seed --class=WithdrawalSeeder
```

Data yang dibuat:
- User mitra: `mitra@example.com` / `password`
- Balance: Rp 200.000
- PIN: `123456`
- Bank: BRI - 129519285192518417

### Manual Testing Flow

1. **Login sebagai Mitra**
   - Email: `mitra@example.com`
   - Password: `password`

2. **Buka Halaman Tarik Saldo**
   - Cek informasi saldo (Rp 200.000)
   - Cek informasi rekening (BRI - 129519285192518417)

3. **Input Jumlah Penarikan**
   - Coba input < Rp 50.000 (error: minimal penarikan)
   - Coba input > Rp 200.000 (error: saldo tidak mencukupi)
   - Input Rp 50.000 - valid

4. **Verifikasi PIN**
   - Input PIN: `123456`
   - Sistem akan submit otomatis saat 6 digit lengkap

5. **Lihat Progress**
   - Halaman progress otomatis muncul
   - Status diupdate setiap 3 detik
   - Setelah ~20 detik akan completed

6. **Success Page**
   - Tampilan konfirmasi berhasil
   - Detail transaksi lengkap

### Validasi Error Cases

**Case 1: Saldo Tidak Cukup**
```
Input: Rp 1.500.000 (saldo Rp 200.000)
Expected: "Jumlah saldo tidak mencukupi"
```

**Case 2: PIN Salah**
```
Input: 999999
Expected: "PIN yang Anda masukkan salah"
```

**Case 3: Minimal Penarikan**
```
Input: Rp 30.000
Expected: "Minimal penarikan Rp 50.000"
```

**Case 4: Bank Tidak Terverifikasi**
```
User tanpa bank verification
Expected: "Anda belum memiliki rekening bank yang terverifikasi"
```

## Production Notes

### Auto-Progress Simulation
Untuk demo, sistem otomatis memproses penarikan melalui semua tahapan:
```php
$withdrawal->update([
    'status' => 'processing',
    'verified_at' => now()->addSeconds(5),
    'approved_at' => now()->addSeconds(10),
    'processing_at' => now()->addSeconds(15),
]);
```

Di production:
- Tahapan dikontrol oleh admin melalui dashboard
- Atau menggunakan cron job untuk auto-approve berdasarkan kriteria
- Transfer dilakukan ke bank menggunakan payment gateway

### Security Considerations

1. **PIN Storage**: PIN disimpan dengan bcrypt hash
2. **PIN Validation**: Minimal 6 digit angka
3. **Balance Check**: Validasi saldo sebelum proses
4. **Transaction ID**: Unique untuk setiap transaksi
5. **Authorization**: Semua endpoint memerlukan Bearer token

### Admin Features (Future Development)

Dashboard admin untuk:
- Approve/reject withdrawal request
- Set admin fee
- View pending withdrawals
- Process manual transfer
- Add rejection notes

## Troubleshooting

### Error: Token tidak ditemukan
```
Pastikan user sudah login dan token tersimpan di SharedPreferences
```

### Error: Database connection
```
Cek konfigurasi database di .env
php artisan migrate
```

### Error: Bank tidak terverifikasi
```
Jalankan seeder:
php artisan db:seed --class=WithdrawalSeeder
```

## File Structure

```
backend/
├── app/
│   ├── Http/Controllers/Mitra/
│   │   └── WithdrawalController.php
│   └── Models/
│       └── Withdrawal.php
├── database/
│   ├── migrations/
│   │   ├── 2026_02_04_100000_create_withdrawals_table.php
│   │   └── 2026_02_04_100001_add_pin_to_users_table.php
│   └── seeders/
│       └── WithdrawalSeeder.php
└── routes/
    └── api.php (withdrawal routes)

customer-mitra/frontend/
├── lib/
│   ├── models/
│   │   └── withdrawal_model.dart
│   ├── services/
│   │   └── withdrawal_service.dart
│   └── screens/mitra/withdrawal/
│       ├── tarik_saldo_page.dart
│       ├── pin_verification_page.dart
│       ├── withdrawal_progress_page.dart
│       └── withdrawal_success_page.dart
```

## Next Steps

1. Integrasi dengan payment gateway untuk transfer otomatis
2. Tambah notifikasi push untuk setiap tahapan
3. Admin dashboard untuk manage withdrawals
4. Export riwayat penarikan ke PDF/Excel
5. Tambah fitur ganti PIN
6. Implementasi biaya admin dinamis
