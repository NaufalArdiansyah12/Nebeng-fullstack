# Detail Tebengan Module

Modul ini berisi halaman detail tebengan untuk mitra yang sudah direfactor menjadi struktur yang lebih modular.

## Struktur Folder

```
detail_tebengan/
├── services/
│   └── booking_data_service.dart      # Service untuk fetch data booking
├── widgets/
│   ├── info_row.dart                  # Widget untuk menampilkan row informasi
│   ├── passenger_tile.dart            # Widget tile untuk penumpang
│   ├── receiver_info_card.dart        # Card untuk informasi penerima barang
│   ├── penumpang_motor_section.dart   # Section penumpang motor
│   └── penumpang_mobil_section.dart   # Section penumpang mobil
└── README.md                          # Dokumentasi ini
```

## File Utama

File utama masih berada di:
`lib/screens/mitra/detail_tebengan_page.dart`

## Cara Penggunaan

### 1. BookingDataService

Service untuk mengambil data booking dari API:

```dart
// Get motor booking
final motorBooking = await BookingDataService.getMotorBooking(rideId);

// Get mobil bookings
final mobilBookings = await BookingDataService.getMobilBookingWithPassengers(rideId);

// Get barang booking
final barangBooking = await BookingDataService.getBarangBooking(rideId);

// Get titip barang booking
final titipBooking = await BookingDataService.getTitipBarangBooking(rideId);

// Get label untuk jumlah penumpang/barang
final label = BookingDataService.getBookingCountLabel(serviceType, passengerCount, hasBarangData);
```

### 2. Widget Components

#### PassengerTile
Widget untuk menampilkan tile penumpang dengan avatar dan info:

```dart
PassengerTile(
  name: 'John Doe',
  subtitle: 'Chat customer',
  isLast: false,
  onTap: () {
    // Handle tap
  },
)
```

#### ReceiverInfoCard
Widget untuk menampilkan informasi penerima barang:

```dart
ReceiverInfoCard(
  title: 'Informasi Penerima Barang',
  name: receiverName,
  phone: receiverPhone,
  address: receiverAddress,
)
```

#### InfoRow
Widget untuk menampilkan row informasi label-value:

```dart
InfoRow(
  label: 'Jenis Kendaraan',
  value: 'Motor',
  isLast: false,
)
```

#### PenumpangMotorSection
Section lengkap untuk menampilkan informasi penumpang motor:

```dart
PenumpangMotorSection(
  ride: rideData,
  onChatPressed: (booking) {
    // Handle chat
  },
)
```

#### PenumpangMobilSection
Section lengkap untuk menampilkan informasi penumpang mobil:

```dart
PenumpangMobilSection(
  ride: rideData,
)
```

## Benefit Refactoring

1. **Lebih Mudah Maintenance**: Setiap widget/service memiliki tanggung jawab yang jelas
2. **Reusable**: Widget dapat digunakan kembali di halaman lain
3. **Testable**: Lebih mudah untuk menulis unit test
4. **Readable**: Code lebih mudah dibaca dan dipahami
5. **Scalable**: Mudah untuk menambahkan fitur baru

## TODO (Next Steps)

Untuk menyelesaikan refactoring:

1. Buat widget untuk `PenumpangBarangSection`
2. Buat widget untuk `PenumpangTitipBarangSection`  
3. Update file `detail_tebengan_page.dart` untuk menggunakan widget-widget baru
4. Hapus method-method lama yang sudah dipindahkan ke widget terpisah
5. Tambahkan unit tests untuk service dan widget

## Notes

- File asli masih ada di `detail_tebengan_page.dart` dan masih berfungsi normal
- Refactoring dilakukan secara bertahap untuk menghindari breaking changes
- Widget-widget baru sudah siap digunakan dan diimpor di file utama
