# 📖 Admin Panel API Documentation

Base URL: `http://localhost:8000/api/admin`

---

## 🔐 Authentication

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "admin@nebeng.com",
  "password": "admin123"
}

Response 200:
{
  "success": true,
  "message": "Login berhasil",
  "token": "abc123xyz...",
  "user": {
    "id": 1,
    "name": "Admin Nebeng",
    "email": "admin@nebeng.com",
    "role": "admin"
  }
}
```

### Logout
```http
POST /auth/logout
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "message": "Logout berhasil"
}
```

### Verify Token
```http
GET /auth/verify
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "user": {
    "id": 1,
    "name": "Admin Nebeng",
    "email": "admin@nebeng.com",
    "role": "admin"
  }
}
```

### Get Profile
```http
GET /auth/profile
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": 1,
    "namaLengkap": "Admin Nebeng",
    "email": "admin@nebeng.com",
    "role": "admin",
    "foto": "http://localhost:8000/storage/profiles/admin.png",
    "noTlp": "081234567890",
    ...
  }
}
```

### Update Profile
```http
PUT /auth/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Admin Baru",
  "email": "admin@example.com",
  "phone": "081234567890",
  "foto": "data:image/png;base64,...",
  "password": "newpassword123"  // optional
}

Response 200:
{
  "success": true,
  "message": "Profile berhasil diupdate",
  "data": {...}
}
```

---

## 📊 Dashboard

### Get Statistics
```http
GET /dashboard
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "statistics": {
      "totalCustomer": 150,
      "totalMitra": 75,
      "totalPesanan": 500,
      "pesananSelesai": 450,
      "pesananDibatalkan": 20,
      "pesananHariIni": 15,
      "totalPendapatan": 5000000,
      "pendapatanHariIni": 250000,
      "customerBaruBulanIni": 20,
      "mitraBaruBulanIni": 10,
      "pendingVerifikasiMitra": 5,
      "pendingVerifikasiCustomer": 8
    },
    "grafik": [
      {"date": "07 Feb", "count": 45},
      {"date": "08 Feb", "count": 52},
      ...
    ],
    "pesananTerbaru": [
      {
        "id": 123,
        "customer_name": "John Doe",
        "mitra_name": "Jane Smith",
        "total_price": 50000,
        "status": "completed",
        "created_at": "13 Feb 2026 10:30"
      },
      ...
    ]
  }
}
```

---

## 👥 Mitra Management

### Get All Mitra
```http
GET /mitra?per_page=10&status=active&search=john
Authorization: Bearer {token}

Query Parameters:
- per_page (int): Items per page (default: 10)
- status (string): Filter by status (pending, active, blocked)
- search (string): Search by name, email, phone

Response 200:
{
  "success": true,
  "data": [...],
  "pagination": {
    "current_page": 1,
    "per_page": 10,
    "total": 75,
    "last_page": 8
  }
}
```

### Get Mitra Detail
```http
GET /mitra/{id}
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "081234567890",
    "address": "Jakarta",
    "status": "active",
    "blocked_reason": null,
    "profile_photo": "http://...",
    "balance": 500000,
    "reward_points": 100,
    "created_at": "13 Feb 2026 10:30",
    "vehicles": [...]
  }
}
```

### Verify Mitra
```http
POST /mitra/{id}/verify
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "message": "Mitra berhasil diverifikasi",
  "data": {...}
}
```

### Reject Mitra
```http
POST /mitra/{id}/reject
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Dokumen tidak lengkap"
}

Response 200:
{
  "success": true,
  "message": "Mitra berhasil ditolak",
  "data": {...}
}
```

### Block Mitra
```http
POST /mitra/{id}/block
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Melanggar aturan platform"
}

