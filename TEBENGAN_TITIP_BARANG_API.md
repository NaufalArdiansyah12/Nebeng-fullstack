# Tebengan Titip Barang API Documentation

## Endpoint Base URL
```
/api/v1/tebengan-titip-barang
```

## Database Structure

**Table Name:** `tebengan_titip_barang`

| Column | Type | Description |
|--------|------|-------------|
| id | bigint | Primary key |
| mitra_id | bigint | Foreign key to users table (mitra who creates the service) |
| origin_location_id | bigint | Foreign key to locations table |
| destination_location_id | bigint | Foreign key to locations table |
| departure_date | date | Date of departure |
| departure_time | time | Time of departure |
| transportation_type | string | Type: 'kereta', 'pesawat', or 'bus' |
| bagasi_capacity | integer | Capacity in kg: 5, 10, or 20 |
| price | decimal(12,2) | Price in Rupiah |
| status | string | Status: 'active', 'inactive', or 'completed' |
| created_at | timestamp | Created timestamp |
| updated_at | timestamp | Updated timestamp |

## API Endpoints

### 1. Get All Tebengan Titip Barang
**GET** `/api/v1/tebengan-titip-barang`

**Query Parameters:**
- `status` (optional) - Filter by status: active, inactive, completed
- `mitra_id` (optional) - Filter by mitra ID
- `origin_location_id` (optional) - Filter by origin location
- `destination_location_id` (optional) - Filter by destination location
- `departure_date` (optional) - Filter by departure date (YYYY-MM-DD)
- `transportation_type` (optional) - Filter by transportation type: kereta, pesawat, bus

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "mitra_id": 1,
        "origin_location_id": 1,
        "destination_location_id": 2,
        "departure_date": "2026-01-20",
        "departure_time": "08:00:00",
        "transportation_type": "kereta",
        "bagasi_capacity": 10,
        "price": "50000.00",
        "status": "active",
        "created_at": "2026-01-13T12:00:00.000000Z",
        "updated_at": "2026-01-13T12:00:00.000000Z",
        "mitra": {
          "id": 1,
          "name": "Mitra Name",
          "email": "mitra@example.com"
        },
        "origin_location": {
          "id": 1,
          "name": "Jakarta"
        },
        "destination_location": {
          "id": 2,
          "name": "Bandung"
        }
      }
    ],
    "per_page": 20,
    "total": 1
  }
}
```

### 2. Get Single Tebengan Titip Barang
**GET** `/api/v1/tebengan-titip-barang/{id}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "mitra_id": 1,
    "origin_location_id": 1,
    "destination_location_id": 2,
    "departure_date": "2026-01-20",
    "departure_time": "08:00:00",
    "transportation_type": "kereta",
    "bagasi_capacity": 10,
    "price": "50000.00",
    "status": "active",
    "mitra": { ... },
    "origin_location": { ... },
    "destination_location": { ... }
  }
}
```

### 3. Create Tebengan Titip Barang
**POST** `/api/v1/tebengan-titip-barang`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "origin_location_id": 1,
  "destination_location_id": 2,
  "departure_date": "2026-01-20",
  "departure_time": "08:00",
  "transportation_type": "kereta",
  "bagasi_capacity": 10,
  "price": 50000
}
```

**Validation Rules:**
- `origin_location_id`: required, must exist in locations table
- `destination_location_id`: required, must exist in locations table
- `departure_date`: required, must be a valid date
- `departure_time`: required
- `transportation_type`: required, must be 'kereta', 'pesawat', or 'bus'
- `bagasi_capacity`: required, must be 5, 10, or 20
- `price`: required, must be numeric and >= 0

**Response:**
```json
{
  "success": true,
  "message": "Tebengan titip barang created successfully",
  "data": { ... }
}
```

### 4. Update Tebengan Titip Barang
**PUT** `/api/v1/tebengan-titip-barang/{id}`

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:** (all fields optional)
```json
{
  "origin_location_id": 1,
  "destination_location_id": 2,
  "departure_date": "2026-01-20",
  "departure_time": "08:00",
  "transportation_type": "pesawat",
  "bagasi_capacity": 20,
  "price": 75000,
  "status": "inactive"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Tebengan titip barang updated successfully",
  "data": { ... }
}
```

### 5. Delete Tebengan Titip Barang
**DELETE** `/api/v1/tebengan-titip-barang/{id}`

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "message": "Tebengan titip barang deleted successfully"
}
```

### 6. Get My Tebengan (Mitra's own listings)
**GET** `/api/v1/tebengan-titip-barang/my/list`

**Headers:**
```
Authorization: Bearer {token}
```

**Query Parameters:**
- `status` (optional) - Filter by status

**Response:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [ ... ],
    "per_page": 20,
    "total": 5
  }
}
```

## Error Responses

### 422 Validation Error
```json
{
  "success": false,
  "message": "Validation error",
  "errors": {
    "transportation_type": ["The transportation type field must be kereta, pesawat, or bus."]
  }
}
```

### 403 Unauthorized
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Tebengan titip barang not found"
}
```

### 500 Server Error
```json
{
  "success": false,
  "message": "Failed to create tebengan titip barang",
  "error": "Error details..."
}
```

## Testing with cURL

### Create Tebengan
```bash
curl -X POST http://localhost:8000/api/v1/tebengan-titip-barang \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "origin_location_id": 1,
    "destination_location_id": 2,
    "departure_date": "2026-01-20",
    "departure_time": "08:00",
    "transportation_type": "kereta",
    "bagasi_capacity": 10,
    "price": 50000
  }'
```

### Get All Tebengan
```bash
curl http://localhost:8000/api/v1/tebengan-titip-barang
```

### Get Filtered Tebengan
```bash
curl "http://localhost:8000/api/v1/tebengan-titip-barang?transportation_type=kereta&status=active"
```

## Notes
- All timestamps are in UTC
- Authentication uses Bearer token from login endpoint
- Only the mitra who created a tebengan can update or delete it
- Status defaults to 'active' when creating new tebengan
- Pagination returns 20 items per page by default
