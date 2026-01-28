import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/customer/main_page.dart';
import 'screens/mitra/main_page.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final n = message.notification;
  final msgId =
      message.messageId ?? message.data['message_id'] ?? message.data['id'];
  if (n != null) {
    await NotificationService.showIfNotDuplicate(
        messageId: (msgId is String && msgId.isNotEmpty) ? msgId : null,
        title: n.title ?? 'Nebeng',
        body: n.body ?? '');
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
      print('NotificationService.init error: $e\n$st');
    }

    try {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get token and (optionally) send to backend
      final token = await messaging.getToken();
      print('FCM token: $token');
      try {
        final prefs = await SharedPreferences.getInstance();
        final apiToken = prefs.getString('api_token');
        if (token != null && apiToken != null && apiToken.isNotEmpty) {
          // Replace BASE_URL with your backend base URL if needed
          final uri = Uri.parse(
              '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000')}/api/v1/user/fcm-token');
          await http.post(uri,
              headers: {
                'Authorization': 'Bearer $apiToken',
                'Content-Type': 'application/json'
              },
              body: '{"fcm_token":"$token"}');
        }
      } catch (e) {
        // ignore errors
      }

      // Foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final n = message.notification;
        final msgId = message.messageId ??
            message.data['message_id'] ??
            message.data['id'];
        if (n != null) {
          await NotificationService.showIfNotDuplicate(
              messageId: (msgId is String && msgId.isNotEmpty) ? msgId : null,
              title: n.title ?? 'Nebeng',
              body: n.body ?? '');
        }
      });
    } catch (e, st) {
      print('Firebase messaging init error: $e\n$st');
    }
  }

  runApp(const MyApp());
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
      locale: const Locale('id', 'ID'),
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
    // Tunggu sebentar agar tidak flicker
    await Future.delayed(const Duration(milliseconds: 100));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    final role = prefs.getString('user_role') ?? 'customer';

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // User sudah login, redirect berdasarkan role
      if (role == 'mitra') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MitraMainPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } else {
      // User belum login, redirect ke splash screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading indicator sementara mengecek auth
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
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
