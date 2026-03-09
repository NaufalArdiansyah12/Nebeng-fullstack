import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _local = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _paymentsChannel =
      AndroidNotificationChannel(
    'payments_channel',
    'Payments',
    description: 'Payment notifications',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
    'chat_messages',
    'Chat Messages',
    description: 'New chat message notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'General app notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    final initSettings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(initSettings);

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // Create all notification channels
      await androidPlugin?.createNotificationChannel(_paymentsChannel);
      await androidPlugin?.createNotificationChannel(_chatChannel);
      await androidPlugin?.createNotificationChannel(_defaultChannel);

      print('[NotificationService] Init OK: channels created (default, chat, payments)');
    }
  }

  static Future<void> show({
    required String title,
    required String body,
    int? notificationId,
    String? channelType, // 'chat', 'payment', or null for default
  }) async {
    // Select appropriate channel based on type
    AndroidNotificationChannel channel;
    switch (channelType) {
      case 'chat':
        channel = _chatChannel;
        break;
      case 'payment':
        channel = _paymentsChannel;
        break;
      default:
        channel = _defaultChannel;
    }

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final id = notificationId ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    print('[NotificationService] Showing: id=$id title="$title" body="$body" channel=${channel.id}');
    await _local.show(id, title, body, details);
  }

  // Show notification only if messageId hasn't been seen before.
  static const String _seenKey = 'seen_message_ids';

  static Future<void> showIfNotDuplicate({
    String? messageId,
    required String title,
    required String body,
    String? channelType,
  }) async {
    if (messageId == null || messageId.isEmpty) {
      print('[NotificationService] showIfNotDuplicate: no messageId, showing directly');
      await show(title: title, body: body, channelType: channelType);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey) ?? <String>[];
    if (list.contains(messageId)) {
      print('[NotificationService] Skipping duplicate: messageId=$messageId');
      return;
    }
    print('[NotificationService] showIfNotDuplicate: showing (messageId=$messageId)');

    // add to front, keep max 100 ids
    list.insert(0, messageId);
    if (list.length > 100) list.removeRange(100, list.length);
    await prefs.setStringList(_seenKey, list);

    final id = messageId.hashCode & 0x7fffffff;
    await show(
      title: title,
      body: body,
      notificationId: id,
      channelType: channelType,
    );
  }
}
