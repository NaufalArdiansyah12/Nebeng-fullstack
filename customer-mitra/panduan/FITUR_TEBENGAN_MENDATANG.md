# Fitur Tebengan Mendatang di Beranda Customer

## Deskripsi
Fitur ini menampilkan card untuk tebengan yang akan datang, sedang diproses, atau menunggu konfirmasi di halaman beranda customer. Maksimal 3 card akan ditampilkan untuk menjaga halaman beranda tetap clean dan tidak terlalu panjang.

## Lokasi
File: `/frontend/lib/screens/customer/beranda_page.dart`

## Fitur yang Ditambahkan

### 1. Section "Tebengan Mendatang"
- Ditampilkan di bawah section banner/promo
- Menampilkan maksimal 3 tebengan upcoming
- Memiliki tombol "Lihat Semua" yang mengarah ke halaman riwayat

### 2. Card Tebengan
Setiap card menampilkan:
- **Icon & Jenis Layanan**: Motor atau Mobil
- **Tanggal Keberangkatan**: Format yang mudah dibaca (contoh: 24 Jan 2026)
- **Status Badge**: 
  - 🟠 Menunggu (pending)
  - 🔵 Dikonfirmasi (confirmed)
  - 🟢 Dalam Perjalanan (in_progress)
- **Rute**: Lokasi pickup dan tujuan dengan visual yang jelas
- **Waktu Keberangkatan**: Jika tersedia

### 3. State Management
- **Loading State**: Menampilkan circular progress indicator saat memuat data
- **Empty State**: Menampilkan pesan "Belum ada tebengan mendatang" dengan icon
- **Data State**: Menampilkan list card tebengan

### 4. Interaksi
- **Tap Card**: Navigasi ke halaman detail booking (`BookingDetailRiwayatPage`)
- **Tombol "Lihat Semua"**: Navigasi ke halaman riwayat (`RiwayatPage`)
- **Pull to Refresh**: User bisa refresh untuk memperbarui data

## Logika Filter
Tebengan yang ditampilkan harus memenuhi kriteria:
1. Service type: `tebengan`, `both`, `motor`, atau `mobil`
2. Tanggal keberangkatan >= hari ini
3. Diurutkan berdasarkan tanggal (paling dekat ditampilkan duluan)
4. Maksimal 3 item

## Implementasi Teknis

### Method yang Ditambahkan
1. `_buildUpcomingTebenganSection()` - Section utama
2. `_buildEmptyUpcomingCard()` - Card untuk state kosong
3. `_buildUpcomingCard(Map<String, dynamic> booking)` - Card individual tebengan

### Method yang Sudah Ada (Digunakan)
- `_loadUpcomingTebengan()` - Memuat data dari API (sudah ada sebelumnya)

### State Variables (Sudah Ada)
- `_upcomingTebengan` - List data tebengan
- `_loadingUpcoming` - Status loading

### Dependencies
- `font_awesome_flutter` - Untuk icon motor dan mobil
- `shared_preferences` - Untuk token autentikasi
- API Service - Untuk fetch data booking

## Navigasi
```dart
// Import yang ditambahkan:
import '../../panduan/riwayat/riwayat_page.dart';
import '../../panduan/riwayat/booking_detail_riwayat_page.dart';

// Navigasi ke detail:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BookingDetailRiwayatPage(booking: booking),
  ),
);

// Navigasi ke riwayat:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const RiwayatPage(),
  ),
);
```

## UI/UX Design

### Card Design
- Border radius: 12px
- Shadow: Soft shadow dengan opacity 0.08
- Padding: 16px
- Margin bottom: 12px antar card
- Interactive: Ripple effect saat di-tap

### Colors
- Primary: `#1E40AF` (Blue 800)
- Status Colors:
  - Pending: Orange
  - Confirmed: Blue
  - In Progress: Green
- Background: White
- Border: Grey 200

### Typography
- Title: Bold, 14pt
- Date: Regular, 12pt, Grey 600
- Location: Medium, 13pt, Black 87
- Status: Semi-bold, 11pt

## Screenshot Layout
```
┌─────────────────────────────────┐
│ Header (Blue Background)        │
│ • Hello Ailsa                   │
│ • Search Bar                    │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ Reward Points Section           │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ Layanan (Services)              │
│ [Motor] [Mobil] [Barang] [...]  │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ Nebeng Disini (Banner/Promo)    │
│ • Carousel Banner               │
│ • Indicators                    │
└─────────────────────────────────┘
┌─────────────────────────────────┐
│ Tebengan Mendatang ───── Lihat │ <- NEW!
│                           Semua │
│ ┌─────────────────────────────┐ │
│ │ [🏍️] Nebeng Motor  [Status] │ │
│ │ 24 Jan 2026                  │ │
│ │ ○ Lokasi Pickup              │ │
│ │ ┊                            │ │
│ │ 📍 Tujuan                    │ │
│ │ ⏰ 08:00 WIB                 │ │
│ └─────────────────────────────┘ │
│ (Maksimal 3 cards)              │
└─────────────────────────────────┘
```

## Testing
Untuk menguji fitur ini:
1. Login sebagai customer
2. Buka halaman beranda
3. Periksa apakah section "Tebengan Mendatang" muncul
4. Jika ada booking upcoming, akan tampil card-nya
5. Jika tidak ada, akan tampil empty state
6. Tap card untuk ke detail
7. Tap "Lihat Semua" untuk ke halaman riwayat
8. Pull down untuk refresh

## Notes
- Fitur ini bergantung pada API endpoint `/api/v1/customer/bookings` yang sudah ada
- Filter dilakukan di client-side untuk performa yang lebih baik
- Data di-refresh otomatis saat halaman di-resume (kembali dari halaman lain)
- Compatible dengan feature refresh indicator yang sudah ada
