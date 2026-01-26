# Integration: Customer Trip List dengan Mitra Rides

## Overview
Halaman trip list di customer sekarang mengambil data real dari database yang menyimpan tebengan yang dibuat oleh mitra.

## Perubahan Backend

### RideController.php
```php
public function index(Request $request)
{
    // Support filtering by:
    // - origin_location_id
    // - destination_location_id  
    // - date
    // - ride_type (motor/mobil)
}
```

**Endpoint:** `GET /api/v1/rides`

**Query Parameters:**
- `origin_location_id` (optional) - Filter by lokasi awal
- `destination_location_id` (optional) - Filter by lokasi tujuan
- `date` (optional) - Filter by tanggal (format: YYYY-MM-DD)
- `ride_type` (optional) - Filter by tipe (motor/mobil)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "origin_location_id": 1,
      "destination_location_id": 2,
      "departure_date": "2026-01-08",
      "departure_time": "09:00:00",
      "ride_type": "motor",
      "service_type": "tebengan",
      "price": 50000,
      "vehicle_name": "Gamu Takayama",
      "vehicle_plate": "N535YZ",
      "vehicle_brand": "Honda",
      "vehicle_type": "Beat",
      "vehicle_color": "Hitam",
      "available_seats": 1,
      "status": "active",
      "origin_location": {
        "id": 1,
        "name": "PIK 2",
        "province": "Jakarta"
      },
      "destination_location": {
        "id": 2,
        "name": "Stasiun Bandung",
        "province": "Bandung"
      },
      "user": {
        "id": 2,
        "name": "Kamado Tanjiro",
        "role": "mitra"
      }
    }
  ]
}
```

## Perubahan Frontend

### 1. ApiService (`lib/services/api_service.dart`)

Menambah method baru:

```dart
static Future<List<Map<String, dynamic>>> fetchRides({
  int? originLocationId,
  int? destinationLocationId,
  String? date,
  String? rideType,
})
```

### 2. TripModel (`lib/screens/customer/nebeng_motor/models/trip_model.dart`)

**Ditambahkan:**
- Property `vehicleName`, `vehiclePlate`, `vehicleBrand`, `vehicleType`, `availableSeats`
- Factory constructor `TripModel.fromApi(Map<String, dynamic> json)` untuk convert API response

### 3. TripListPage (`lib/screens/customer/nebeng_motor/pages/trip_list_page.dart`)

**Parameter baru:**
- `originLocationId` (int?)
- `destinationLocationId` (int?)

**State management:**
- `isLoading` - untuk loading indicator
- `errorMessage` - untuk error handling

**Methods:**
- `_loadTrips()` - async, fetch dari API
- `_buildLoadingState()` - tampilan loading
- `_buildErrorState()` - tampilan error dengan retry button

### 4. NebengMotorPage (`lib/screens/customer/nebeng_motor_page.dart`)

**State variables baru:**
- `lokasiAwalId` (int?)
- `lokasiTujuanId` (int?)

**Perubahan:**
- `_showLocationPicker()` - sekarang menyimpan ID lokasi juga
- `_handleNextButton()` - pass location IDs ke TripListPage

### 5. LocationPickerPage (`lib/screens/customer/nebeng_motor/pages/location_picker_page.dart`)

**Type changes:**
- `List<Map<String, String>>` → `List<Map<String, dynamic>>`
- Sekarang support ID field dari API

## Flow Data

```
1. Customer memilih lokasi di NebengMotorPage
   └─> Fetch dari ApiService.fetchLocations()
   └─> Simpan ID, name, address

2. Customer klik "Selanjutnya"
   └─> Navigate ke TripListPage dengan originLocationId & destinationLocationId

3. TripListPage.initState()
   └─> Call _loadTrips()
   └─> ApiService.fetchRides() dengan filter
   └─> Convert response ke List<TripModel>
   └─> Display dengan TripCard

4. Customer pilih trip
   └─> Navigate ke BookingDetailPage
```

## Testing

### Test Data
Pastikan sudah ada rides di database (dibuat oleh mitra):

```bash
# Login sebagai mitra
POST /api/v1/auth/login
{
  "email": "mitra@example.com",
  "password": "password"
}

# Buat tebengan
POST /api/v1/rides
Authorization: Bearer {token}
{
  "origin_location_id": 1,
  "destination_location_id": 2,
  "departure_date": "2026-01-08",
  "departure_time": "09:00:00",
  "ride_type": "motor",
  "service_type": "tebengan",
  "price": 50000,
  ...
}
```

### Verify
1. Login sebagai customer
2. Pilih "Nebeng Motor"
3. Pilih lokasi awal dan tujuan (sesuai dengan rides yang ada)
4. Pilih tanggal
5. Klik "Selanjutnya"
6. Halaman trip list seharusnya menampilkan rides yang dibuat mitra

## Error Handling

1. **No internet connection** - Tampilkan error state dengan retry button
2. **API error** - Tampilkan error message dengan retry button
3. **Empty results** - Tampilkan empty state dengan tukar arah button
4. **Loading** - Tampilkan circular progress indicator

## Next Steps

- [ ] Implementasi untuk Nebeng Mobil
- [ ] Cache rides data untuk offline mode
- [ ] Refresh on pull down
- [ ] Filter tambahan (harga, rating, dll)
- [ ] Real-time updates dengan WebSocket
