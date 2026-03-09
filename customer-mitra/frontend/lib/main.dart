import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/shared/notification_service.dart';
import 'models/user_role.dart';
import 'screens/auth/loading_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/customer/main_page.dart';
import 'screens/mitra/main_page.dart';
import 'screens/posmitra/main_page.dart';
import 'package:http/http.dart' as http;
import 'services/shared/api_config.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('[FCM] Background handler: messageId=${message.messageId}, data=${message.data}');
  final n = message.notification;
  final msgId =
      message.messageId ?? message.data['message_id'] ?? message.data['id'];
  if (n != null) {
    print('[FCM] Background: showing notification "${n.title}" / "${n.body}"');
    await NotificationService.showIfNotDuplicate(
        messageId: (msgId is String && msgId.isNotEmpty) ? msgId : null,
        title: n.title ?? 'Nebeng',
        body: n.body ?? '');
  } else {
    print('[FCM] Background: no notification payload');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Firebase Web configuration for Nebeng1 project
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBUbH0l6mEyV2Ljpm4bMJNSnQ8sZYFz0d8',
        authDomain: 'nebeng1.firebaseapp.com',
        projectId: 'nebeng1',
        storageBucket: 'nebeng1.firebasestorage.app',
        messagingSenderId: '182582993392',
        appId: '1:182582993392:web:8722c82a418eb850ba3d35',
        measurementId: 'G-K854K8MNHP',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  // Initialize notifications and FCM only on mobile platforms.
  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (e, st) {
      // Notification service init failed
    }

    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS)
      final permission = await messaging.requestPermission(alert: true, badge: true, sound: true);
      print('[FCM] Permission status: ${permission.authorizationStatus}');

      // Get token and (optionally) send to backend
      final token = await messaging.getToken();

      print('[FCM] Token: ${token != null ? "${token.length} chars" : "null"}');

      try {
        final prefs = await SharedPreferences.getInstance();
        final apiToken = prefs.getString('api_token');
        final userRole = prefs.getString('user_role') ?? 'customer';
        print('[FCM] user_role=$userRole, has_api_token=${apiToken != null && apiToken.isNotEmpty}');

        if (token != null && apiToken != null && apiToken.isNotEmpty) {
          // Determine the correct endpoint based on user role (pos_mitra = posmitra)
          final isPosMitra = userRole == 'posmitra' || userRole == 'pos_mitra';
          String endpoint;
          if (isPosMitra) {
            endpoint = '/api/v1/posmitra/fcm-token';
            print('[FCM] PosMitra -> sending token to posmitra endpoint');
          } else {
            endpoint = '/api/v1/user/fcm-token';
            print('[FCM] User -> sending token to user endpoint');
          }

          final baseUrl = ApiConfig.baseUrl;
          final uri = Uri.parse('$baseUrl$endpoint');
          print('[FCM] POST $uri');

          final response = await http.post(uri,
              headers: {
                'Authorization': 'Bearer $apiToken',
                'Content-Type': 'application/json'
              },
              body: '{"fcm_token":"$token"}');
          print('[FCM] POST fcm-token response: status=${response.statusCode}, body=${response.body}');
        } else {
          if (token == null) {
            print('[FCM] Skip sending token: FCM token is null');
          } else {
            print('[FCM] Skip sending token: no api_token or empty (user not logged in?)');
          }
        }
      } catch (e, st) {
        print('[FCM] Error sending token to backend: $e');
        print('[FCM] $st');
      }

      // Listen for token refreshes and update backend when it happens
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final apiToken = prefs.getString('api_token');
          final userRole = prefs.getString('user_role') ?? 'customer';
          
          if (newToken != null && apiToken != null && apiToken.isNotEmpty) {
            final isPosMitra = userRole == 'posmitra' || userRole == 'pos_mitra';
            String endpoint;
            if (isPosMitra) {
              endpoint = '/api/v1/posmitra/fcm-token';
              print('[FCM] PosMitra -> sending refreshed token to posmitra endpoint');
            } else {
              endpoint = '/api/v1/user/fcm-token';
            }
            final baseUrl = ApiConfig.baseUrl;
            final uri = Uri.parse('$baseUrl$endpoint');
            
            await http.post(uri,
                headers: {
                  'Authorization': 'Bearer $apiToken',
                  'Content-Type': 'application/json'
                },
                body: '{"fcm_token":"$newToken"}');
          }
        } catch (e) {
          // ignore
        }
      });

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {

        print('[FCM] 📨 Message received (foreground)');
        print('[FCM]    messageId: ${message.messageId}');
        print('[FCM]    data: ${message.data}');


        final n = message.notification;
        final msgId = message.messageId ??
            message.data['message_id'] ??
            message.data['id'];

        // Check if this is a chat message notification
        final notificationType = message.data['type'];

        if (n != null) {
          print('[FCM]    notification title: ${n.title}');
          print('[FCM]    notification body: ${n.body}');
          print('[FCM]    calling NotificationService.showIfNotDuplicate');


          // Use 'chat' channel for chat messages, default for others
          final channelType =
              notificationType == 'chat_message' ? 'chat' : null;

          await NotificationService.showIfNotDuplicate(
            messageId: (msgId is String && msgId.isNotEmpty) ? msgId : null,
            title: n.title ?? 'Nebeng',
            body: n.body ?? '',
            channelType: channelType,
          );

          print('[FCM]    showIfNotDuplicate done');
        } else {
          print('[FCM]    No notification payload (data-only message) - type: $notificationType');
        }

        if (notificationType == 'chat_message') {
          print('[FCM]    Type: Chat Message');
          print('[FCM]    Sender: ${message.data['sender_name']}');
          print('[FCM]    Conversation: ${message.data['conversation_id']}');

        }
      });

      // Background message handler (when app is in background but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {

        print('[FCM] 📬 Notification opened from background');
        print('[FCM]    data: ${message.data}');

        final notificationType = message.data['type'];
        if (notificationType == 'chat_message') {


          final conversationId = message.data['conversation_id'];
          final senderName = message.data['sender_name'];
          print('[FCM]    Opening chat: $conversationId with $senderName');

        }
      });

      // Handle notification that opened the app from terminated state
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {

        print('[FCM] 📭 App opened from notification (terminated state)');
        print('[FCM]    data: ${initialMessage.data}');

        final notificationType = initialMessage.data['type'];
        if (notificationType == 'chat_message') {

          // TODO: Store this to navigate after app initializes

          final conversationId = initialMessage.data['conversation_id'];
          print('[FCM]    Should open chat: $conversationId');

        }
      } else {
        print('[FCM] No initial message (app opened normally)');
      }
      print('[FCM] Firebase messaging init done');
    } catch (e, st) {

      // Firebase messaging init failed

      print('[FCM] Firebase messaging init error: $e');
      print('[FCM] $st');

    }
  }

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('id'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nebeng',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const AuthChecker(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Hapus delay agar langsung cepat
    // await Future.delayed(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    final role = prefs.getString('user_role') ?? 'customer';

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // User sudah login, redirect berdasarkan role
      final userRole = UserRole.fromString(role);

      if (userRole.isMitra) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MitraMainPage()),
        );
      } else if (userRole.isPosMitra) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PosMitraMainPage()),
        );
      } else {
        // Default customer atau role lainnya
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } else {
      // User belum login, redirect ke onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingScreen();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
