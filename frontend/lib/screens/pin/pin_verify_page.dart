import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../widgets/pin_input_widget.dart';
import '../widgets/numeric_keypad.dart';
import 'pin_success_page.dart';

class PinVerifyPage extends StatefulWidget {
  final String pinToVerify;
  final bool isChangingPin;

  const PinVerifyPage({
    Key? key,
    required this.pinToVerify,
    this.isChangingPin = false,
  }) : super(key: key);

  @override
  State<PinVerifyPage> createState() => _PinVerifyPageState();
}

class _PinVerifyPageState extends State<PinVerifyPage> {
  String _pin = '';
  String? _errorMessage;
  final int _pinLength = 6;

  void _onNumberPressed(String number) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _onVerify() async {
    if (_pin.length == _pinLength) {
      if (_pin == widget.pinToVerify) {
        // PIN matched, save it
        await _savePin(_pin);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PinSuccessPage(),
          ),
        );
      } else {
        // PIN doesn't match
        setState(() {
          _errorMessage = 'Harap verifikasi PIN dengan benar';
          _pin = '';
        });
      }
    }
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    // Hash the PIN before storing/sending
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();

    final token = prefs.getString('api_token');
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token tidak ditemukan')),
      );
      return;
    }

    try {
      final resp =
          await ApiService.createPin(token: token, hashedPin: hashedPin);
      if (resp['success'] == true) {
        // store locally as backup
        await prefs.setString('user_pin', hashedPin);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Gagal membuat PIN')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error membuat PIN: ${e.toString()}')),
      );
    }
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
        title: Text(
          widget.isChangingPin ? 'Buat PIN' : 'Verifikasi PIN',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: const Color(0xFF1E3A8A),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Verifikasi PIN Anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PIN berupa 6 digit angka',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                PinInputWidget(pin: _pin),
                const SizedBox(height: 12),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pin.length == _pinLength ? _onVerify : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        widget.isChangingPin ? 'Ubah' : 'Verifikasi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          NumericKeypad(
            onNumberPressed: _onNumberPressed,
            onBackspace: _onBackspace,
          ),
        ],
      ),
    );
  }
}
