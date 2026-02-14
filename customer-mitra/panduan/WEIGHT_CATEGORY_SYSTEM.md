# Weight Category System - Documentation

## Overview
Sistem berat barang telah diperbarui untuk menggunakan pilihan terstandarisasi daripada input bebas. Ini memastikan konsistensi data dan kemudahan pemrosesan.

## Pilihan Berat Barang

| Kategori | Label | Berat Maksimal |
|----------|-------|----------------|
| Kecil    | Kecil - Maksimal 5 Kg | 5 kg |
| Sedang   | Sedang - Maksimal 10 Kg | 10 kg |
| Besar    | Besar - Maksimal 20 Kg | 20 kg |

## Database

### Tabel yang Terpengaruh
- `booking_motor`
- `booking_mobil`
- `booking_barang`
- `booking_titip_barang`

### Kolom Weight
```sql
weight VARCHAR(255) NULL COMMENT 'Pilihan: Kecil (Maks. 5kg), Sedang (Maks. 10kg), Besar (Maks. 20kg)'
```

### Migration
File: `2026_02_09_000000_add_weight_options_comment.php`

Menambahkan komentar pada kolom weight untuk dokumentasi pilihan yang tersedia.

## Backend API

### Validasi
Semua endpoint booking sekarang memvalidasi field `weight` dengan rule:

```php
'weight' => 'nullable|string|in:Kecil,Sedang,Besar'
```

### Controllers yang Diupdate
1. `BookingController.php` - Endpoint umum untuk booking
2. `BookingTitipBarangController.php` - Endpoint titip barang

### Enum Helper
File: `app/Enums/WeightCategory.php`

Menyediakan helper untuk:
- Mendapatkan batas berat maksimal
- Mendapatkan label display
- Validasi nilai weight
- Mengambil semua opsi sebagai array

#### Penggunaan Enum

```php
use App\Enums\WeightCategory;

// Get max weight
$maxWeight = WeightCategory::KECIL->getMaxWeight(); // 5

// Get label
$label = WeightCategory::SEDANG->getLabel(); // "Sedang - Maksimal 10 Kg"

// Get all options
$options = WeightCategory::options();
/* Returns:
[
    ['value' => 'Kecil', 'label' => 'Kecil - Maksimal 5 Kg', 'max_weight' => 5],
    ['value' => 'Sedang', 'label' => 'Sedang - Maksimal 10 Kg', 'max_weight' => 10],
    ['value' => 'Besar', 'label' => 'Besar - Maksimal 20 Kg', 'max_weight' => 20],
]
*/

// Validate weight
WeightCategory::isValid('Kecil'); // true
WeightCategory::isValid('Invalid'); // false
```

## Frontend (Flutter)

### Widget Picker
File: `lib/screens/customer/nebeng_barang/widgets/ukuran_picker.dart`

Modal bottom sheet yang menampilkan 3 pilihan berat dengan icon dan deskripsi.

### Halaman yang Diupdate
1. `nebeng_motor/pages/booking_detail_page.dart`
2. `nebeng_mobil/pages/booking_detail_page.dart`
3. `nebeng_barang/pages/booking_detail_page.dart`

Semua halaman sekarang menggunakan `UkuranPicker` daripada TextField untuk input berat.

### Implementation
```dart
import '../../nebeng_barang/widgets/ukuran_picker.dart';

String? _selectedWeight;

// Show picker
UkuranPicker.show(context, (selected) {
  setState(() {
    _selectedWeight = selected; // 'Kecil', 'Sedang', or 'Besar'
  });
});
```

## API Request/Response

### Request Body
```json
{
  "ride_id": 1,
  "user_id": 2,
  "weight": "Sedang",
  "description": "Dokumen penting"
}
```

### Validation Error Response
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "weight": [
      "The selected weight is invalid."
    ]
  }
}
```

### Valid Values
- `"Kecil"`
- `"Sedang"`
- `"Besar"`
- `null` (optional field)

## Testing

### cURL Examples

**Valid Request:**
```bash
curl -X POST http://localhost:8000/api/v1/booking \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": 1,
    "user_id": 2,
    "ride_type": "motor",
    "weight": "Kecil",
    "description": "Paket kecil"
  }'
```

**Invalid Weight:**
```bash
curl -X POST http://localhost:8000/api/v1/booking \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "ride_id": 1,
    "user_id": 2,
    "ride_type": "motor",
    "weight": "XL",
    "description": "Paket besar"
  }'
# Returns validation error
```

## Migration History

1. **Initial weight field** - String field max 50 characters (free text)
2. **2026_02_09** - Added validation rules and documentation, restricted to 3 standard options

## Breaking Changes

⚠️ **Perubahan yang Mempengaruhi Existing Data:**

Jika ada booking lama dengan nilai weight yang tidak sesuai ('2KG', '5kg', dll), mungkin perlu migration data:

```php
// Optional data migration script
DB::table('booking_motor')->whereNotNull('weight')->update(['weight' => null]);
DB::table('booking_mobil')->whereNotNull('weight')->update(['weight' => null]);
DB::table('booking_barang')->whereNotNull('weight')->update(['weight' => null]);
DB::table('booking_titip_barang')->whereNotNull('weight')->update(['weight' => null]);
```

Atau mapping otomatis:
```php
// Map old values to new categories
$weightMap = [
    '2KG' => 'Kecil',
    '5KG' => 'Kecil',
    '10KG' => 'Sedang',
    '15KG' => 'Sedang',
    '20KG' => 'Besar',
];

foreach ($weightMap as $old => $new) {
    DB::table('booking_motor')->where('weight', 'LIKE', "%{$old}%")->update(['weight' => $new]);
    DB::table('booking_mobil')->where('weight', 'LIKE', "%{$old}%")->update(['weight' => $new]);
    DB::table('booking_barang')->where('weight', 'LIKE', "%{$old}%")->update(['weight' => $new]);
    DB::table('booking_titip_barang')->where('weight', 'LIKE', "%{$old}%")->update(['weight' => $new]);
}
```

## Future Improvements

1. **Custom Weight Categories** - Allow mitra to define custom weight categories
2. **Price Calculation** - Automatic price adjustment based on weight category
3. **Weight Validation** - Check if selected weight fits within vehicle capacity
4. **Analytics** - Track popular weight categories for better inventory planning
