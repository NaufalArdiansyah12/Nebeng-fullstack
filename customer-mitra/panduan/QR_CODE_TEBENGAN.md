# QR Code untuk Tebangan Mitra

## Overview
Setiap kali mitra membuat tebangan (motor, mobil, barang, atau titip barang), sistem akan otomatis generate QR code unik yang dapat di-scan oleh pos mitra untuk menandai tebangan telah selesai.

## Backend Implementation

### 1. Database Schema
Menambahkan kolom `qr_code_data` di semua tabel tebangan:
- `tebengan_motor`
- `tebengan_mobil`
- `tebengan_barang`
- `tebengan_titip_barang`

**Migration:**
```php
$table->string('qr_code_data', 500)->nullable()->after('status');
$table->index('qr_code_data');
```

### 2. QR Code Generation

**Format QR Code:**
```
RIDE-{TYPE}-{ID}-{RANDOM}
```

**Contoh:**
- Motor: `RIDE-MOTOR-123-ABC12XYZ`
- Mobil: `RIDE-MOBIL-456-DEF34UVW`
- Barang: `RIDE-BARANG-789-GHI56RST`
- Titip Barang: `RIDE-TITIP-321-JKL78MNO`

**Implementation:**
```php
private function generateQrCode($rideType, $rideId)
{
    $type = strtoupper($rideType);
    $random = Str::upper(Str::random(8));
    return "RIDE-{$type}-{$rideId}-{$random}";
}
```

### 3. Controller Updates

#### RideController (Motor, Mobil, Barang)
```php
$ride = Ride::create($data);

// Generate and save QR code
$qrCode = $this->generateQrCode('motor', $ride->id);
$ride->qr_code_data = $qrCode;
$ride->save();
```

#### TebenganTitipBarangController
```php
$tebengan = TebenganTitipBarang::create($data);

// Generate and save QR code
$qrCode = $this->generateQrCode($tebengan->id);
$tebengan->qr_code_data = $qrCode;
$tebengan->save();
```

### 4. API Response
QR code data akan di-return dalam response create ride:

```json
{
  "success": true,
  "message": "Ride created successfully",
  "data": {
    "id": 123,
    "qr_code_data": "RIDE-MOTOR-123-ABC12XYZ",
    // ... other fields
  }
}
```

## Frontend Implementation

### 1. Dependencies
**pubspec.yaml:**
```yaml
dependencies:
  qr_flutter: ^4.1.0
```

### 2. Success Page Updates

#### Motor/Mobil/Barang - RideSuccessPage
```dart
class RideSuccessPage extends StatelessWidget {
  final String? qrCodeData;
  
  const RideSuccessPage({Key? key, this.qrCodeData}) : super(key: key);
  
  // QR Code display widget
  if (qrCodeData != null && qrCodeData!.isNotEmpty) ...[
    QrImageView(
      data: qrCodeData!,
      version: QrVersions.auto,
      size: 200.0,
      backgroundColor: Colors.white,
    ),
  ]
}
```

#### Titip Barang - TitipBarangSuccessPage
```dart
class TitipBarangSuccessPage extends StatelessWidget {
  final String? qrCodeData;
  
  const TitipBarangSuccessPage({Key? key, this.qrCodeData}) : super(key: key);
  
  // QR Code display widget (same as above)
}
```

### 3. Passing QR Code Data

**DetailRidePage (Motor/Mobil/Barang):**
```dart
final response = await ApiService.createRide(...);
final qrCodeData = response['data']?['qr_code_data'] as String?;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => RideSuccessPage(qrCodeData: qrCodeData),
  ),
);
```

**DetailTitipBarangPage:**
```dart
final responseData = jsonDecode(response.body);
final qrCodeData = responseData['data']?['qr_code_data'] as String?;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => TitipBarangSuccessPage(qrCodeData: qrCodeData),
  ),
);
```

## Usage Flow

1. **Mitra membuat tebangan** → Fill form (motor/mobil/barang/titip barang)
2. **Submit data** → Backend generate QR code otomatis
3. **Success page** → QR code ditampilkan
4. **Pos mitra scan QR** → (Next implementation: Scan & verify di pos mitra)
5. **Update status** → Tebangan ditandai selesai

## Next Steps (Untuk Pos Mitra)

### Scanner Implementation
- Buat halaman scanner QR code di pos mitra
- Validasi QR code format
- Fetch detail tebangan berdasarkan QR code
- Update status tebangan ke "completed"
- Show tebangan details setelah scan

### API Endpoint untuk Scan
```php
// GET /api/v1/rides/scan/{qr_code_data}
// Verify QR code dan return ride details

// PUT /api/v1/rides/{id}/complete
// Update status tebangan ke completed
```

## Security Considerations

1. **Unique QR Codes:** Setiap QR code bersifat unik dengan random string 8 karakter
2. **Indexed:** Kolom `qr_code_data` di-index untuk fast lookup
3. **One-time Use:** QR code hanya valid untuk 1x scan (status check)
4. **Validation:** Perlu validasi bahwa tebangan belum completed sebelum update status

## Testing

### Test Create Ride dengan QR Code

**Request:**
```bash
curl -X POST http://localhost:8000/api/v1/rides \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "origin_location_id": 1,
    "destination_location_id": 2,
    "departure_date": "2026-02-01",
    "departure_time": "08:00:00",
    "ride_type": "motor",
    "service_type": "tebengan",
    "price": 50000,
    "available_seats": 1
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "qr_code_data": "RIDE-MOTOR-123-ABC12XYZ",
    // ... other fields
  }
}
```

### Verify QR Code in Database
```sql
SELECT id, qr_code_data, status FROM tebengan_motor WHERE id = 123;
```

## Files Modified

### Backend
- `database/migrations/2026_01_30_000001_add_qr_code_to_tebengan_tables.php`
- `app/Models/Ride.php`
- `app/Models/CarRide.php`
- `app/Models/BarangRide.php`
- `app/Models/TebenganTitipBarang.php`
- `app/Http/Controllers/Api/RideController.php`
- `app/Http/Controllers/TebenganTitipBarangController.php`

### Frontend
- `pubspec.yaml`
- `lib/screens/mitra/create_tebengan_motor/pages/ride_success_page.dart`
- `lib/screens/mitra/create_tebengan_motor/pages/detail_ride_page.dart`
- `lib/screens/mitra/titip_barang/pages/titip_barang_success_page.dart`
- `lib/screens/mitra/titip_barang/pages/detail_titip_barang_page.dart`

## Troubleshooting

### QR Code tidak muncul
- Pastikan response dari API mengandung `qr_code_data`
- Check console log untuk error
- Verify qr_flutter package sudah ter-install

### QR Code tidak ter-generate
- Check migration sudah running
- Verify model fillable includes `qr_code_data`
- Check controller logic untuk generate QR

### Database Error
```bash
php artisan migrate:rollback --step=1
php artisan migrate
```
