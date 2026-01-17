# Payment Module - Ubah Jadwal

Module untuk menangani pembayaran perubahan jadwal (reschedule payment).

## Struktur Folder

```
payment/
├── reschedule_payment_page.dart        # Halaman utama pembayaran
└── widgets/
    ├── virtual_account_card.dart       # Widget kartu Virtual Account
    ├── payment_info_card.dart          # Widget informasi pembayaran
    └── payment_instruction_card.dart   # Widget instruksi pembayaran
```

## File Descriptions

### 1. reschedule_payment_page.dart
Halaman pembayaran untuk ubah jadwal yang menampilkan:
- Virtual Account number dengan fitur copy
- Total pembayaran
- Instruksi pembayaran
- Tombol konfirmasi pembayaran
- Success screen setelah pembayaran berhasil

**Key Features:**
- Format amount dengan separator ribuan
- Copy VA number to clipboard
- Loading state handling
- Auto navigate to home after success
- Error handling

### 2. virtual_account_card.dart
Widget untuk menampilkan Virtual Account dengan design card yang menarik.

**Features:**
- Gradient background
- Bank name display
- Copy to clipboard functionality
- Responsive design

**Props:**
- `bankCode`: String - Kode bank (bri, bca, bni, dll)
- `virtualAccount`: String - Nomor Virtual Account

### 3. payment_info_card.dart
Widget reusable untuk menampilkan informasi pembayaran.

**Props:**
- `label`: String - Label informasi
- `value`: String - Nilai yang ditampilkan
- `isSelectable`: bool - Apakah text bisa diselect
- `isAmount`: bool - Styling khusus untuk amount

### 4. payment_instruction_card.dart
Widget untuk menampilkan instruksi pembayaran dengan design yang jelas.

**Props:**
- `bankCode`: String - Kode bank untuk instruksi spesifik
- `virtualAccount`: String - Nomor VA

**Features:**
- Info icon
- Clear instructions
- Bank-specific guidance

## Usage Example

```dart
import 'ubah_jadwal/payment/reschedule_payment_page.dart';

// Navigate to payment page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ReschedulePaymentPage(
      requestId: requestId,
      paymentTxnId: paymentId,
      virtualAccount: vaNumber,
      bankCode: 'bri',
      amount: 15000,
    ),
  ),
);
```

## Payment Flow

1. User sees Virtual Account number and amount
2. User transfers money to the VA
3. User clicks "Saya Sudah Bayar" button
4. System confirms payment with backend
5. On success, shows success screen
6. Auto navigate to home after 2 seconds

## API Integration

- `POST /api/v1/reschedule/{id}/confirm-payment` - Confirm reschedule payment

**Request:**
```json
{
  "payment_txn_id": "string"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payment confirmed"
}
```

## Supported Banks

- BRI (Bank Rakyat Indonesia)
- BCA (Bank Central Asia)
- BNI (Bank Negara Indonesia)
- Mandiri
- Permata

## UI/UX Features

1. **Visual Hierarchy**
   - VA card with gradient background
   - Clear amount display
   - Instruction card with info icon

2. **User Guidance**
   - Step-by-step instructions
   - Warning message before confirmation
   - Success feedback

3. **Responsive Design**
   - Adapts to different screen sizes
   - Proper spacing and padding
   - Readable typography

4. **Interactive Elements**
   - Copy VA number with feedback
   - Loading state on button
   - Success animation

## Dependencies

- `flutter/services.dart` - For clipboard functionality
- `api_service.dart` - API calls
