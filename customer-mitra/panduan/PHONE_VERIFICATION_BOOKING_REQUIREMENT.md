# ✅ PHONE VERIFICATION REQUIRED FOR BOOKING

## 🎯 Implementasi Selesai

Sistem sudah diupdate agar **customer wajib verifikasi nomor HP** sebelum dapat membuat booking (motor, mobil, barang, titip barang).

---

## 📋 Perubahan Backend

### BookingController.php
Menambahkan validasi di method `store()`:

```php
// Check if user has verified their phone number
$user = User::find($request->user_id);
if (!$user->phone_verified) {
    return response()->json([
        'success' => false,
        'message' => 'Anda harus memverifikasi nomor HP terlebih dahulu sebelum dapat melakukan booking. Silakan verifikasi nomor HP Anda di menu Keamanan.',
        'requires_phone_verification' => true,
    ], 403);
}
```

**Response Error jika belum verifikasi:**
```json
{
  "success": false,
  "message": "Anda harus memverifikasi nomor HP terlebih dahulu sebelum dapat melakukan booking. Silakan verifikasi nomor HP Anda di menu Keamanan.",
  "requires_phone_verification": true
}
```

**HTTP Status Code:** `403 Forbidden`

---

## 📱 TODO: Update Frontend

Frontend perlu menangani response error ini di semua halaman booking:

### 1. Halaman Booking Motor
File: `lib/screens/customer/nebeng_motor/...`

### 2. Halaman Booking Mobil  
File: `lib/screens/customer/nebeng_mobil/...`

### 3. Halaman Booking Barang
File: `lib/screens/customer/nebeng_barang/...`

### 4. Halaman Titip Barang
File: `lib/screens/customer/titip_barang/...`

---

## 💡 Cara Implementasi di Flutter

### Opsi 1: Dialog dengan Navigasi ke Verifikasi

```dart
try {
  final result = await BookingService.createBooking(...);
  // Booking berhasil
} catch (e) {
  final errorMsg = e.toString();
  
  // Cek apakah error karena phone belum verified
  if (errorMsg.contains('verifikasi nomor HP')) {
    _showPhoneVerificationRequiredDialog();
  } else {
    _showErrorDialog(errorMsg);
  }
}

void _showPhoneVerificationRequiredDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Verifikasi Diperlukan'),
        ],
      ),
      content: Text(
        'Anda harus memverifikasi nomor HP terlebih dahulu sebelum dapat melakukan booking.',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close dialog
            // Navigate to phone verification
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhoneVerificationPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1E40AF),
          ),
          child: Text(
            'Verifikasi Sekarang',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
```

### Opsi 2: Parse JSON Response

Jika booking service mengembalikan Map:

```dart
final result = await BookingService.createBooking(...);

if (result['success'] == false && 
    result['requires_phone_verification'] == true) {
  _showPhoneVerificationRequiredDialog();
  return;
}
```

---

## 🔍 Testing

### Test Case 1: User Belum Verifikasi
1. Login sebagai user yang `phone_verified` = NULL/0
2. Coba buat booking motor/mobil/barang/titip
3. **Expected:** Muncul dialog error dengan pesan verifikasi
4. Klik "Verifikasi Sekarang" → Navigate ke PhoneVerificationPage

### Test Case 2: User Sudah Verifikasi  
1. Login sebagai user yang `phone_verified` = 1
2. Coba buat booking
3. **Expected:** Booking berhasil dibuat tanpa error

---

## 📊 Database Check

Cek status verifikasi user:
```sql
SELECT id, name, phone, phone_verified, phone_verified_at 
FROM users 
WHERE id = <user_id>;
```

Update manual untuk testing:
```sql
-- Set user sebagai verified
UPDATE users SET phone_verified = 1, phone_verified_at = NOW() WHERE id = 1;

-- Set user sebagai belum verified
UPDATE users SET phone_verified = 0, phone_verified_at = NULL WHERE id = 1;
```

---

## ✅ Status

- [x] Backend validation implemented
- [x] Error response dengan message jelas
- [x] Flag `requires_phone_verification` untuk frontend
- [ ] Frontend error handling (TODO - implementasi di semua halaman booking)
- [ ] UI/UX dialog verifikasi (TODO)
- [ ] Testing end-to-end (TODO)

---

**Developer Note:** Frontend perlu update semua halaman booking untuk menangani error 403 dengan message phone verification. Prioritaskan user experience dengan memberikan tombol langsung ke halaman verifikasi.
