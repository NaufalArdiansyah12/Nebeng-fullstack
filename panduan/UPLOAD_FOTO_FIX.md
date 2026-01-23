# Fix Upload Foto - 19 Januari 2026

## Masalah
Foto ter-upload ke database tapi tidak tersimpan di filesystem.

## Penyebab
Penggunaan method upload Laravel yang tidak konsisten:
- `$file->store()` - Kadang tidak reliable
- `$file->storeAs('public', $path)` - Path ganda (public/public/...)

## Solusi
Menggunakan `Storage::disk('public')->put()` yang lebih eksplisit dan reliable.

## File yang Diperbaiki

### 1. VerifikasiCustomerController.php
**Lokasi:** `app/Http/Controllers/Api/VerifikasiCustomerController.php`

**Sebelum:**
```php
$photo->storeAs('public', $filename);
Storage::delete('public/' . $path);
```

**Sesudah:**
```php
Storage::disk('public')->put($filename, file_get_contents($photo));
Storage::disk('public')->delete($filename);
```

**Upload methods:**
- `uploadFacePhoto()` - Line ~122
- `uploadKtpPhoto()` - Line ~191
- `uploadFaceKtpPhoto()` - Line ~264

**Storage location:** `storage/app/public/verifikasi/{wajah|ktp|wajah_ktp}/`

---

### 2. AuthController.php
**Lokasi:** `app/Http/Controllers/Api/AuthController.php`

**Sebelum:**
```php
$path = $file->store('public/profile_photos');
$user->profile_photo = Storage::url($path);
```

**Sesudah:**
```php
$filename = 'profile_photos/' . $user->id . '_' . time() . '.' . $file->getClientOriginalExtension();
Storage::disk('public')->put($filename, file_get_contents($file));
$user->profile_photo = Storage::url($filename);
```

**Method:** `updateProfile()` - Line ~183

**Storage location:** `storage/app/public/profile_photos/`

---

### 3. BookingController.php
**Lokasi:** `app/Http/Controllers/Api/BookingController.php`

**Sebelum:**
```php
$photo->storeAs('public/uploads', $filename);
$photoPath = '/storage/uploads/' . $filename;
```

**Sesudah:**
```php
$filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
Storage::disk('public')->put($filename, file_get_contents($photo));
$photoPath = '/storage/' . $filename;
```

**Method:** `createBooking()` - Line ~122

**Storage location:** `storage/app/public/uploads/`

**Use case:** Upload foto untuk booking barang dan titip barang

---

### 4. RideController.php
**Lokasi:** `app/Http/Controllers/Api/RideController.php`

**Sebelum:**
```php
$path = $file->store('uploads', 'public');
$url = '/storage/' . $path;
```

**Sesudah:**
```php
$filename = 'uploads/' . time() . '_' . uniqid() . '.' . $file->getClientOriginalExtension();
Storage::disk('public')->put($filename, file_get_contents($file));
$url = '/storage/' . $filename;
```

**Method:** `createRide()` (dalam closure barang) - Line ~260

**Storage location:** `storage/app/public/uploads/`

**Use case:** Upload foto saat membuat ride untuk barang

---

### 5. BookingTitipBarangController.php
**Lokasi:** `app/Http/Controllers/Api/BookingTitipBarangController.php`

**Sebelum:**
```php
$photo->storeAs('public/uploads', $filename);
$photoPath = '/storage/uploads/' . $filename;
```

**Sesudah:**
```php
$filename = 'uploads/' . time() . '_' . uniqid() . '.' . $photo->getClientOriginalExtension();
Storage::disk('public')->put($filename, file_get_contents($photo));
$photoPath = '/storage/' . $filename;
```

**Method:** `createBooking()` - Line ~48

**Storage location:** `storage/app/public/uploads/`

**Use case:** Upload foto untuk booking titip barang

---

## Struktur Folder Storage

```
storage/app/public/
├── profile_photos/      # Foto profil user
├── uploads/            # Foto booking barang/titip barang dan ride
└── verifikasi/         # Foto verifikasi KTP
    ├── wajah/         # Foto wajah
    ├── ktp/           # Foto KTP
    └── wajah_ktp/     # Foto selfie dengan KTP
```

## Testing

Test storage berfungsi dengan:
```bash
php backend/test-storage.php
```

Output yang benar:
```
✓ File created: verifikasi/wajah/test_xxx.txt
✓ File exists at: /path/to/storage/app/public/verifikasi/wajah/test_xxx.txt
✓ File content: Test content - 2026-01-19 HH:MM:SS
```

## Catatan Penting

1. **Symbolic Link**: Pastikan `php artisan storage:link` sudah dijalankan
2. **Permissions**: Folder storage harus writable (775 atau 755)
3. **Disk Configuration**: File `config/filesystems.php` sudah dikonfigurasi dengan benar
4. **Konsistensi**: Semua upload sekarang menggunakan `Storage::disk('public')->put()`
5. **URL Access**: Foto dapat diakses via `/storage/{path}` (contoh: `/storage/verifikasi/wajah/1_123456.jpg`)

## Keuntungan Metode Ini

✅ **Konsisten** - Semua upload menggunakan method yang sama
✅ **Reliable** - Lebih eksplisit, tidak ada ambiguitas path
✅ **Debuggable** - Lebih mudah di-trace saat ada error
✅ **Testable** - Bisa di-test dengan mudah
✅ **Maintainable** - Code lebih mudah dipahami dan di-maintain
