# Implementasi Multi-Language (Localization) dengan Easy Localization

## Overview
Aplikasi Nebeng sekarang mendukung multi-bahasa dengan menggunakan package `easy_localization`. 

## Bahasa yang Didukung
- 🇮🇩 Bahasa Indonesia (id)
- 🇬🇧 English (en)

## Struktur File

### 1. Translation Files
Lokasi: `assets/translations/`
- `id.json` - Terjemahan Bahasa Indonesia
- `en.json` - Terjemahan Bahasa Inggris

### 2. Helper Class
Lokasi: `lib/utils/app_localizations.dart`
- Class helper untuk akses mudah ke translations

### 3. Main Configuration
File `lib/main.dart` sudah dikonfigurasi dengan:
- `EasyLocalization` wrapper
- Supported locales: id, en
- Fallback locale: id (Indonesian)
- Translation path: `assets/translations`

## Cara Menggunakan

### Metode 1: Menggunakan `.tr()` Extension
```dart
Text('language'.tr())  // Output: "Bahasa" atau "Language"
```

### Metode 2: Menggunakan Helper Class (Recommended)
```dart
import 'package:nebeng/utils/app_localizations.dart';

Text(AppLocalizations.language)  // Lebih clean dan type-safe
```

### Metode 3: Direct Key dengan Easy Localization
```dart
Text('profile'.tr())
Text('edit_profile'.tr())
Text('logout'.tr())
```

## Menambah Terjemahan Baru

1. Tambahkan key di `assets/translations/id.json`:
```json
{
  "new_feature": "Fitur Baru"
}
```

2. Tambahkan terjemahan di `assets/translations/en.json`:
```json
{
  "new_feature": "New Feature"
}
```

3. (Opsional) Tambahkan di helper class `app_localizations.dart`:
```dart
static String get newFeature => 'new_feature'.tr();
```

4. Gunakan di kode:
```dart
Text('new_feature'.tr())
// atau
Text(AppLocalizations.newFeature)
```

## Mengganti Bahasa

### Via UI (Language Page)
User dapat mengganti bahasa melalui:
Profile → Bahasa → Pilih bahasa

### Programmatically
```dart
// Ganti ke Bahasa Indonesia
await context.setLocale(Locale('id'));

// Ganti ke English
await context.setLocale(Locale('en'));
```

## Fitur yang Sudah Diimplementasi

✅ Profile Page dengan semua menu menggunakan translations
✅ Language Page untuk mengganti bahasa
✅ Helper class untuk akses mudah
✅ Auto-save preference ke SharedPreferences
✅ Real-time language change tanpa restart app

## File yang Sudah Diupdate

1. `pubspec.yaml` - Menambahkan `easy_localization` package
2. `lib/main.dart` - Setup EasyLocalization
3. `lib/screens/customer/profile/profile_page.dart` - Menggunakan translations
4. `lib/screens/customer/profile/language_page.dart` - Implementasi language selector
5. `assets/translations/id.json` - Terjemahan Bahasa Indonesia
6. `assets/translations/en.json` - Terjemahan English
7. `lib/utils/app_localizations.dart` - Helper class

## Testing

Untuk test implementasi:

1. Jalankan aplikasi:
```bash
flutter run
```

2. Buka Profile → Bahasa
3. Pilih bahasa yang diinginkan
4. Lihat perubahan text di profile page secara real-time

## Next Steps (Opsional)

Untuk implementasi lebih lengkap:

1. Tambahkan translations untuk halaman lain (Home, Order, History, dll)
2. Tambahkan lebih banyak bahasa (Arab, Mandarin, dll)
3. Implementasi RTL support untuk bahasa Arab
4. Tambahkan translations untuk error messages
5. Tambahkan translations untuk validation messages

## Troubleshooting

### Jika text tidak berubah:
1. Pastikan file translation ada di `assets/translations/`
2. Pastikan key sudah ditambahkan di both `id.json` dan `en.json`
3. Restart aplikasi dengan hot restart (bukan hot reload)

### Jika muncul error saat build:
```bash
flutter clean
flutter pub get
flutter run
```

## References

- [Easy Localization Documentation](https://pub.dev/packages/easy_localization)
- [Flutter Internationalization Guide](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
