import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../customer/main_page.dart';
import '../mitra/main_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendFcmTokenToBackend(String apiToken) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();

      if (fcmToken != null) {
        print('Sending FCM token to backend: $fcmToken');
        final uri = Uri.parse(
          '${const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000')}/api/v1/user/fcm-token',
        );

        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $apiToken',
            'Content-Type': 'application/json',
          },
          body: '{"fcm_token":"$fcmToken"}',
        );

        if (response.statusCode == 200) {
          print('FCM token berhasil dikirim ke backend');
        } else {
          print('Gagal mengirim FCM token: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error sending FCM token: $e');
      // Ignore errors, tidak perlu mengganggu flow login
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      _showResultDialog(
        title: 'Form Tidak Lengkap',
        message: 'Mohon isi email dan password dengan benar.',
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final token = data['token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      final role = user?['role'] as String? ?? 'customer';

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_token', token);
        await prefs.setString('user_role', role);
        // Store user id for later booking/payment calls
        if (user != null && user['id'] != null) {
          final userId = user['id'];
          if (userId is int) {
            await prefs.setInt('user_id', userId);
          } else if (userId is String) {
            await prefs.setInt('user_id', int.parse(userId));
          } else {
            await prefs.setInt('user_id', (userId as num).toInt());
          }
          print('User ID saved: ${prefs.getInt('user_id')}');
        }

        // Kirim FCM token ke backend setelah login berhasil
        _sendFcmTokenToBackend(token);
      }

      if (mounted) {
        _showResultDialog(
          title: 'Login Berhasil!',
          message: 'Selamat datang kembali!',
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
          onClose: () {
            // Redirect based on role
            if (role == 'mitra') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MitraMainPage(),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainPage(),
                ),
              );
            }
          },
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          title: 'Login Gagal',
          message: 'Email atau password salah. Silakan coba lagi.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onClose,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a1a),
                ),
              ),

              const SizedBox(height: 20),

              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 50,
                  color: iconColor,
                ),
              ),

              const SizedBox(height: 20),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 30),

              // Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onClose != null) {
                      onClose();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // Title
                  const Text(
                    'Selamat Datang kembali!\nSenang bertemu denganmu\nlagi!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a1a1a),
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1a1a1a),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan email Anda';
                        }
                        if (!value.contains('@')) {
                          return 'Email tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1a1a1a),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF666666),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan password Anda';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Navigate to forgot password page
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        disabledBackgroundColor: const Color(0xFF93A3C3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Or divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or Login with',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google login button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Implement Google login
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Icon (Custom SVG-style)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: CustomPaint(
                                painter: GoogleLogoPainter(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to register page
                        },
                        child: const Text(
                          'Register Now',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Google Logo Painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue part (top right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height * 0.5)
        ..lineTo(size.width, size.height * 0.25)
        ..arcToPoint(
          Offset(size.width * 0.75, 0),
          radius: Radius.circular(size.width * 0.25),
        )
        ..lineTo(size.width * 0.5, 0)
        ..lineTo(size.width * 0.5, size.height * 0.5)
        ..close(),
      paint,
    );

    // Red part (top left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.5, 0)
        ..lineTo(size.width * 0.25, 0)
        ..arcToPoint(
          Offset(0, size.height * 0.25),
          radius: Radius.circular(size.width * 0.25),
        )
        ..lineTo(0, size.height * 0.5)
        ..close(),
      paint,
    );

    // Yellow part (bottom left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.5)
        ..lineTo(0, size.height * 0.75)
        ..arcToPoint(
          Offset(size.width * 0.25, size.height),
          radius: Radius.circular(size.width * 0.25),
        )
        ..lineTo(size.width * 0.5, size.height)
        ..lineTo(size.width * 0.5, size.height * 0.5)
        ..close(),
      paint,
    );

    // Green part (bottom right)
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.5, size.height)
        ..lineTo(size.width * 0.75, size.height)
        ..arcToPoint(
          Offset(size.width, size.height * 0.75),
          radius: Radius.circular(size.width * 0.25),
        )
        ..lineTo(size.width, size.height * 0.5)
        ..close(),
      paint,
    );

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.25,
      paint,
    );

    // Blue center accent
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.5, size.height * 0.25)
        ..arcToPoint(
          Offset(size.width * 0.75, size.height * 0.5),
          radius: Radius.circular(size.width * 0.25),
        )
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

