# Rides Module - Mitra

Modul ini mengatur fitur pembuatan dan manajemen tebengan untuk mitra.

## Struktur Folder

```
rides/
├── pages/                          # Halaman-halaman utama
│   ├── create_ride_page.dart       # Form pembuatan tebengan baru
│   ├── detail_ride_page.dart       # Halaman preview/detail sebelum submit
│   └── ride_success_page.dart      # Halaman konfirmasi berhasil
│
└── widgets/                        # Komponen UI yang dapat digunakan ulang
    ├── location_card.dart          # Card untuk menampilkan lokasi
    ├── info_card.dart              # Card untuk menampilkan info umum
    ├── location_picker.dart        # Modal pemilihan lokasi
    ├── time_picker_modal.dart      # Modal custom pemilihan waktu (24 jam)
    ├── service_type_selector.dart  # Modal pemilihan jenis layanan
    └── vehicle_details_dialog.dart # Dialog input detail kendaraan
```

## Flow Pembuatan Tebengan

1. **CreateRidePage** - Mitra mengisi form:
   - Lokasi awal dan tujuan
   - Tanggal dan waktu keberangkatan
   - Jenis layanan (tebengan/barang/both)
   - Detail kendaraan dan tarif

2. **DetailRidePage** - Preview data sebelum submit:
   - Menampilkan ringkasan semua data
   - Validasi sebelum submit ke API
   - Tombol "Buat tebengan" untuk konfirmasi

3. **RideSuccessPage** - Konfirmasi berhasil:
   - Badge success dengan animasi
   - Tombol navigasi ke daftar tebengan

## Widgets

### LocationCard
Card untuk menampilkan dan memilih lokasi dengan icon warna berbeda (hijau untuk asal, merah untuk tujuan).

### InfoCard
Card generik untuk menampilkan informasi dengan icon dan dapat diklik.

### LocationPicker
Modal bottom sheet dengan daftar lokasi yang dapat dicari dan dipilih.

### TimePickerModal
Custom time picker dengan tampilan 24 jam (tanpa AM/PM), menggunakan gradient background biru-ungu.

### ServiceTypeSelector
Modal untuk memilih jenis layanan: Tebengan, Barang, atau Both.

### VehicleDetailsDialog
Dialog form untuk input detail kendaraan (nama, plat, merk, tipe, warna) dan tarif.

## Penggunaan

```dart
// Navigasi ke halaman create ride
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CreateRidePage(),
  ),
);
```

## Dependencies

- `flutter/material.dart` - UI Framework
- `shared_preferences` - Menyimpan API token
- `api_service.dart` - HTTP requests ke backend

## API Integration

Modul ini terintegrasi dengan endpoint:
- `POST /api/v1/rides` - Membuat tebengan baru

## Notes

- Semua waktu menggunakan format 24 jam
- Validasi dilakukan di sisi client sebelum submit
- Token authentication disimpan di SharedPreferences
