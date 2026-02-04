# Database Environment Setup

Project ini menggunakan **hybrid database** yang memungkinkan switching antara database lokal dan online.

## File Konfigurasi

- `.env` - File aktif yang digunakan saat ini (auto-generated, jangan edit manual)
- `.env.local` - Konfigurasi untuk development dengan database lokal
- `.env.testing` - Konfigurasi untuk testing dengan database Supabase (online)
- `.env.example` - Template konfigurasi

## Quick Start

### 1. Switch ke Database Lokal (Development)

```bash
./switch-db.sh local
```

**Database:** MySQL Local (PHPMyAdmin)
- Host: `127.0.0.1:3306`
- Database: `nebeng_local`
- Username: `root`
- Password: (kosongkan jika default)

**Setup Database Lokal dengan PHPMyAdmin:**

1. **Pastikan MySQL dan PHPMyAdmin sudah running:**
   ```bash
   # Start MySQL (XAMPP)
   sudo /opt/lampp/lampp startmysql
   
   # Atau jika pakai service MySQL native
   sudo systemctl start mysql
   ```

2. **Buka PHPMyAdmin:**
   - URL: http://localhost/phpmyadmin
   - Login: root (password: kosong atau sesuai setup)

3. **Buat Database:**
   - Klik "New" di sidebar kiri
   - Nama database: `nebeng_local`
   - Collation: `utf8mb4_unicode_ci`
   - Klik "Create"

4. **Jalankan Migration Laravel:**
   ```bash
   php artisan migrate
   php artisan db:seed
   ```

**Alternatif: Buat Database via Command Line:**
```bash
mysql -u root -p
CREATE DATABASE nebeng_local CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;

php artisan migrate
php artisan db:seed
```

### 2. Switch ke Database Online (Testing)

```bash
./switch-db.sh testing
```

**Database:** Supabase PostgreSQL (Cloud)
- Sudah terkonfigurasi dengan kredensial Supabase Anda
- Gunakan untuk testing dengan tim atau testing API dari Flutter

### 3. Cara Kerja

Setiap kali Anda run `./switch-db.sh`, script akan:
1. Copy file environment yang dipilih ke `.env`
2. Clear Laravel cache
3. Rebuild configuration cache

## Workflow Recommended

### Untuk Development Sehari-hari:
```bash
./switch-db.sh local
php artisan serve
```
✅ Data Anda aman di lokal
✅ Cepat, tidak perlu internet
✅ Bebas eksperimen tanpa ganggu database testing

### Untuk Testing dengan Flutter/Team:
```bash
./switch-db.sh testing
php artisan serve
```
✅ Data sync dengan tim
✅ Test API dari device/emulator
✅ Test payment integration

## Tips

### Check Database Aktif
```bash
php artisan tinker
>>> DB::connection()->getDatabaseName()
>>> DB::connection()->getDriverName()
```

### Backup Database Lokal
```bash
# Via command line
mysqldump -u root -p nebeng_local > backup_$(date +%Y%m%d).sql

# Atau via PHPMyAdmin: Database → Export → Go
```

### Restore ke Database Lokal
```bash
# Via command line
mysql -u root -p nebeng_local < backup_20260114.sql

# Atau via PHPMyAdmin: Database → Import → Choose file → Go
```

### Reset Database Lokal
```bash
./switch-db.sh local
php artisan migrate:fresh --seed
```

### Sync Data dari Online ke Local
```bash
# Dump dari Supabase
./switch-db.sh testing
php artisan db:seed  # atau gunakan pg_dump jika ada akses direct

# Restore ke local
./switch-db.sh local
php artisan migrate:fresh
# import data
```

## Struktur File

```
backend/
├── .env              ← File aktif (auto-generated)
├── .env.local        ← Database lokal
├── .env.testing      ← Database online (Supabase)
├── .env.example      ← Template
├── switch-db.sh      ← Script switching
└── database/
    ├── migrations/
    ├── seeders/
    └── database.sqlite  ← Untuk SQLite (opsional)
```

## Troubleshooting

### Error "Connection refused" atau "Can't connect to MySQL server"
```bash
# Cek status MySQL
sudo systemctl status mysql

# Start MySQL
sudo systemctl start mysql

# Atau jika pakai XAMPP
sudo /opt/lampp/lampp startmysql

# Cek apakah MySQL listening di port 3306
sudo netstat -tlnp | grep 3306
```

### Error "Database does not exist"
```bash
./switch-db.sh local

# Buat database via mysql command
mysql -u root -p -e "CREATE DATABASE nebeng_local;"

# Atau buka PHPMyAdmin dan buat manual
php artisan migrate
```

### Error "Access denied for user 'root'@'localhost'"
```bash
# Reset password MySQL root (jika perlu)
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
FLUSH PRIVILEGES;
EXIT;

# Atau update .env.local dengan password yang benar
```

### Lupa sedang pakai database mana?
```bash
grep "APP_ENV\|DB_HOST" .env
```

## Security Notes

⚠️ **PENTING:**
- File `.env`, `.env.local`, `.env.testing` sudah ada di `.gitignore`
- Jangan commit file yang berisi password database
- Share kredensial database hanya via channel aman (bukan Git)
