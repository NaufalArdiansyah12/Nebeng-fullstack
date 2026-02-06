# Mitra Tracking Map - Refactored Structure

File `mitra_tracking_map_page.dart` yang awalnya 2500 baris telah dipecah menjadi struktur modular untuk mempermudah maintenance dan development.

## Struktur Folder

```
mitra_tracking_map/
├── models/
│   └── tracking_state.dart          # State management - semua variabel state
├── services/
│   └── tracking_service.dart        # API calls & location tracking logic
├── widgets/
│   ├── tracking_map_widget.dart     # Widget peta dengan markers & routes
│   ├── qr_code_screen.dart          # Layar QR code setelah selesai
│   ├── info_card_widgets.dart       # Bottom info card & pickup waiting card
│   └── overlay_widgets.dart         # Button overlay, countdown timer, dll
└── utils/
    ├── tracking_helpers.dart        # Helper functions untuk parsing & formatting
    └── persistence_helper.dart      # Helper untuk save/load state ke SharedPreferences
```

## File Utama

- **mitra_tracking_map_page.dart** - File export yang mengarah ke versi refactored
- **mitra_tracking_map_page_refactored.dart** - Main page yang mengkoordinasi semua komponen

## Deskripsi Komponen

### 1. Models (`tracking_state.dart`)
Berisi class `TrackingState` yang menyimpan semua state variables:
- Controllers (MapController, ChatService)
- Timers (location, countdown, pickup)
- Location & tracking state
- Route data
- Booking info

### 2. Services (`tracking_service.dart`)
Berisi class `TrackingService` dengan methods untuk:
- Fetch route dari OSRM API
- Get current position
- Check location permissions
- Update booking location & status
- Resolve booking ID
- Get booking data by type (motor/mobil/barang/titip)

### 3. Widgets

#### `tracking_map_widget.dart`
- Widget peta dengan FlutterMap
- Menampilkan markers untuk origin, destination, current position
- Menampilkan polyline untuk route

#### `qr_code_screen.dart`
- Layar QR code yang ditampilkan setelah tebengan selesai
- Menampilkan rating, total pendapatan, dan QR code

#### `info_card_widgets.dart`
- `BottomInfoCard`: Card info di bawah peta dengan booking details
- `PickupWaitingCard`: Card untuk waiting timer 15 menit saat sudah di pickup

#### `overlay_widgets.dart`
- `TopMessageButton`: Tombol pesan di atas peta
- `BackButtonOverlay`: Tombol kembali
- `TollToggleButton`: Toggle untuk hindari/lewat tol (khusus mobil)
- `CountdownTimerOverlay`: Timer countdown sampai departure
- `ActionButton`: Tombol aksi "Mulai Menuju"

### 4. Utils

#### `tracking_helpers.dart`
Helper classes:
- `LocationHelper`: Parse LatLng dari berbagai format
- `BookingTypeHelper`: Detect booking type (motor/mobil/barang/titip)
- `FormatHelper`: Format countdown & timer
- `BookingInfoHelper`: Extract info dari booking data

#### `persistence_helper.dart`
Helper untuk persistence:
- Save/load tracking state ke SharedPreferences
- Save/clear pickup arrival time
- Load persisted state saat app restart

## Manfaat Refactoring

1. **Modular**: Setiap komponen punya tanggung jawab jelas
2. **Reusable**: Widget & helper bisa digunakan ulang
3. **Maintainable**: Mudah cari & edit kode spesifik
4. **Testable**: Lebih mudah untuk unit testing
5. **Scalable**: Mudah menambah fitur baru tanpa mengubah banyak file

## Cara Penggunaan

Import seperti biasa:
```dart
import 'package:..../screens/mitra/mitra_tracking_map_page.dart';

// Gunakan widget seperti sebelumnya
MitraTrackingMapPage(item: bookingData)
```

Tidak ada perubahan pada cara penggunaan, hanya struktur internal yang berubah.

## Catatan

- File `mitra_tracking_map_page.dart` sekarang hanya berisi export statement
- Logic utama ada di `mitra_tracking_map_page_refactored.dart`
- Semua import path sudah disesuaikan
