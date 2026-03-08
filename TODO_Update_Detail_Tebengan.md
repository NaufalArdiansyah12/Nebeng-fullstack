# TODO: Update Detail Tebengan Page

## Task: Tampilkan data sesuai type layanan (nebeng_motor, nebeng_mobil, nebeng_barang, titip_barang)

## Files to modify:
1. customer-mitra/frontend/lib/screens/posmitra/aktivitas_page.dart
2. customer-mitra/frontend/lib/screens/posmitra/aktivitas/detail_tebengan_page.dart

## Implementation Steps:

### Phase 1: Update aktivitas_page.dart
- [ ] Update `_rideToActivity()` function to include serviceType
- [ ] Add different icons for each service type
- [ ] Show different labels: "Nabung Motor", "Nabung Mobil", "Nebeng Barang", "Titip Barang"

### Phase 2: Update detail_tebengan_page.dart
- [ ] Make page StatefulWidget to handle dynamic content
- [ ] Add serviceType parameter to activity
- [ ] If nebeng_motor/mobil: Show "Informasi Kendaraan" + "Informasi Penebeng"
- [ ] If titip_barang: Show "Informasi Pengirim" + "Informasi Paket"
- [ ] If nebeng_barang: Show "Informasi Barang"
- [ ] Update card styling based on service type

## Status: IN PROGRESS
