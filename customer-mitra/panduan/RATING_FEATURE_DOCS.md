# Fitur Rating Driver/Mitra

## Deskripsi
Fitur ini memungkinkan customer untuk memberikan rating (1-5 bintang) dan review text kepada driver/mitra setelah perjalanan selesai (status booking = `completed`).

## Backend API

### Endpoint yang Digunakan
1. **POST** `/api/v1/ratings` - Submit rating baru
2. **GET** `/api/v1/ratings/booking/{bookingId}?booking_type={type}` - Get rating untuk booking tertentu
3. **GET** `/api/v1/ratings/driver/{driverId}` - Get semua rating driver

### Request Format (Submit Rating)
```json
{
  "booking_id": 123,
  "booking_type": "motor|mobil|barang|titip_barang",
  "driver_id": 456,
  "rating": 5,
  "review": "Perjalanan sangat nyaman dan aman" // opsional
}
```

### Response Format
```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "data": {
    "id": 1,
    "booking_id": 123,
    "booking_type": "motor",
    "user_id": 789,
    "driver_id": 456,
    "rating": 5,
    "review": "Perjalanan sangat nyaman dan aman",
    "created_at": "2026-01-28T10:30:00.000000Z",
    "updated_at": "2026-01-28T10:30:00.000000Z"
  }
}
```

## Frontend Implementation

### Files Created/Modified

#### 1. API Service (`lib/services/api_service.dart`)
Ditambahkan 3 method baru:
- `submitRating()` - Submit rating ke backend
- `getRating()` - Get rating untuk booking tertentu
- `getDriverRatings()` - Get semua rating driver

#### 2. Rating Dialog (`lib/screens/customer/riwayat/booking_detail/widgets/rating_dialog.dart`)
Dialog untuk input rating dengan fitur:
- Interactive 5-star rating selector
- Review text input (opsional, max 500 karakter)
- Driver info display
- Loading state
- Error handling

#### 3. Rating Card (`lib/screens/customer/riwayat/booking_detail/widgets/rating_card.dart`)
Card widget untuk menampilkan:
- **Belum rating**: Tombol "Beri Rating Driver"
- **Sudah rating**: Tampilkan rating yang sudah diberikan dengan bintang, review text, dan timestamp

#### 4. Booking Detail Page (`lib/screens/customer/riwayat/booking_detail_riwayat_page.dart`)
Modifikasi:
- Import rating widgets
- State untuk menyimpan `existingRating`
- Method `_fetchRating()` untuk load rating saat init (jika status completed)
- Method `_showRatingDialog()` untuk menampilkan rating dialog
- Menampilkan RatingCard di bawah PriceCard (hanya untuk status completed)

## Flow Penggunaan

1. **Customer membuka detail booking dengan status completed**
   - Halaman akan otomatis fetch rating jika sudah pernah diberi rating
   - Menampilkan RatingCard di bawah informasi harga

2. **Jika belum pernah rating:**
   - RatingCard menampilkan tombol "Beri Rating Driver"
   - Customer klik tombol tersebut
   - Dialog rating muncul

3. **Customer memberikan rating:**
   - Pilih jumlah bintang (1-5)
   - Tulis review (opsional)
   - Klik "Kirim Rating"
   - Dialog menutup dan rating di-fetch ulang

4. **Jika sudah pernah rating:**
   - RatingCard menampilkan rating yang sudah diberikan
   - Menampilkan jumlah bintang
   - Menampilkan review text (jika ada)
   - Menampilkan tanggal rating diberikan

## Validasi

### Backend
- Rating wajib diisi (1-5)
- Booking harus completed
- Booking harus milik user yang login
- Driver ID harus valid
- Tidak boleh rating 2x untuk booking yang sama

### Frontend
- User harus pilih rating (1-5) sebelum submit
- Review text maksimal 500 karakter
- Loading state saat submit
- Error handling dengan snackbar

## UI/UX Features

### Rating Dialog
- Beautiful gradient header dengan icon
- Driver photo & name display
- Interactive star rating (tap to select)
- Real-time feedback (Sangat Buruk, Buruk, Cukup, Baik, Sangat Baik)
- Color-coded rating text (red, orange, green)
- Optional review dengan hint text
- Dual action buttons (Batal & Kirim Rating)
- Loading indicator saat submit

### Rating Card
- Icon badge (star) dengan warna sesuai status
- Informative text untuk status
- **Before rating**: Call-to-action button
- **After rating**: 
  - Stars visualization
  - Numeric rating (e.g., "5.0")
  - Review text dalam card dengan icon
  - Timestamp dengan format Indonesia

## Notes

- Fitur ini hanya muncul untuk booking dengan status `completed`
- User hanya bisa rating sekali per booking
- Rating akan mempengaruhi average rating driver
- Review bersifat opsional tapi direkomendasikan untuk feedback yang lebih detail
