import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'payments_channel',
    'Payments',
    description: 'Payment notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(initSettings);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  static Future<void> show(
      {required String title,
      required String body,
      int? notificationId}) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    final iosDetails = DarwinNotificationDetails();

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final id = notificationId ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _local.show(id, title, body, details);
  }

  // Show notification only if messageId hasn't been seen before.
  static const String _seenKey = 'seen_message_ids';

  static Future<void> showIfNotDuplicate(
      {String? messageId, required String title, required String body}) async {
    if (messageId == null || messageId.isEmpty) {
      await show(title: title, body: body);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey) ?? <String>[];
    if (list.contains(messageId)) return;

    // add to front, keep max 100 ids
    list.insert(0, messageId);
    if (list.length > 100) list.removeRange(100, list.length);
    await prefs.setStringList(_seenKey, list);

    final id = messageId.hashCode & 0x7fffffff;
    await show(title: title, body: body, notificationId: id);
  }
}
