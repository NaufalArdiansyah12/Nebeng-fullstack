# Troubleshooting Email Gmail - Error 535 Authentication Failed

## Error yang Anda Alami

```
Error: Failed to authenticate on SMTP server with username "ranggamagangjogja@gmail.com"
Error 535: Username and Password not accepted
```

## Penyebab Utama

**Anda menggunakan password Gmail biasa, bukan App Password!**

Gmail tidak lagi mengizinkan login dengan password biasa untuk aplikasi pihak ketiga. Anda **WAJIB** menggunakan **App Password**.

## Solusi Step-by-Step

### Langkah 1: Aktifkan 2-Step Verification

1. Buka: https://myaccount.google.com/security
2. Scroll ke bagian **"How you sign in to Google"**
3. Klik **"2-Step Verification"**
4. Ikuti langkah-langkah untuk mengaktifkan 2-Step Verification
   - Anda akan diminta memasukkan nomor telepon
   - Verifikasi dengan kode yang dikirim

**PENTING:** 2-Step Verification **WAJIB AKTIF** sebelum bisa membuat App Password!

### Langkah 2: Buat App Password

1. Setelah 2-Step Verification aktif, kembali ke: https://myaccount.google.com/security
2. Scroll ke bagian **"2-Step Verification"**
3. Klik **"App passwords"** (Kata sandi aplikasi)
   - Jika tidak muncul, pastikan 2-Step Verification sudah aktif minimal 24 jam
4. Di halaman App passwords:
   - **Select app:** Pilih **"Mail"**
   - **Select device:** Pilih **"Other (Custom name)"**
   - Ketik: **"Laravel"** atau **"Finance App"**
   - Klik **"Generate"**
5. **Copy password yang muncul** (16 karakter)
   - Format: `xxxx xxxx xxxx xxxx` (dengan spasi)
   - Atau: `xxxxxxxxxxxxxxxx` (tanpa spasi)
   - **Kedua format bisa digunakan di .env**

### Langkah 3: Update file `.env`

Buka file `backend/.env` dan pastikan konfigurasi seperti ini:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=ranggamagangjogja@gmail.com
MAIL_PASSWORD=xxxx xxxx xxxx xxxx
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=ranggamagangjogja@gmail.com
MAIL_FROM_NAME="Nebeng Finance"

FRONTEND_URL=http://localhost:5173
```

**Catatan penting:**
- `MAIL_PASSWORD` harus App Password yang baru dibuat (16 karakter)
- Bisa dengan spasi atau tanpa spasi, keduanya valid
- Jangan gunakan tanda kutip (`"`) di sekitar password
- `MAIL_USERNAME` harus sama dengan email Gmail Anda

### Langkah 4: Clear Config Cache

Setelah mengubah `.env`, **WAJIB** clear cache:

```bash
cd backend
php artisan config:clear
php artisan cache:clear
```

### Langkah 5: Test Lagi

```bash
php artisan mail:test ranggamagangjogja@gmail.com
```

## Masalah Umum Lainnya

### 1. "App passwords" tidak muncul

**Solusi:**
- Pastikan 2-Step Verification sudah aktif minimal beberapa jam
- Coba akses langsung: https://myaccount.google.com/apppasswords
- Jika masih tidak muncul, gunakan akun Google Workspace (bukan Gmail personal)

### 2. App Password tidak bekerja

**Cek:**
- Pastikan copy-paste password dengan benar (tidak ada spasi ekstra)
- Pastikan tidak ada tanda kutip di `.env`
- Pastikan `MAIL_USERNAME` benar-benar email Gmail Anda
- Coba buat App Password baru

### 3. Masih error setelah menggunakan App Password

**Coba:**
- Gunakan port 465 dengan SSL:
  ```env
  MAIL_PORT=465
  MAIL_ENCRYPTION=ssl
  ```
- Pastikan tidak ada firewall yang memblokir port 587 atau 465
- Cek `storage/logs/laravel.log` untuk error detail

### 4. Email masuk ke Spam

- Pastikan `MAIL_FROM_ADDRESS` sama dengan `MAIL_USERNAME`
- Tambahkan SPF record jika menggunakan custom domain

## Format Password di .env

**BENAR:**
```env
MAIL_PASSWORD=abcd efgh ijkl mnop
```
atau
```env
MAIL_PASSWORD=abcdefghijklmnop
```

**SALAH:**
```env
MAIL_PASSWORD="abcd efgh ijkl mnop"  # Jangan pakai tanda kutip
MAIL_PASSWORD='abcd efgh ijkl mnop'  # Jangan pakai tanda kutip
```

## Verifikasi Konfigurasi

Untuk melihat konfigurasi yang sedang digunakan (tanpa menampilkan password):

```bash
php artisan tinker
```

Kemudian jalankan:
```php
config('mail.mailers.smtp.host')
config('mail.mailers.smtp.port')
config('mail.mailers.smtp.encryption')
config('mail.mailers.smtp.username')
// Password tidak ditampilkan untuk keamanan
```

## Bantuan Lebih Lanjut

Jika masih error setelah mengikuti semua langkah:
1. Cek `storage/logs/laravel.log` untuk error detail
2. Pastikan menggunakan App Password terbaru
3. Coba buat App Password baru
4. Pastikan 2-Step Verification aktif
