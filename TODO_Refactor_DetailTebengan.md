# TODO: Refactor DetailTebenganPage

## Task
Memisahkan serviceType gabungan menjadi dua field: ride_type dan service_type

## Progress
- [x] 1. Mengubah getter - hapus serviceType gabungan dan getter terkait
- [x] 2. Menambahkan getter baru untuk rideType dan serviceType terpisah
- [x] 3. Menambahkan getter isTebengan, isBarang, isBoth
- [x] 4. Menambahkan getter isMotor, isMobil, isBarangVehicle
- [x] 5. Memperbarui serviceTypeLabel dan serviceTypeIcon berdasarkan rideType
- [x] 6. Memperbarui logika tampilan card berdasarkan service_type
- [x] 7. Memperbarui _buildVehicleCard dan _buildPackageCard
- [x] 8. Memperbarui aktivitas_page.dart agar sesuai dengan logic baru
- [ ] 9. Testing dan verifikasi

## Logic Baru
1. Jika service_type = tebengan: Vehicle Card + Passengers Card
2. Jika service_type = barang: Package Card + Sender Card
3. Jika service_type = both: Semua Card (Vehicle + Package + Passengers + Sender)
4. ride_type menentukan icon dan label kendaraan (motor, mobil, barang)

## Perubahan yang Dilakukan

### Getter Baru:
- `rideType` - dari activity['rideType']
- `serviceType` - dari activity['serviceTypeRaw']
- `isTebengan` - serviceType == 'tebengan'
- `isBarangService` - serviceType == 'barang'
- `isBoth` - serviceType == 'both'
- `isMotor` - rideType == 'motor'
- `isMobil` - rideType == 'mobil'
- `isBarangVehicle` - rideType == 'barang'

### Getter yang Dihapus:
- `serviceType` (lama: nebeng_motor, nebeng_mobil, dll)
- `isNebengMotor`, `isNebengMobil`, `isNebengBarang`, `isTitipBarang`
- `isVehicleService`, `isBarangService` (lama)

### Label dan Icon:
- `serviceTypeLabel` - berdasarkan rideType + serviceType
- `rideTypeIcon` - berdasarkan rideType saja
- `rideTypeColor` - berdasarkan rideType saja
- `serviceTypeColor` - berdasarkan serviceType

### Logika Tampilan Card:
- `isTebengan` → Vehicle Card + Passengers Card
- `isBarangService` → Package Card + Sender Card
- `isBoth` → Semua Card
