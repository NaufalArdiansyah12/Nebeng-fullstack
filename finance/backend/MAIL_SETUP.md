# Setup Email Gmail untuk Reset Password

## Langkah-langkah Setup

### 1. Buat App Password di Gmail

**PENTING:** Anda **WAJIB** menggunakan App Password, bukan password Gmail biasa!

1. Buka [Google Account Settings](https://myaccount.google.com/security)
2. Pilih **Security** (Keamanan)
3. **Aktifkan 2-Step Verification** (WAJIB!):
   - Scroll ke bagian "How you sign in to Google"
   - Klik **"2-Step Verification"**
   - Ikuti langkah-langkah untuk mengaktifkan
   - Verifikasi dengan nomor telepon
4. Setelah 2-Step Verification aktif, kembali ke Security
5. Scroll ke bagian **"2-Step Verification"**, klik **"App passwords"** (Kata sandi aplikasi)
   - Jika tidak muncul, pastikan 2-Step Verification sudah aktif minimal beberapa jam
   - Atau akses langsung: https://myaccount.google.com/apppasswords
6. Di halaman App passwords:
   - **Select app:** Pilih **"Mail"**
   - **Select device:** Pilih **"Other (Custom name)"**
   - Ketik: **"Laravel"** atau **"Finance App"**
   - Klik **"Generate"**
7. **Copy password yang dihasilkan** (16 karakter)
   - Format: `xxxx xxxx xxxx xxxx` (dengan spasi) atau `xxxxxxxxxxxxxxxx` (tanpa spasi)
   - **Kedua format bisa digunakan di .env**

### 2. Konfigurasi di file `.env`

Tambahkan atau update konfigurasi berikut di file `backend/.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-16-char-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="${APP_NAME}"

# Frontend URL untuk link reset password
FRONTEND_URL=http://localhost:5173
```

**Contoh:**
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=admin@example.com
MAIL_PASSWORD=abcd efgh ijkl mnop
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=admin@example.com
MAIL_FROM_NAME="Nebeng Finance"

FRONTEND_URL=http://localhost:5173
```

### 3. Clear Config Cache

Setelah mengubah `.env`, jalankan:

```bash
cd backend
php artisan config:clear
php artisan cache:clear
```

### 4. Test Email

**Cara 1: Menggunakan Artisan Command (Recommended)**

Jalankan command berikut untuk test email:

```bash
cd backend
php artisan mail:test your-email@gmail.com
```

Jika berhasil, Anda akan menerima email test di inbox Anda.

**Cara 2: Test melalui Aplikasi**

1. Jalankan aplikasi
2. Buka halaman Forgot Password
3. Masukkan email yang terdaftar
4. Cek inbox Gmail (atau spam folder)

## Troubleshooting

### Email tidak terkirim / Error 535 Authentication Failed

**Penyebab utama:** Menggunakan password Gmail biasa, bukan App Password!

1. **PASTIKAN menggunakan App Password**: 
   - Bukan password Gmail biasa!
   - App Password adalah 16 karakter yang dibuat di Google Account
   - Lihat `TROUBLESHOOTING_EMAIL.md` untuk panduan lengkap

2. **Cek 2-Step Verification**: 
   - Harus aktif untuk bisa membuat App Password
   - Jika App passwords tidak muncul, pastikan 2-Step Verification aktif minimal beberapa jam

3. **Cek format di .env**:
   - Jangan pakai tanda kutip di sekitar password
   - Contoh benar: `MAIL_PASSWORD=abcd efgh ijkl mnop`
   - Contoh salah: `MAIL_PASSWORD="abcd efgh ijkl mnop"`

4. **Cek port dan encryption**: 
   - Port 587 dengan TLS (recommended)
   - Port 465 dengan SSL (alternatif)

5. **Clear config cache** setelah mengubah .env:
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

6. **Cek log**: Lihat `backend/storage/logs/laravel.log` untuk error detail

**Lihat file `TROUBLESHOOTING_EMAIL.md` untuk panduan lengkap troubleshooting!**

### Error: "Connection could not be established"

- Pastikan `MAIL_HOST=smtp.gmail.com`
- Pastikan `MAIL_PORT=587` dan `MAIL_ENCRYPTION=tls`
- Atau gunakan `MAIL_PORT=465` dan `MAIL_ENCRYPTION=ssl`

### Email masuk ke Spam

- Pastikan `MAIL_FROM_ADDRESS` sama dengan `MAIL_USERNAME`
- Tambahkan SPF record di domain (jika menggunakan custom domain)

## Alternatif: Menggunakan Port 465 (SSL)

Jika port 587 tidak bekerja, gunakan port 465:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=465
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-16-char-app-password
MAIL_ENCRYPTION=ssl
MAIL_FROM_ADDRESS=your-email@gmail.com
MAIL_FROM_NAME="${APP_NAME}"
```
