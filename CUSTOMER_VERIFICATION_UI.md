# Customer Verification Flow - Flutter Screens

## Overview
Implementasi UI Flutter untuk verifikasi identitas customer dengan 3 jenis verifikasi:
1. Verifikasi Wajah
2. Verifikasi e-KTP
3. Verifikasi Wajah dan e-KTP

## Screen Flow

```
ProfilePage
    ↓
VerifikasiIntroPage (Introduction)
    ↓
VerifikasiTypePage (Choose verification type)
    ↓
VerifikasiUploadPage (Guidelines)
    ↓
VerifikasiFormPage (KTP data form - only for KTP & Face+KTP)
    ↓
VerifikasiCapturePage (Capture/Upload photo)
    ↓
VerifikasiSuccessPage (Success message)
    ↓
VerifikasiStatusPage (View verification status)
```

## Screens Documentation

### 1. VerifikasiIntroPage
**Path:** `lib/screens/customer/profile/verifikasi_intro_page.dart`

**Purpose:** Halaman pengenalan verifikasi akun

**Features:**
- Ilustrasi security dengan dokumen dan shield
- Penjelasan pentingnya verifikasi
- Button "Verifikasi" untuk melanjutkan
- Button "Kembali" untuk cancel

**Navigation:**
- From: ProfilePage
- To: VerifikasiTypePage

---

### 2. VerifikasiTypePage
**Path:** `lib/screens/customer/profile/verifikasi_type_page.dart`

**Purpose:** Memilih jenis verifikasi yang diinginkan

**Features:**
- 3 pilihan verifikasi dengan icon dan deskripsi
- Selection state dengan visual feedback
- Button "Lanjut" yang disabled jika belum memilih

**Options:**
1. Verifikasi wajah (face icon)
2. Verifikasi e-KTP (credit_card icon)
3. Verifikasi wajah dan e-KTP (how_to_reg icon)

**Navigation:**
- From: VerifikasiIntroPage
- To: VerifikasiUploadPage (with verificationType parameter)

---

### 3. VerifikasiUploadPage
**Path:** `lib/screens/customer/profile/verifikasi_upload_page.dart`

**Purpose:** Menampilkan panduan upload dokumen

**Features:**
- Sample document placeholder
- List persyaratan dengan checkmark hijau
- List yang harus dihindari dengan X merah
- Panduan berbeda untuk setiap tipe verifikasi

**Requirements (varies by type):**
- **Face:** Wajah jelas, pencahayaan cukup, tanpa aksesoris, jarak dekat
- **KTP:** Seluruh KTP terlihat, tidak blur, informasi terbaca, tidak ada pantulan
- **Face+KTP:** Wajah dan KTP jelas, informasi terbaca, wajah tidak tertutup

**Navigation:**
- From: VerifikasiTypePage
- To: 
  - VerifikasiCapturePage (for face verification)
  - VerifikasiFormPage (for KTP & Face+KTP)

---

### 4. VerifikasiFormPage
**Path:** `lib/screens/customer/profile/verifikasi_form_page.dart`

**Purpose:** Form input data KTP (hanya untuk verifikasi KTP dan Face+KTP)

**Features:**
- Input nama lengkap
- Input NIK (16 digit, numeric only)
- Date picker untuk tanggal lahir
- Textarea untuk alamat
- Form validation

**Validation:**
- Nama lengkap: required
- NIK: required, exactly 16 digits
- Tanggal lahir: required
- Alamat: required

**Navigation:**
- From: VerifikasiUploadPage
- To: VerifikasiCapturePage (with form data)

---

### 5. VerifikasiCapturePage
**Path:** `lib/screens/customer/profile/verifikasi_capture_page.dart`

**Purpose:** Capture atau upload foto untuk verifikasi

**Features:**
- Preview area dengan border frame
- Button "Ambil Foto" (camera)
- Button "Pilih dari Galeri" (gallery)
- Image preview setelah foto diambil
- Button "Ambil Ulang" dan "Gunakan Foto"
- Upload foto ke backend

**Image Settings:**
- Max resolution: 1920x1920
- Quality: 85%
- Supported formats: jpeg, png, jpg

**Navigation:**
- From: VerifikasiUploadPage or VerifikasiFormPage
- To: VerifikasiSuccessPage (after successful upload)

---

### 6. VerifikasiSuccessPage
**Path:** `lib/screens/customer/profile/verifikasi_success_page.dart`

