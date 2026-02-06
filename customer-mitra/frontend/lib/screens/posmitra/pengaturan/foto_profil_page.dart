import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/posmitra/posmitra_service.dart';

class FotoProfilPage extends StatefulWidget {
  const FotoProfilPage({Key? key}) : super(key: key);

  @override
  State<FotoProfilPage> createState() => _FotoProfilPageState();
}

class _FotoProfilPageState extends State<FotoProfilPage> {
  int currentStep = 0;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;

  void _nextStep() {
    if (currentStep < 4) {
      setState(() {
        currentStep++;
      });
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 800);
      if (picked != null) {
        setState(() {
          _pickedImage = picked;
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih foto terlebih dahulu')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Token tidak ditemukan. Silakan login.')));
        return;
      }

      final resp = await PosMitraService.updateProfile(
          photoFilePath: _pickedImage!.path);
      if (resp['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diunggah')));
        setState(() => currentStep = 4);
        // Auto-close and bubble success after a short delay so parent reloads
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        final msg = resp['message'] ?? 'Gagal mengunggah foto';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
            if (currentStep > 0) {
              _previousStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Foto Profil',
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
                onPressed: _handleButtonPress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _getButtonText(),
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
        return _buildStep1Info();
      case 1:
        return _buildStep2Upload();
      case 2:
        return _buildStep3Position();
      case 3:
        return _buildStep4Preview();
      case 4:
        return _buildStep5Success();
      default:
        return _buildStep1Info();
    }
  }

  Widget _buildStep1Info() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ikuti panduan foto untuk mempermudah Anda dalam mengambil foto',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[700], height: 1.4),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: _pickedImage != null
                ? ClipOval(
                    child: Image.file(File(_pickedImage!.path),
                        width: 120, height: 120, fit: BoxFit.cover))
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Foto Profil',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showImageOptions,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Ambil foto',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Upload() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Panduan Upload Dokumen',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121))),
          const SizedBox(height: 32),
          Container(
            width: 160,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person, size: 80, color: Colors.grey[400]),
          ),
          const SizedBox(height: 12),
          const Text('Tampak Document',
              style: TextStyle(fontSize: 13, color: Color(0xFF757575))),
          const SizedBox(height: 32),
          _buildRequirementBox(
            color: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF4CAF50),
            icon: Icons.check,
            title: 'Persyaratan:',
            items: [
              'Foto menggunakan latar belakang putih polos',
              'Tanpa menggunakan aksesori seperti topi / kacamata hitam, dll',
            ],
          ),
          const SizedBox(height: 16),
          _buildRequirementBox(
            color: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFEF5350),
            icon: Icons.close,
            title: 'Yang harus dihindari:',
            items: ['Akan dapat penolakan ke ketekang dan terpotong'],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementBox({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration:
                    BoxDecoration(color: iconColor, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121)))),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                          color: Color(0xFF424242), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(item,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF424242),
                                height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStep3Position() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('Posisikan wajah Anda dalam lingkaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121))),
          const SizedBox(height: 8),
          Text('Posisikan wajahmu terhadap jelas',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 40),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF1E3A8A), width: 3)),
              ),
              Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                    color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                child: Icon(Icons.person, size: 120, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Preview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Ikuti panduan foto untuk mempermudah Anda dalam mengambil foto',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4))),
                const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12)),
            child: _pickedImage != null
                ? ClipOval(
                    child: Image.file(File(_pickedImage!.path),
                        width: 140, height: 140, fit: BoxFit.cover))
                : Icon(Icons.person, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showImageOptions,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              side: const BorderSide(color: Color(0xFF1E3A8A)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Ambil foto',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A))),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Success() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          const Text('Foto Profil Berhasil Disimpan',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121))),
          const SizedBox(height: 40),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 30,
                    offset: Offset(0, 10))
              ],
            ),
            child: const Icon(Icons.check, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text('Selamat! Anda telah berhasil\nmenambahkan foto profil',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (currentStep) {
      case 0:
        return 'Simpan';
      case 1:
        return 'Selanjutnya';
      case 2:
        return 'Ambil foto';
      case 3:
        return 'Simpan';
      case 4:
        return 'Kembali';
      default:
        return 'Lanjut';
    }
  }

  void _handleButtonPress() async {
    if (currentStep == 4) {
      // Return true to signal parent that a change was made
      Navigator.pop(context, true);
      return;
    }

    // If we have a picked image and we are at a step that should save, upload it
    if ((_pickedImage != null) && (currentStep == 0 || currentStep == 3)) {
      await _uploadPhoto();
      return;
    }

    _nextStep();
  }
}
