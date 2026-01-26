# Nebeng Motor Module

Modul untuk fitur booking nebeng motor dengan struktur kode yang terorganisir.

## Struktur Folder

```
nebeng_motor/
├── data/
│   ├── location_data.dart          # Data lokasi & histori alamat
│   └── trip_data.dart              # Data perjalanan tersedia
├── models/
│   └── trip_model.dart             # Model data perjalanan
├── pages/
│   ├── location_picker_page.dart   # Halaman pemilihan lokasi
│   └── trip_list_page.dart         # Halaman daftar perjalanan
├── utils/
│   ├── date_formatter.dart         # Utility untuk format tanggal
│   └── theme.dart                  # Konstanta tema & warna
└── widgets/
    ├── date_input_field.dart       # Widget input tanggal
    ├── form_section.dart           # Widget form section lengkap
    ├── history_section.dart        # Widget section histori alamat
    ├── location_input_field.dart   # Widget input lokasi
    └── trip_card.dart              # Widget card perjalanan
```

## Deskripsi File

### Data Layer
- **location_data.dart**: Menyimpan data statis untuk daftar lokasi (Yogyakarta & Purwokerto) dan histori alamat
- **trip_data.dart**: Menyimpan dan mengelola data perjalanan yang tersedia

### Models
- **trip_model.dart**: Model data untuk perjalanan (trip) dengan informasi lengkap

### Pages
- **location_picker_page.dart**: Halaman fullscreen untuk memilih lokasi dengan fitur search/filter
- **trip_list_page.dart**: Halaman daftar perjalanan tersedia dengan fitur swap direction

### Utils
- **date_formatter.dart**: Utility functions untuk format tanggal (format panjang dan pendek)
- **theme.dart**: Konstanta warna dan tema yang digunakan di seluruh modul

### Widgets
- **location_input_field.dart**: Reusable widget untuk input field lokasi (awal/tujuan)
- **date_input_field.dart**: Reusable widget untuk input field tanggal
- **form_section.dart**: Widget container untuk form dengan 3 input fields
- **history_section.dart**: Widget untuk menampilkan daftar histori alamat
- **trip_card.dart**: Widget card untuk menampilkan informasi perjalanan lengkap

## Main Page
**nebeng_motor_page.dart**: Halaman utama yang mengintegrasikan semua widgets dan logic

## Flow Aplikasi

1. **Halaman Utama (NebengMotorPage)**
   - User memilih lokasi awal
   - User memilih lokasi tujuan
   - User memilih tanggal keberangkatan
   - Klik tombol "Selanjutnya"

2. **Halaman Daftar Perjalanan (TripListPage)**
   - Menampilkan daftar perjalanan yang tersedia
   - Fitur swap direction (tukar arah perjalanan)
   - Setiap card menampilkan:
     - Tanggal dan waktu
     - Lokasi keberangkatan & tujuan
     - Total biaya
     - Tombol "Selanjutnya"

## Keuntungan Struktur Ini

1. **Modular**: Setiap komponen terpisah dan dapat digunakan kembali
2. **Maintainable**: Mudah untuk maintenance dan update
3. **Scalable**: Mudah ditambahkan fitur baru tanpa mengubah struktur
4. **Clean Code**: Code lebih bersih dan mudah dibaca
5. **Separation of Concerns**: Data, UI, dan logic terpisah dengan jelas
6. **Model-based**: Menggunakan model untuk struktur data yang konsisten

## Cara Penggunaan

```dart
import 'package:flutter/material.dart';
import 'screens/customer/nebeng_motor_page.dart';

// Di dalam aplikasi
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NebengMotorPage(),
  ),
);
```
