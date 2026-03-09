# Fitur QR Bypass untuk Wilayah Tanpa PosMitra

## Deskripsi
Fitur ini memungkinkan superadmin untuk mengaktifkan bypass QR code untuk wilayah tertentu yang tidak memiliki petugas PosMitra. Ketika bypass diaktifkan, mitra dapat menyelesaikan tebengan langsung dengan menekan tombol, tanpa perlu scan QR code di PosMitra.

## Komponen yang Diimplementasikan

### 1. Backend (Laravel)

#### Database
- **Tabel**: `location_qr_bypass_settings`
  - `id`: Primary key
  - `location_id`: Foreign key ke tabel locations
  - `qr_bypass_enabled`: Boolean untuk status bypass
  - `notes`: Catatan opsional (alasan mengaktifkan bypass)
  - `timestamps`: Created at & Updated at

#### Models
- `LocationQRBypassSetting`: Model untuk pengaturan bypass per wilayah
- `Location`: Ditambahkan relasi `qrBypassSetting()`

#### Controllers & API Endpoints

##### SuperAdmin API
- `GET /api/v1/superadmin/location-qr-bypass`
  - Mengambil semua lokasi dengan status bypass-nya
  
- `PUT /api/v1/superadmin/location-qr-bypass/{locationId}`
  - Update setting bypass untuk wilayah tertentu
  - Body: `{ qr_bypass_enabled: boolean, notes: string }`

##### Mitra API
- `GET /api/v1/mitra/location/{locationId}/bypass`
  - Cek apakah wilayah tertentu memiliki bypass enabled
  - Requires authentication
  
- `POST /api/v1/booking/{bookingType}/{bookingId}/complete-by-driver`
  - Menyelesaikan tebengan oleh driver tanpa QR scan
  - Requires authentication
  - Validasi: hanya bisa digunakan jika status = "sudah_sampai_tujuan"

### 2. SuperAdmin Panel (React + TypeScript)

#### Halaman Baru
- **Path**: `/dashboard/qr-bypass-settings`
- **File**: `superadmin/src/pages/QRBypassSettings.tsx`

#### Fitur UI
- Grid card untuk setiap wilayah
- Toggle switch untuk enable/disable bypass per wilayah
- Textarea untuk catatan (alasan bypass)
- Real-time update ke backend
- Toast notification untuk feedback

#### Menu Sidebar
Ditambahkan di bawah menu "Pos Mitra":
- Pengaturan QR Bypass

### 3. Customer-Mitra App (Flutter/Dart)

#### File yang Dimodifikasi
1. **`qr_only_screen.dart`**
   - Converted dari StatelessWidget ke StatefulWidget
   - Menambahkan parameter: `destinationLocationId`, `bookingType`, `bookingId`
   - Cek bypass setting saat init
   - Dua mode tampilan:
     - **QR View**: Tampilan QR code normal (jika bypass OFF)
     - **Bypass View**: Tampilan dengan button "Selesaikan Tebengan" (jika bypass ON)

2. **`tracking_helpers.dart`**
   - Menambahkan helper methods:
     - `getDestinationLocationId()`: Ambil destination location ID
     - `getBookingId()`: Ambil booking ID

3. **`mitra_tracking_map_page_refactored.dart`**
   - Update panggilan `QROnlyScreen` dengan parameter baru

#### Flow Mitra App
1. Mitra sampai di tujuan → Status berubah ke "sudah_sampai_tujuan"
2. App memanggil API check bypass: `GET /api/v1/mitra/location/{locationId}/bypass`
3. Jika bypass enabled:
   - Tampilkan button "Selesaikan Tebengan"
   - Saat button diklik → Call API `POST /api/v1/booking/{type}/{id}/complete-by-driver`
   - Status berubah menjadi "selesai"
4. Jika bypass disabled:
   - Tampilkan QR code seperti biasa
   - Customer harus scan QR di PosMitra

## Cara Penggunaan

### SuperAdmin
1. Login ke SuperAdmin panel
2. Buka menu: **Pos Mitra → Pengaturan QR Bypass**
3. Toggle ON untuk wilayah yang tidak punya PosMitra
4. (Opsional) Tambahkan catatan/alasan
5. Setting otomatis tersimpan

### Mitra
1. Lakukan tebengan seperti biasa
2. Saat sampai di tujuan:
   - **Jika wilayah punya PosMitra**: Tampil QR code → scan di PosMitra
   - **Jika wilayah tanpa PosMitra**: Tampil button → Klik "Selesaikan Tebengan"
3. Status otomatis berubah menjadi selesai

## Keamanan
- Semua endpoint Mitra dilindungi dengan middleware `check.user.status`
- Validasi booking ownership: hanya mitra yang melakukan tebengan yang bisa complete
- Validasi status: hanya booking dengan status "sudah_sampai_tujuan" yang bisa di-complete

## Testing
1. Aktifkan bypass untuk satu wilayah di SuperAdmin
2. Buat tebengan dengan tujuan ke wilayah tersebut
3. Saat sampai di tujuan, verifikasi muncul button bukan QR code
4. Klik button dan verifikasi status berubah menjadi "selesai"
5. Ulangi untuk wilayah dengan bypass OFF untuk memastikan QR code tetap muncul

## Database Migration
```bash
cd backend
php artisan migrate
```

Migration file: `2026_03_05_021250_create_location_qr_bypass_settings_table.php`

## Dependencies
Tidak ada dependency baru yang ditambahkan. Semua menggunakan package yang sudah ada.
