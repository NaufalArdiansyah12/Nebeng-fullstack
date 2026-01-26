## Struktur Folder Booking Detail

```
📦 booking_detail/
│
├── 📂 utils/                           # Helper & Utility Functions
│   ├── 📄 booking_formatters.dart      # Format tanggal, harga, status
│   │   ├── formatDateTime()
│   │   ├── formatDateOnly()
│   │   ├── formatPrice()
│   │   └── getStatusText()
│   │
│   └── 📄 countdown_helper.dart        # Manajemen countdown timer
│       ├── start()
│       ├── cancel()
│       └── dispose()
│
└── 📂 widgets/                         # UI Components
    │
    ├── 📄 booking_header.dart          # Header dengan gradient & status
    │   └── Widget: BookingHeader
    │
    ├── 📄 countdown_section.dart       # Tampilan countdown
    │   └── Widget: CountdownSection
    │
    ├── 📄 driver_info_card.dart        # Info driver + tombol aksi
    │   └── Widget: DriverInfoCard
    │
    ├── 📄 route_card.dart              # Info rute perjalanan
    │   └── Widget: RouteCard
    │
    ├── 📄 passenger_card.dart          # Info penumpang
    │   ├── Widget: PassengerCard       (simple)
    │   └── Widget: DetailedPassengerCard (detailed)
    │
    ├── 📄 price_card.dart              # Detail harga
    │   └── Widget: PriceCard
    │
    ├── 📄 location_card.dart           # Kartu lokasi
    │   └── Widget: LocationCard
    │
    ├── 📄 map_placeholder.dart         # Placeholder peta
    │   ├── CustomPainter: MapPatternPainter
    │   └── Widget: MapPlaceholder
    │
    └── 📄 in_progress_layout.dart      # Layout khusus status in_progress
        └── Widget: InProgressLayout

📄 booking_detail_riwayat_page.dart     # Main page (menggunakan semua components)
📄 booking_detail_riwayat_page_backup.dart  # Backup file asli
📄 README.md                            # Dokumentasi lengkap
```

## Alur Kerja (Flow)

```
┌─────────────────────────────────────────────────────┐
│  booking_detail_riwayat_page.dart (Main)           │
│  • Manage state (status, tracking data)             │
│  • Fetch data dari API                              │
│  • Tentukan layout berdasarkan status               │
└────────────────┬────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼
┌───────────────┐  ┌──────────────────┐
│ in_progress?  │  │   default layout │
└───────┬───────┘  └────────┬─────────┘
        │                   │
        ▼                   ▼
┌──────────────────┐  ┌─────────────────────────┐
│ InProgressLayout │  │ Uses Components:        │
│ (Full screen)    │  │ • BookingHeader         │
│ • MapPlaceholder │  │ • CountdownSection      │
│ • LocationCard   │  │ • DriverInfoCard        │
│ • Driver info    │  │ • RouteCard             │
└──────────────────┘  │ • PassengerCard         │
                      │ • PriceCard             │
                      └─────────────────────────┘
```

## Komponen Reusable

### 1. BookingHeader
```dart
BookingHeader(
  title: 'Nebeng Motor',
  headerIcon: Icons.two_wheeler,
  accentColor: Color(0xFF0F4AA3),
  currentStatus: 'paid',
)
```

### 2. CountdownSection
```dart
CountdownSection(
  rawDate: '2026-01-25',
  rawTime: '14:30:00',
  timeUntilDeparture: Duration(hours: 2),
)
```

### 3. DriverInfoCard
```dart
DriverInfoCard(
  driverName: 'Pak Budi',
  driverPhoto: 'https://...',
  plateNumber: 'AB 1234 CD',
  accentColor: Color(0xFF0F4AA3),
  onCallPressed: () {},
  onChatPressed: () {},
)
```

### 4. RouteCard
```dart
RouteCard(
  origin: 'Yogyakarta',
  destination: 'Purwokerto',
  departureTime: '14:30',
  dateOnly: '25 Januari 2026',
)
```

### 5. PriceCard
```dart
PriceCard(
  pricePerSeat: 'Rp50.000',
  seats: '2',
  totalPrice: 'Rp100.000',
  bookingType: 'motor',
  booking: bookingData,
)
```

## Utilities

### BookingFormatters
```dart
// Format harga
BookingFormatters.formatPrice(50000)
// Output: "Rp50.000"

// Format tanggal
BookingFormatters.formatDateOnly('2026-01-25')
// Output: "25 Januari 2026"

// Get status text
BookingFormatters.getStatusText('in_progress')
// Output: "Sedang Berlangsung"
```

### CountdownHelper
```dart
final helper = CountdownHelper();

helper.start(
  departureDate: '2026-01-25',
  departureTime: '14:30:00',
  onUpdate: (duration) {
    print('Time left: ${duration?.inHours} hours');
  },
);

// Cleanup
helper.dispose();
```

## Keuntungan Refactoring

✅ **Code lebih pendek**: Main file dari 1709 baris → ~450 baris
✅ **Mudah maintain**: Setiap komponen terpisah
✅ **Reusable**: Komponen bisa dipakai di halaman lain
✅ **Team friendly**: Banyak developer bisa kerja parallel
✅ **Easy testing**: Tiap komponen bisa di-test sendiri
✅ **Clear structure**: Folder terorganisir dengan baik

## Tips Penggunaan

1. **Import yang diperlukan**:
   ```dart
   import 'booking_detail/widgets/countdown_section.dart';
   import 'booking_detail/utils/booking_formatters.dart';
   ```

2. **Kustomisasi komponen**:
   Setiap widget memiliki props yang bisa disesuaikan

3. **Extend komponen**:
   Bisa inherit widget dan override sesuai kebutuhan

4. **Tambah komponen baru**:
   Buat file baru di folder `widgets/` dengan pattern yang sama

---
Last updated: January 23, 2026