Response 200:
{
  "success": true,
  "message": "Mitra berhasil diblokir",
  "data": {...}
}
```

### Unblock Mitra
```http
POST /mitra/{id}/unblock
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "message": "Mitra berhasil diunblock",
  "data": {...}
}
```

### Get Mitra Vehicles
```http
GET /mitra/{id}/vehicles
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "vehicle_type": "motor",
      "brand": "Honda",
      "model": "Beat",
      "license_plate": "B 1234 XYZ",
      ...
    }
  ]
}
```

---

## 🚗 Vehicles Management

### Get All Vehicles
```http
GET /vehicles?per_page=10&search=honda
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [...],
  "pagination": {...}
}
```

### Get Vehicle Detail
```http
GET /vehicles/{id}
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 5,
    "vehicle_type": "motor",
    "brand": "Honda",
    "model": "Beat",
    "license_plate": "B 1234 XYZ",
    "user": {
      "id": 5,
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "081234567890"
    }
  }
}
```

---

## 👤 Customer Management

### Get All Customers
```http
GET /customers?per_page=10&status=active&search=jane
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [...],
  "pagination": {...}
}
```

### Get Pending Verification
```http
GET /customers/pending-verification?per_page=10
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [...],
  "pagination": {...}
}
```

### Get Blocked Customers
```http
GET /customers/blocked?per_page=10
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [...],
  "pagination": {...}
}
```

### Get Customer Detail
```http
GET /customers/{id}
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Jane Doe",
    "email": "jane@example.com",
    "phone": "081234567890",
    "phone_verified": true,
    "address": "Jakarta",
    "status": "active",
    "balance": 100000,
    "reward_points": 50,
    ...
  }
}
```

### Verify Customer
```http
POST /customers/{id}/verify
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "message": "Customer berhasil diverifikasi",
  "data": {...}
}
```

### Block/Unblock Customer
Same as Mitra (block/unblock endpoints)

---

## 📦 Pesanan Management

### Get All Pesanan
```http
GET /pesanan?per_page=10&status=completed&search=john
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [
    {
      "id": 123,
      "booking_code": "BOOK-000123",
      "customer": {...},
      "mitra": {...},
      "ride_type": "motor",
      "pickup_location": "Jakarta",
      "dropoff_location": "Bogor",
      "seats": 1,
      "total_price": 50000,
      "status": "completed",
      "created_at": "13 Feb 2026 10:30"
    }
  ],
  "pagination": {...}
}
```

### Get Pesanan Statistics
```http
GET /pesanan/statistics
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "total": 500,
    "pending": 10,
    "accepted": 15,
    "completed": 450,
    "cancelled": 25,
    "today": 15,
    "this_month": 120
  }
}
```

### Get Pesanan Detail
```http
GET /pesanan/{id}
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": 123,
    "booking_code": "BOOK-000123",
    "customer": {...},
    "mitra": {...},
    "vehicle": {...},
    "ride_type": "motor",
    "pickup_location": "Jakarta",
    "pickup_lat": -6.2088,
    "pickup_lng": 106.8456,
    "dropoff_location": "Bogor",
    "dropoff_lat": -6.5971,
    "dropoff_lng": 106.8060,
    "seats": 1,
    "total_price": 50000,
    "payment_method": "cash",
    "status": "completed",
    "notes": null,
    "photo": null,
    ...
  }
}
```

---

## 📋 Laporan Management

### Get All Laporan
```http
GET /laporan?per_page=10&status=pending&type=customer
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "laporan_code": "LAP-000001",
      "reporter_name": "John Doe",
      "reporter_type": "customer",
      "reported_name": "Jane Smith",
      "category": "Pelayanan Buruk",
      "subject": "Mitra tidak sopan",
      "status": "pending",
      "created_at": "11 Feb 2026 14:20"
    }
  ],
  "pagination": {...}
}
```

### Get Statistics
```http
GET /laporan/statistics
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "total": 156,
    "pending": 23,
    "resolved": 120,
    "rejected": 13,
    "today": 5,
    "this_month": 45
  }
}
```

### Get Laporan Detail
```http
GET /laporan/{id}
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "id": 1,
    "laporan_code": "LAP-000001",
    "reporter": {...},
    "reported": {...},
    "category": "Pelayanan Buruk",
    "subject": "Mitra tidak sopan",
    "description": "...",
    "evidence": {...},
    "status": "pending",
    "admin_notes": null,
    ...
  }
}
```

### Create Laporan
```http
POST /laporan
Authorization: Bearer {token}
Content-Type: application/json

{
  "reporter_id": 1,
  "reported_id": 2,
  "category": "Pelayanan Buruk",
  "subject": "Mitra tidak sopan",
  "description": "..."
}

Response 201:
{
  "success": true,
  "message": "Laporan berhasil dibuat"
}
```

### Update Status
```http
PUT /laporan/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "resolved",
  "admin_notes": "Sudah ditindaklanjuti"
}

Response 200:
{
  "success": true,
  "message": "Status laporan berhasil diupdate"
}
```

### Resolve Laporan
```http
POST /laporan/{id}/resolve
Authorization: Bearer {token}
Content-Type: application/json

{
  "resolution": "Mitra diberi peringatan",
  "action_taken": "Warning issued"
}

Response 200:
{
  "success": true,
  "message": "Laporan berhasil diselesaikan"
}
```

---

## 💰 Refund Management

### Get All Refund
```http
GET /refund?per_page=10&status=pending
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "refund_code": "REF-000001",
      "booking_code": "BOOK-000123",
      "customer_name": "John Doe",
      "amount": 50000,
      "reason": "Pembatalan Mitra",
      "status": "pending",
      "created_at": "12 Feb 2026 09:15"
    }
  ],
  "pagination": {...}
}
```

### Get Statistics
```http
GET /refund/statistics
Authorization: Bearer {token}

Response 200:
{
  "success": true,
  "data": {
    "total": 89,
    "pending": 12,
    "approved": 65,
    "rejected": 12,
    "total_amount": 4500000,
    "approved_amount": 3250000,
    "today": 3,
    "this_month": 23
  }
}
```

### Approve Refund
```http
POST /refund/{id}/approve
Authorization: Bearer {token}
Content-Type: application/json

{
  "admin_notes": "Approved",
  "refund_amount": 50000  // optional, jika ingin custom amount
}

Response 200:
{
  "success": true,
  "message": "Refund berhasil disetujui dan saldo dikembalikan"
}
```

### Reject Refund
```http
POST /refund/{id}/reject
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Tidak memenuhi syarat",
  "admin_notes": "..."
}

Response 200:
{
  "success": true,
  "message": "Refund ditolak"
}
```

---

## ⚠️ Error Responses

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Token tidak ditemukan"
}
```

### 422 Validation Error
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "email": ["Email harus diisi"],
    "password": ["Password minimal 6 karakter"]
  }
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Mitra tidak ditemukan"
}
```

### 500 Server Error
```json
{
  "success": false,
  "message": "Error mengambil data dashboard",
  "error": "..."
}
```

---

## 🔧 Tips & Best Practices

1. **Always include Authorization header** untuk protected routes
2. **Handle token expiration** - re-login jika dapat 401
3. **Use pagination** untuk data yang banyak
4. **Validate input** di frontend sebelum kirim ke API
5. **Show loading states** saat request API
6. **Handle errors gracefully** dengan user-friendly messages

---

**Last Updated:** February 13, 2026
