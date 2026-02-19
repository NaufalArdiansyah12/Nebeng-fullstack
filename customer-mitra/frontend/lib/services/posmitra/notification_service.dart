import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Callback for when notification is received
  static Function(Map<String, dynamic>)? onNotificationReceived;
  
  // Base URL for API - should be configured based on environment
  static String _baseUrl = 'https://nebeng-api.example.com';

  static Future<void> init() async {
    // Initialize Flutter Local Notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);
    
    // Initialize Firebase
    await Firebase.initializeApp();
    
    // Initialize FCM
    await _initFirebaseMessaging();
  }
  
  static Future<void> _initFirebaseMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('Notification permission status: ${settings.authorizationStatus}');
    
    // Get FCM token
    String? fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');
    
    if (fcmToken != null) {
      // Save FCM token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', fcmToken);
      
      // Try to get stored base URL
      final storedBaseUrl = prefs.getString('api_base_url');
      if (storedBaseUrl != null) {
        _baseUrl = storedBaseUrl;
      }
      
      // Send FCM token to backend
      await _sendFcmTokenToBackend(fcmToken);
    }
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Check if app was opened from notification (cold start)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }
  
  static Future<void> _sendFcmTokenToBackend(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      
      if (token == null || token.isEmpty) {
        print('No API token found, cannot send FCM token to backend');
        return;
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/posmitra/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'fcm_token': fcmToken,
        }),
      );
      
      print('FCM token sent to backend: ${response.statusCode}');
      print('Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('FCM token registered successfully');
        }
      }
    } catch (e) {
      print('Error sending FCM token to backend: $e');
    }
  }
  
  static void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    // Show local notification
    if (message.notification != null) {
      show(
        message.notification?.title ?? 'Notifikasi',
        message.notification?.body ?? '',
        data: message.data,
      );
    }
    
    // Call callback if set
    if (onNotificationReceived != null) {
      onNotificationReceived!(message.data);
    }
  }
  
  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.notification?.title}');
    
    // Call callback if set
    if (onNotificationReceived != null) {
      onNotificationReceived!(message.data);
    }
  }
  
  static void _handleInitialMessage(RemoteMessage message) {
    print('App opened from cold start with notification: ${message.notification?.title}');
    
    // Call callback if set
    if (onNotificationReceived != null) {
      onNotificationReceived!(message.data);
    }
  }

  static void show(String title, String body, {Map<String, dynamic>? data}) {
    const androidDetails = AndroidNotificationDetails(
      'notif_channel',
      'Notifikasi',
      importance: Importance.max,
      priority: Priority.high,
    );

    _local.show(
      0,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
  
  // Method to refresh FCM token (call this when token is refreshed)
  static Future<void> refreshToken() async {
    String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await _sendFcmTokenToBackend(fcmToken);
    }
  }
  
  // Method to unsubscribe from notifications
  static Future<void> unsubscribe() async {
    await _firebaseMessaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_token');
  }
  
  // Set custom base URL for API
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }
}
