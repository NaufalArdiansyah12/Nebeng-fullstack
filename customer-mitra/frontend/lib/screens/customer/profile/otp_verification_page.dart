import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../services/api/phone_verification_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone;
  final String maskedEmail;

  const OtpVerificationPage({
    Key? key,
    required this.phone,
    required this.maskedEmail,
  }) : super(key: key);

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _remainingAttempts = 3;
  int _countdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _canResend = false;
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    // Check if all fields are filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showErrorDialog('Mohon lengkapi kode OTP 6 digit');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        _showErrorDialog('Sesi Anda telah berakhir. Silakan login kembali.');
        return;
      }

      final result = await PhoneVerificationService.verifyOtp(
        token: token,
        phone: widget.phone,
        otpCode: otp,
      );

      if (result['success'] == true) {
        // Success - show success dialog then go back
        _showSuccessDialog();
      } else {
        // Failed
        if (result['data'] != null &&
            result['data']['remaining_attempts'] != null) {
          _remainingAttempts = result['data']['remaining_attempts'];
        }
        _showErrorDialog(result['message'] ?? 'Kode OTP salah');
        _clearOtp();
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        _showErrorDialog('Sesi Anda telah berakhir. Silakan login kembali.');
        return;
      }

      final result = await PhoneVerificationService.resendOtp(
        token: token,
        phone: widget.phone,
      );

      if (result['success'] == true) {
        _startCountdown();
        _clearOtp();
        _showSnackBar('Kode OTP baru telah dikirim ke email Anda');
      } else {
        _showErrorDialog(result['message'] ?? 'Gagal mengirim ulang kode OTP');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _clearOtp() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gagal'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Berhasil!'),
          ],
        ),
        content: const Text(
          'Nomor HP Anda berhasil diverifikasi',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Go back with success result
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E40AF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Masukan Kode OTP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 60,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Masukan kode anda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Kode berupa 6 digit angka dan huruf',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Email info
            Text(
              'Kode telah dikirimkan melalui email ke',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.maskedEmail.isNotEmpty ? widget.maskedEmail : widget.phone,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // OTP Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF1E40AF),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        // Move to next field
                        if (index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else {
                          // Last field - trigger verification
                          _focusNodes[index].unfocus();
                          _verifyOtp();
                        }
                      }
                    },
                    onTap: () {
                      // Clear this field when tapped
                      _controllers[index].clear();
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Remaining attempts info
            if (_remainingAttempts < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Sisa percobaan: $_remainingAttempts kali',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Verify Button
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Verifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Resend OTP
            Center(
              child: _canResend
                  ? TextButton(
                      onPressed: _isResending ? null : _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Kirim ulang kode',
                              style: TextStyle(
                                color: Color(0xFF1E40AF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    )
                  : Text(
                      'Kirim ulang kode dalam ${_countdown}s',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
