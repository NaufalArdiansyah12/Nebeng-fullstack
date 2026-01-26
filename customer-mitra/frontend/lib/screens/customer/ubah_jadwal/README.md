# Ubah Jadwal Module

Module untuk mengubah jadwal booking yang sudah ada.

## Struktur Folder

```
ubah_jadwal/
├── ubah_jadwal_page.dart           # Halaman utama untuk memilih tanggal baru
├── ubah_jadwal_list_page.dart      # Halaman daftar jadwal yang tersedia
├── ubah_jadwal_detail_page.dart    # Halaman detail konfirmasi booking baru
├── widgets/
│   ├── date_selector.dart          # Widget untuk memilih tanggal (horizontal selector)
│   └── ride_card.dart              # Widget card untuk menampilkan jadwal perjalanan
└── payment/
    ├── reschedule_payment_page.dart        # Halaman pembayaran ubah jadwal
    ├── README.md                            # Dokumentasi payment module
    └── widgets/
        ├── virtual_account_card.dart       # Widget kartu Virtual Account
        ├── payment_info_card.dart          # Widget informasi pembayaran
        └── payment_instruction_card.dart   # Widget instruksi pembayaran
```

## File Descriptions

### 1. ubah_jadwal_page.dart
Halaman pertama untuk ubah jadwal yang menampilkan:
- Info booking saat ini (kode pemesanan, kendaraan, rute)
- Date picker untuk memilih tanggal baru
- Tombol "Ubah Jadwal" untuk melanjutkan

**Key Features:**
- Validasi tanggal
- Fetch available rides dari API
- Navigasi ke list page

### 2. ubah_jadwal_list_page.dart
Halaman daftar jadwal yang tersedia menampilkan:
- Header dengan rute perjalanan
- Date selector horizontal
- List of available rides

**Key Features:**
- Filter rides berdasarkan tanggal
- Display multiple ride options
- Navigasi ke detail page

### 3. ubah_jadwal_detail_page.dart
Halaman detail konfirmasi pemesanan baru menampilkan:
- Nomor pemesanan
- Detail rute lengkap
- Tanggal dan jam keberangkatan
- Daftar penumpang
- Tombol "Lanjut" untuk konfirmasi

**Key Features:**
- Load passenger data from booking
- Create reschedule request
- Handle payment if price difference exists
- Navigate to payment page

## Widgets

### date_selector.dart
Widget untuk menampilkan date selector horizontal dengan 5 tanggal (2 sebelum, selected, 2 sesudah).

**Props:**
- `selectedDate`: DateTime - Tanggal yang dipilih
- `onDateSelected`: Function(DateTime)? - Callback ketika tanggal dipilih

### ride_card.dart
Widget card untuk menampilkan informasi jadwal perjalanan.

**Props:**
- `ride`: Map<String, dynamic> - Data ride
- `booking`: Map<String, dynamic> - Data booking saat ini
- `selectedDate`: DateTime - Tanggal yang dipilih

**Display:**
- Tanggal dan harga
- Origin dan destination dengan icon
- Waktu keberangkatan
- Jumlah kursi tersedia
- Button "Selengkapnya"

## Usage Example

```dart
import 'ubah_jadwal/ubah_jadwal_page.dart';

// Navigate to ubah jadwal
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => UbahJadwalPage(booking: bookingData),
  ),
);
```

## API Integration

Module ini terintegrasi dengan backend API:
- `GET /api/v1/bookings/{id}/available-rides` - Fetch jadwal tersedia
- `POST /api/v1/bookings/{id}/reschedule` - Create reschedule request
- `POST /api/v1/payments` - Create payment for price difference

## Dependencies

- `shared_preferences` - Store user token
- `api_service.dart` - API calls
- `payment/reschedule_payment_page.dart` - Payment page (dalam folder ini)

## Module Structure

Module ini terdiri dari 3 bagian utama:

1. **Main Pages** - Halaman utama flow ubah jadwal
2. **Widgets** - Reusable components untuk UI
3. **Payment** - Sub-module untuk handle payment (lihat [payment/README.md](payment/README.md))

Setiap bagian diorganisir dalam folder terpisah untuk memudahkan maintenance dan reusability.
