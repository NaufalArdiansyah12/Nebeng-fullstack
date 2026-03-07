import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import '../shared/api_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Callback for when notification is received
  static Function(Map<String, dynamic>)? onNotificationReceived;

  // Callback for when upcoming rides data is fetched
  static Function(List<Map<String, dynamic>>)? onUpcomingRidesFetched;

  // Base URL for API - gunakan ApiConfig (sama seperti PosMitraService)
  static String get baseUrl => ApiConfig.baseUrl;

  // Track notified ride IDs to avoid duplicate notifications
  static final Set<int> _notifiedRideIds = {};

  // Timer for polling upcoming rides
  static Timer? _pollingTimer;

  // Last fetched ride IDs for comparison
  static List<int> _lastRideIds = [];

  // ─────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);

    await Firebase.initializeApp();
    await _initFirebaseMessaging();
  }

  static Future<void> _initFirebaseMessaging() async {
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(
        '🔔 Notification permission: ${settings.authorizationStatus}');

    String? fcmToken = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $fcmToken');

    if (fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);

      await _sendFcmTokenToBackend(fcmToken);
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) _handleInitialMessage(initialMessage);
  }

  // ─────────────────────────────────────────────
  // UPCOMING RIDES
  // ─────────────────────────────────────────────

  /// Ambil daftar tebengan yang akan datang dari API.
  /// Mengembalikan list of ride maps, atau [] jika gagal.
  static Future<List<Map<String, dynamic>>> getUpcomingRides() async {
    try {
      print('🔄 [getUpcomingRides] Fetching upcoming rides...');

      final headers = await _getHeaders();
      if (headers == null) {
        print('⚠️ [getUpcomingRides] No auth token, skipping fetch.');
        return [];
      }

      final url = '${baseUrl}/api/posmitra/upcoming-rides';
      print('📡 [getUpcomingRides] URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      print('📡 [getUpcomingRides] Status: ${response.statusCode}');
      print('📦 [getUpcomingRides] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final rides =
              List<Map<String, dynamic>>.from(data['data'] ?? []);
          print(
              '✅ [getUpcomingRides] Found ${rides.length} upcoming rides');

          // Panggil callback jika ada
          onUpcomingRidesFetched?.call(rides);

          // Cek ride baru dan tampilkan notifikasi
          if (rides.isNotEmpty) {
            await _notifyNewRides(rides);
          }

          return rides;
        }

        throw Exception(
            data['message'] ?? 'Gagal mengambil data tebengan');
      }

      throw Exception(
          'Gagal mengambil data tebengan: ${response.statusCode}');
    } on TimeoutException {
      print('⏱️ [getUpcomingRides] Request timeout');
      return [];
    } catch (e) {
      print('❌ [getUpcomingRides] Error: $e');
      return [];
    }
  }

  /// Cek ride baru dan tampilkan notifikasi jika ada ride baru
  static Future<void> _notifyNewRides(List<Map<String, dynamic>> rides) async {
    // Ambil ID ride sekarang
    final currentRideIds = rides.map((r) => r['id'] as int?).whereType<int>().toList();
    
    // Cari ride baru (yang belum pernah di-fetch sebelumnya)
    final newRideIds = currentRideIds.where((id) => !_lastRideIds.contains(id)).toList();
    
    print('🔔 [_notifyNewRides] Current IDs: $currentRideIds, New IDs: $newRideIds');

    // Jika ada ride baru, tampilkan notifikasi untuk ride terbaru
    if (newRideIds.isNotEmpty && rides.isNotEmpty) {
      // Urutkan rides berdasarkan ID terbesar (paling baru)
      rides.sort((a, b) => (b['id'] as int? ?? 0).compareTo(a['id'] as int? ?? 0));
      
      for (final newId in newRideIds) {
        // Skip jika sudah pernah dinotifikasi
        if (_notifiedRideIds.contains(newId)) continue;
        
        final ride = rides.firstWhere(
          (r) => r['id'] == newId,
          orElse: () => rides.first,
        );
        
        // Tampilkan notifikasi
        await _showUpcomingRideNotification(ride);
        
        // Tandai sudah dinotifikasi
        _notifiedRideIds.add(newId);
      }
    }

    // Update last ride IDs untuk comparasi berikutnya
    _lastRideIds = currentRideIds;
  }

  /// Tampilkan notifikasi untuk ride baru
  static Future<void> _showUpcomingRideNotification(Map<String, dynamic> ride) async {
    final origin = ride['origin'];
    final destination = ride['destination'];
    final time = ride['departure_time'] ?? '';
    final date = ride['departure_date'] ?? '';
    final price = ride['price'] ?? '';
    final rideType = ride['ride_type'] ?? 'tebengan';

    String title = '🚗 Tebengan Baru Available!';
    String body = '';
    
    if (origin != null && destination != null) {
      if (date.isNotEmpty && time.isNotEmpty) {
        body = '$origin → $destination\n$date $time';
      } else {
        body = '$origin → $destination';
      }
      if (price.toString().isNotEmpty) {
        body += '\nHarga: Rp $price';
      }
    } else {
      body = 'Ada tebengan baru yang tersedia!';
    }

    print('🔔 [_notifyNewRides] Showing notification: $title - $body');

    show(
      title,
      body,
      data: {'type': 'upcoming_ride', 'ride_id': ride['id']?.toString()},
    );
  }

  /// Mulai polling otomatis setiap [intervalMinutes] menit.
  /// Panggil ini setelah user login.
  static void startUpcomingRidesPolling({int intervalMinutes = 5}) {
    stopUpcomingRidesPolling(); // Pastikan tidak double timer

    print(
        '⏰ [Polling] Mulai polling upcoming rides setiap $intervalMinutes menit');

    // Fetch langsung pertama kali
    getUpcomingRides();

    _pollingTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => getUpcomingRides(),
    );
  }

  /// Hentikan polling otomatis.
  /// Panggil ini saat user logout atau halaman ditutup.
  static void stopUpcomingRidesPolling() {
    if (_pollingTimer != null) {
      _pollingTimer!.cancel();
      _pollingTimer = null;
      print('🛑 [Polling] Polling upcoming rides dihentikan');
    }
  }

  // ─────────────────────────────────────────────
  // HEADERS HELPER
  // ─────────────────────────────────────────────

  /// Mengembalikan headers dengan Bearer token, atau null jika tidak ada token.
  static Future<Map<String, String>?> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token.isEmpty) return null;

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────
  // FCM TOKEN
  // ─────────────────────────────────────────────

  static Future<void> _sendFcmTokenToBackend(String fcmToken) async {
    try {
      final headers = await _getHeaders();
      if (headers == null) {
        print('⚠️ No API token, skipping FCM token registration');
        return;
      }

      final url = '${baseUrl}/api/v1/posmitra/fcm-token';
      print('📤 [FCM] Sending token to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({'fcm_token': fcmToken}),
      );

      print('📤 FCM token sent: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ FCM token registered successfully');
        }
      }
    } catch (e) {
      print('❌ Error sending FCM token: $e');
    }
  }

  // ─────────────────────────────────────────────
  // FCM MESSAGE HANDLERS
  // ─────────────────────────────────────────────

  static void _handleForegroundMessage(RemoteMessage message) {
    print(
        '📬 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      show(
        message.notification?.title ?? 'Notifikasi',
        message.notification?.body ?? '',
        data: message.data,
      );
    }

    // Jika notif terkait ride baru, refresh upcoming rides
    if (message.data['type'] == 'new_ride') {
      getUpcomingRides();
    }

    onNotificationReceived?.call(message.data);
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('📲 App opened from notification: ${message.notification?.title}');
    onNotificationReceived?.call(message.data);
  }

  static void _handleInitialMessage(RemoteMessage message) {
    print(
        '🚀 Cold start from notification: ${message.notification?.title}');
    onNotificationReceived?.call(message.data);
  }

  // ─────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION
  // ─────────────────────────────────────────────

  static void show(String title, String body,
      {Map<String, dynamic>? data}) {
    const androidDetails = AndroidNotificationDetails(
      'notif_channel',
      'Notifikasi Tebengan',
      importance: Importance.max,
      priority: Priority.high,
    );

    _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID unik
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  // ─────────────────────────────────────────────
  // UTILITY
  // ─────────────────────────────────────────────

  static Future<void> refreshToken() async {
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) await _sendFcmTokenToBackend(fcmToken);
  }

  static Future<void> unsubscribe() async {
    stopUpcomingRidesPolling();
    await _firebaseMessaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
    _notifiedRideIds.clear();
    _lastRideIds.clear();
  }

  /// Reset notified rides (misalnya saat logout atau ingin menerima notifikasi ulang)
  static void resetNotifiedRides() {
    _notifiedRideIds.clear();
    _lastRideIds.clear();
    print('🔄 [NotificationService] Notified rides reset');
  }
}
