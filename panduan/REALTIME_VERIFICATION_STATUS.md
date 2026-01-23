# Realtime Verification Status - Beranda Page

## Fitur yang Ditambahkan

### 1. **Auto-Polling Status**
- Status verifikasi dicek otomatis setiap **10 detik**
- Berjalan di background selama user berada di halaman beranda
- Timer dibersihkan otomatis saat page di-dispose

### 2. **App Lifecycle Observer**
- Menggunakan `WidgetsBindingObserver` untuk detect app state
- Ketika app kembali ke foreground (resumed), status langsung di-refresh
- Memastikan user selalu melihat status terkini

### 3. **Pull-to-Refresh**
- User dapat swipe down untuk manual refresh status
- Menggunakan `RefreshIndicator` widget
- Memberikan kontrol manual kepada user

### 4. **Real-time Notification**
- Ketika status berubah, muncul SnackBar notification
- **Status Approved** ✅: Notifikasi hijau dengan icon check
- **Status Rejected** ❌: Notifikasi merah dengan icon cancel
- Durasi notifikasi: 5 detik
- User dapat dismiss dengan tombol "OK"

### 5. **Status Change Detection**
- Tracking `_previousStatus` untuk detect perubahan
- Hanya show notification saat status benar-benar berubah
- Mencegah notification spam

## Implementasi Teknis

### State Variables
```dart
class _BerandaPageState extends State<BerandaPage> with WidgetsBindingObserver {
  Timer? _statusCheckTimer;
  String _previousStatus = '';
  String _verificationStatus = 'not_verified';
  bool _showKTPWarning = true;
```

### Lifecycle Management
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _loadVerificationStatus();
  _startStatusPolling();
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _statusCheckTimer?.cancel();
  super.dispose();
}

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _loadVerificationStatus();
  }
}
```

### Polling Timer
```dart
void _startStatusPolling() {
  _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    _loadVerificationStatus();
  });
}
```

### Status Change Notification
```dart
void _showStatusChangeNotification(String status) {
  String message;
  Color bgColor;
  IconData icon;

  switch (status) {
    case 'verified':
      message = '🎉 Verifikasi Anda telah disetujui!';
      bgColor = Colors.green;
      icon = Icons.check_circle;
      break;
    case 'rejected':
      message = '❌ Verifikasi Anda ditolak.';
      bgColor = Colors.red;
      icon = Icons.cancel;
      break;
    default:
      return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: bgColor,
      duration: const Duration(seconds: 5),
    ),
  );
}
```

### Pull-to-Refresh
```dart
RefreshIndicator(
  onRefresh: _loadVerificationStatus,
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: Column(/* ... */),
  ),
)
```

## User Experience Flow

### Scenario 1: Admin Approve Verifikasi
1. User upload verifikasi → status: **pending**
2. Admin approve di backend → database status: **approved**
3. Dalam max 10 detik, app auto-refresh status
4. SnackBar hijau muncul: "🎉 Verifikasi Anda telah disetujui!"
5. Warning banner hilang otomatis
6. Layanan menjadi aktif (tidak abu-abu lagi)
7. **Tidak perlu restart app atau re-login!**

### Scenario 2: Admin Reject Verifikasi
1. User upload verifikasi → status: **pending**
2. Admin reject di backend → database status: **rejected**
3. Dalam max 10 detik, app auto-refresh status
4. SnackBar merah muncul: "❌ Verifikasi Anda ditolak"
5. Warning banner update: "Verifikasi KTP ditolak"
6. User dapat klik banner untuk verifikasi ulang

### Scenario 3: Manual Refresh
1. User swipe down di halaman beranda
2. Pull-to-refresh trigger
3. Status langsung di-check dari server
4. UI update sesuai status terbaru

### Scenario 4: App Back to Foreground
1. User minimize app (background)
2. Admin approve/reject verifikasi
3. User buka app lagi (foreground)
4. `didChangeAppLifecycleState` trigger auto-refresh
5. Status langsung update tanpa delay

## Keuntungan

✅ **User-Friendly**: User tidak perlu logout/login ulang
✅ **Instant Feedback**: Max 10 detik untuk status update
✅ **Visual Notification**: Jelas kapan status berubah
✅ **Manual Control**: User bisa pull-to-refresh kapan saja
✅ **Battery Efficient**: Timer interval 10 detik (tidak terlalu sering)
✅ **Lifecycle Aware**: Respect app lifecycle, auto-cleanup resources
✅ **Network Efficient**: Hanya call API sekali setiap interval

## Testing

### Test Case 1: Auto Update
1. Login sebagai customer
2. Upload verifikasi (status: pending)
3. Buka database, ubah status jadi 'approved'
4. Tunggu max 10 detik
5. ✅ Notification muncul dan layanan aktif

### Test Case 2: Pull to Refresh
1. Login sebagai customer
2. Di beranda, swipe down
3. ✅ Refresh indicator muncul
4. ✅ Status di-update dari server

### Test Case 3: App Resume
1. Login dan di halaman beranda
2. Minimize app (tekan home button)
3. Ubah status di database
4. Buka app lagi
5. ✅ Status langsung update

### Test Case 4: Memory Management
1. Buka beranda (timer start)
2. Navigate ke page lain
3. ✅ Timer tetap jalan (feature)
4. Close beranda page
5. ✅ Timer di-cancel (no memory leak)

## Konfigurasi

### Polling Interval
Default: **10 detik**

Untuk mengubah interval:
```dart
// Di method _startStatusPolling()
_statusCheckTimer = Timer.periodic(
  const Duration(seconds: 30), // Ubah jadi 30 detik
  (timer) => _loadVerificationStatus(),
);
```

### Notification Duration
Default: **5 detik**

Untuk mengubah durasi:
```dart
// Di method _showStatusChangeNotification()
SnackBar(
  duration: const Duration(seconds: 10), // Ubah jadi 10 detik
  // ...
)
```

## Troubleshooting

### Status Tidak Update
1. Cek koneksi internet
2. Cek backend server running
3. Cek API token valid
4. Lihat console log untuk error

### Notification Tidak Muncul
1. Pastikan status benar-benar berubah di database
2. Cek `_previousStatus` sudah di-set
3. Pastikan `mounted` check pass

### Timer Memory Leak
1. Pastikan `dispose()` dipanggil
2. Check `_statusCheckTimer?.cancel()` ada
3. Pastikan `removeObserver()` dipanggil

## Future Improvements

- [ ] Push notification (Firebase Cloud Messaging)
- [ ] WebSocket untuk instant update
- [ ] Offline mode detection
- [ ] Retry mechanism saat network error
- [ ] Exponential backoff untuk polling
