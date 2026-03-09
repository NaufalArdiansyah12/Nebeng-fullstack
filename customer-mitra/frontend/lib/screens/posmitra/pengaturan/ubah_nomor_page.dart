import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/posmitra/posmitra_service.dart';

class UbahNomorPage extends StatefulWidget {
  const UbahNomorPage({Key? key}) : super(key: key);

  @override
  State<UbahNomorPage> createState() => _UbahNomorPageState();
}

class _UbahNomorPageState extends State<UbahNomorPage> {
  int currentStep = 0;
  final TextEditingController _phoneController = TextEditingController();
  String? errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10,15}$').hasMatch(phone);
  }

  void _handleSubmit() async {
    if (currentStep == 0) {
      final phone = _phoneController.text.trim();

      if (phone.isEmpty) {
        setState(() {
          errorMessage = 'Nomor telepon tidak boleh kosong';
        });
        return;
      }

      if (!_isValidPhone(phone)) {
        setState(() {
          errorMessage = 'Format nomor telepon tidak valid';
        });
        return;
      }

      setState(() {
        errorMessage = null;
        currentStep = 1;
      });
    } else if (currentStep == 1) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');

        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Token tidak ditemukan. Silakan login.')),
          );
          return;
        }

        final phone = _phoneController.text.trim();

        final resp = await PosMitraService.updateProfile(
          phone: phone, // 🔥 kirim phone bukan email
        );

        if (resp['success'] == true) {
          setState(() {
            currentStep = 2;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp['message'] ?? 'Gagal memperbarui nomor')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      Navigator.pop(context, true);
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
          'Ubah Nomor Telepon',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: SingleChildScrollView(child: _buildStepContent())),
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  currentStep == 2 ? 'Kembali' : 'Kirim',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

  Widget _buildStep1Input() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan nomor telepon baru Anda',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Contoh: 081234567890',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2Preview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfirmasi Nomor Telepon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _phoneController.text.trim(),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Success() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nomor Telepon Berhasil Diubah',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
