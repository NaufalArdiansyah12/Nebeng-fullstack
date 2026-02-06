import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/posmitra/posmitra_service.dart';

class UbahEmailPage extends StatefulWidget {
  const UbahEmailPage({Key? key}) : super(key: key);

  @override
  State<UbahEmailPage> createState() => _UbahEmailPageState();
}

class _UbahEmailPageState extends State<UbahEmailPage> {
  int currentStep = 0;
  final TextEditingController _emailController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _handleSubmit() async {
    if (currentStep == 0) {
      // Validate email
      final email = _emailController.text.trim();

      if (email.isEmpty) {
        setState(() {
          errorMessage = 'Email tidak boleh kosong';
        });
        return;
      }

      if (!_isValidEmail(email)) {
        setState(() {
          errorMessage = 'Format email tidak valid';
        });
        return;
      }

      // Move to next step (preview/confirm)
      setState(() {
        errorMessage = null;
        currentStep = 1;
      });
    } else if (currentStep == 1) {
      // Send to backend
      setState(() {
        errorMessage = null;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Token tidak ditemukan. Silakan login.')));
          return;
        }

        final email = _emailController.text.trim();
        final resp = await PosMitraService.updateProfile(email: email);
        if (resp['success'] == true) {
          setState(() {
            currentStep = 2;
          });
        } else {
          final msg = resp['message'] ?? 'Gagal memperbarui email';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      // Return to profile
      Navigator.pop(context);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () {
            if (currentStep > 0 && currentStep < 2) {
              setState(() {
                currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Ubah Email',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildStepContent(),
            ),
          ),
          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  currentStep == 2 ? 'Kembali' : 'Kirim',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _buildStep1Input();
      case 1:
        return _buildStep2Preview();
      case 2:
        return _buildStep3Success();
      default:
        return _buildStep1Input();
    }
  }

  // Step 1: Input new email (empty field)
  Widget _buildStep1Input() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan email baru Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan email baru Anda aktif! Email tersebut akan mengubahkan akun yang digunakan kedalam',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF212121),
            ),
            decoration: InputDecoration(
              hintText: 'Masukkan alamat email baru Anda',
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: errorMessage != null
                    ? const BorderSide(color: Color(0xFFEF5350), width: 1)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: errorMessage != null
                      ? const Color(0xFFEF5350)
                      : const Color(0xFF1E3A8A),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (value) {
              if (errorMessage != null) {
                setState(() {
                  errorMessage = null;
                });
              }
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF5350),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Step 2: Preview/Confirm email
  Widget _buildStep2Preview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan email baru Anda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan email baru Anda aktif! Email tersebut akan mengubahkan akun yang digunakan kedalam',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _emailController.text.trim(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Success
  Widget _buildStep3Success() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text(
            'Email Berhasil Diubah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 40),
          // Success icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 70,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Selamat! Anda telah berhasil mengubah alamat email',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
