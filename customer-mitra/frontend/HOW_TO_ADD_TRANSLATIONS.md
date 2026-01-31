# Cara Menerapkan Translations ke Halaman Lain

## Yang Sudah Diimplementasi

✅ **Bottom Navigation** (Beranda, Riwayat, Pesan, Profil)
✅ **Profile Page** (semua menu)
✅ **Language Page** (selector bahasa)

## Cara Menerapkan ke Halaman Lain

### 1. Import easy_localization
Tambahkan di bagian atas file:
```dart
import 'package:easy_localization/easy_localization.dart';
```

### 2. Ganti Hardcoded Text dengan .tr()

**Sebelum:**
```dart
Text('Nebeng Motor')
```

**Sesudah:**
```dart
Text('nebeng_motor'.tr())
```

### 3. Pastikan Key Ada di Translation Files

Cek file `assets/translations/id.json` dan `en.json`:
```json
{
  "nebeng_motor": "Nebeng Motor"  // untuk id.json
}
```

```json
{
  "nebeng_motor": "Ride Motor"  // untuk en.json
}
```

### 4. Hot Restart Aplikasi

Setelah menambahkan translations:
- Tekan `R` di terminal Flutter
- Atau klik tombol Restart di VS Code
- Atau `Ctrl+Shift+F5`

## Contoh Implementasi di Berbagai Widget

### AppBar Title
```dart
AppBar(
  title: Text('profile'.tr()),
)
```

### Button Text
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('save'.tr()),
)
```

### SnackBar
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('success'.tr())),
)
```

### Dialog
```dart
AlertDialog(
  title: Text('confirmation'.tr()),
  content: Text('are_you_sure_logout'.tr()),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('no'.tr()),
    ),
    TextButton(
      onPressed: () {},
      child: Text('yes'.tr()),
    ),
  ],
)
```

### List Items
```dart
ListView(
  children: [
    ListTile(
      title: Text('edit_profile'.tr()),
      subtitle: Text('change_your_info'.tr()),
    ),
  ],
)
```

## Tips

1. **Gunakan snake_case untuk keys**: `nebeng_motor`, `edit_profile`, `change_password`
2. **Hindari spasi dalam keys**: Gunakan underscore
3. **Konsisten antara id.json dan en.json**: Pastikan key sama di kedua file
4. **Test dengan hot restart**: Bukan hot reload
5. **Gunakan AppLocalizations helper** untuk type-safety (opsional)

## File-file yang Perlu Diupdate

Untuk implementasi lengkap, update file-file berikut:

### Halaman Utama
- [ ] `beranda_page.dart` - Service cards, headers, buttons
- [ ] `riwayat_page.dart` - Tab names, status text
- [ ] `chats_page.dart` - Headers, empty state

### Booking Pages
- [ ] `nebeng_motor_page.dart` - Form labels, buttons
- [ ] `nebeng_mobil_page.dart` - Form labels, buttons
- [ ] `nebeng_barang/pages/nebeng_barang_page.dart` - Labels, buttons
- [ ] `barang_umum/pages/barang_umum_page.dart` - Labels, buttons

### Detail Pages
- [ ] Booking detail pages - Labels, status, buttons
- [ ] Payment pages - Instructions, confirmations

### Dialogs & Modals
- [ ] Error messages
- [ ] Confirmation dialogs
- [ ] Success messages

## Langkah Cepat untuk Update Halaman Baru

1. Buka file yang ingin diupdate
2. Tambahkan import: `import 'package:easy_localization/easy_localization.dart';`
3. Find & Replace:
   - Cari: `Text('Nama Text')`
   - Ganti dengan: `Text('nama_text'.tr())`
4. Tambahkan key di `id.json` dan `en.json`
5. Hot restart aplikasi

## Automation (Advanced)

Untuk update massal, Anda bisa:
1. Buat list semua hardcoded strings
2. Generate translation files
3. Replace secara batch menggunakan regex
4. Verifikasi satu per satu

---

**Note:** Implementasi bertahap lebih aman daripada update semua sekaligus. Mulai dari halaman yang sering digunakan.