**Purpose:** Menampilkan pesan sukses setelah upload

**Features:**
- Animated success illustration (green circle with checkmark)
- Success message sesuai tipe verifikasi
- Informasi bahwa verifikasi sedang di-review
- Button "Lanjut" ke status page

**Navigation:**
- From: VerifikasiCapturePage
- To: VerifikasiStatusPage (removes all previous routes)

---

### 7. VerifikasiStatusPage
**Path:** `lib/screens/customer/profile/verifikasi_status_page.dart`

**Purpose:** Menampilkan status verifikasi customer

**Features:**
- Load status dari API
- Tampilan 3 jenis verifikasi dengan checkmark untuk yang sudah selesai
- Status badge (pending/approved/rejected) dengan warna berbeda
- Button action sesuai status:
  - "Lanjut" - jika belum verifikasi
  - "Menunggu Review" - jika pending (disabled)
  - "Verifikasi Selesai" - jika approved (disabled)

**Status Colors:**
- Pending: Orange (#F59E0B)
- Approved: Green (#10B981)
- Rejected: Red (#EF4444)

**Navigation:**
- From: VerifikasiSuccessPage or ProfilePage
- To: VerifikasiTypePage (if status allows)

---

## Models

### VerifikasiCustomer
**Path:** `lib/models/verifikasi_model.dart`

```dart
class VerifikasiCustomer {
  final int? id;
  final String? namaLengkap;
  final String? nik;
  final String? tanggalLahir;
  final String? alamat;
  final String? photoWajah;
  final String? photoKtp;
  final String? photoKtpWajah;
  final String status;
  final String? reviewedAt;
  final String? createdAt;
  final String? updatedAt;
}
```

### VerifikasiStatus
```dart
class VerifikasiStatus {
  final bool hasVerification;
  final String? status;
  final bool verifikasiWajah;
  final bool verifikasiKtp;
  final bool verifikasiWajahKtp;
}
```

---

## Services

### VerifikasiService
**Path:** `lib/services/verifikasi_service.dart`

**Methods:**

1. `getVerificationStatus(String token)`
   - Get current verification status

2. `getVerification(String token)`
   - Get detailed verification data

3. `uploadFacePhoto({required String token, required File photo})`
   - Upload face photo

4. `uploadKtpPhoto({...})`
   - Upload KTP photo with data

5. `uploadFaceKtpPhoto({...})`
   - Upload face+KTP photo with data

6. `submitVerification(String token)`
   - Submit verification for review

---

## Design System

### Colors
```dart
Primary Blue: #1E40AF
Success Green: #10B981
Warning Orange: #F59E0B
Error Red: #EF4444
Gray Background: #F5F5F5
Border Gray: #E5E7EB
Text Dark: #1A1A1A
Text Gray: #666666
```

### Typography
```dart
Page Title: 24px, Bold
Section Title: 18px, Bold
Card Title: 16px, Semi-Bold
Body Text: 14px, Regular
Caption: 13px, Regular
```

### Common Components
- Elevated buttons with rounded corners (8px)
- Outlined buttons for secondary actions
- Card containers with shadow
- Icon badges with colored backgrounds
- Status indicators with colored circles

---

## Integration Points

### Entry Point
Add to ProfilePage menu:
```dart
_buildMenuItem(
  icon: Icons.verified_user,
  iconColor: const Color(0xFF1E40AF),
  title: 'Verifikasi Akun',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VerifikasiIntroPage(),
      ),
    );
  },
),
```

### Required Dependencies
```yaml
dependencies:
  image_picker: ^latest
  shared_preferences: ^latest
  http: ^latest
```

### Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

---

## Testing Checklist

- [ ] Navigate through all screens
- [ ] Select each verification type
- [ ] Form validation works correctly
- [ ] Camera capture works
- [ ] Gallery selection works
- [ ] Photo preview displays correctly
- [ ] Upload to backend succeeds
- [ ] Success page shows correct message
- [ ] Status page loads verification data
- [ ] Status indicators show correct colors
- [ ] Error handling works (network errors, validation errors)
- [ ] Loading states display properly
- [ ] Back navigation works on all screens

---

## Future Enhancements

1. Add face detection validation
2. Add OCR for automatic KTP data extraction
3. Add liveness detection for face verification
4. Add photo quality validation
5. Add progress indicator for multi-step process
6. Add ability to retake/reupload after rejection
7. Add notification when verification is approved/rejected
