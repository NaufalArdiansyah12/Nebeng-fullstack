# Saved Passengers Feature

## Overview
Feature untuk menyimpan data penumpang yang sering digunakan, sehingga user tidak perlu input data berulang kali setiap kali booking.

## Database Schema

### Table: `saved_passengers`
```sql
- id (bigint, primary key)
- user_id (bigint, foreign key -> users.id)
- name (varchar 255)
- phone (varchar 20)
- created_at (timestamp)
- updated_at (timestamp)
```

## API Endpoints

### 1. Get Saved Passengers
**GET** `/api/v1/saved-passengers`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "success": true,
  "message": "Data penumpang berhasil diambil",
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "name": "Ailsa Nasywa",
      "phone": "082992730984",
      "created_at": "2026-02-03T07:12:38.000000Z",
      "updated_at": "2026-02-03T07:12:38.000000Z"
    }
  ]
}
```

### 2. Save New Passenger
**POST** `/api/v1/saved-passengers`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

**Body:**
```json
{
  "name": "Ailsa Nasywa",
  "phone": "082992730984"
}
```

**Validation:**
- name: required, string, max 255 characters
- phone: required, string, max 20 characters
- Duplicate check: tidak boleh simpan penumpang dengan nama dan nomor yang sama

**Response:**
```json
{
  "success": true,
  "message": "Penumpang berhasil disimpan",
  "data": {
    "id": 1,
    "user_id": 1,
    "name": "Ailsa Nasywa",
    "phone": "082992730984",
    "created_at": "2026-02-03T07:12:38.000000Z",
    "updated_at": "2026-02-03T07:12:38.000000Z"
  }
}
```

### 3. Delete Saved Passenger
**DELETE** `/api/v1/saved-passengers/{id}`

**Headers:**
```
Authorization: Bearer {token}
Accept: application/json
```

**Response:**
```json
{
  "success": true,
  "message": "Penumpang berhasil dihapus"
}
```

## Frontend Implementation

### File: `saved_passenger_service.dart`
Service untuk komunikasi dengan API saved passengers.

### File: `booking_detail_page.dart`
Halaman booking yang menggunakan saved passengers:
- Load saved passengers saat init
- Tampilkan list saved passengers dengan search
- Add passenger dengan toggle "Simpan ke daftar"
- Delete passenger dari daftar

### Features:
1. **Auto-load**: Saat buka halaman booking, otomatis load saved passengers dari database
2. **Search**: Fitur search untuk cari penumpang tersimpan
3. **Save Toggle**: Toggle button untuk simpan penumpang baru ke daftar
4. **Delete**: Button delete untuk hapus dari daftar tersimpan
5. **Duplicate Check**: Validasi agar tidak ada duplikat di database
6. **Real-time Sync**: Data langsung ter-update di UI setelah save/delete

## Testing

### Test GET
```bash
curl -X GET "http://127.0.0.1:8000/api/v1/saved-passengers" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json"
```

### Test POST
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/saved-passengers" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"name": "Ailsa Nasywa", "phone": "082992730984"}'
```

### Test DELETE
```bash
curl -X DELETE "http://127.0.0.1:8000/api/v1/saved-passengers/1" \
  -H "Authorization: Bearer {token}" \
  -H "Accept: application/json"
```

## Migration
```bash
php artisan migrate
```

Migration file: `2026_02_03_070313_create_saved_passengers_table.php`
