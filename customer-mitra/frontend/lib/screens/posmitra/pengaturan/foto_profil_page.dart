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
  // 🔥 SEDERHANAKAN: Hanya 3 step
  static const int STEP_PILIH_FOTO = 0;
  static const int STEP_UPLOADING = 1;
  static const int STEP_SUKSES = 2;
  
  int currentStep = STEP_PILIH_FOTO;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (picked != null) {
        // 🔥 VALIDASI UKURAN FILE (max 2MB)
        final file = File(picked.path);
        final fileSize = await file.length();
        
        if (fileSize > 2 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran foto maksimal 2MB'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // 🔥 VALIDASI FORMAT FILE
        final extension = picked.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Format foto harus JPG/PNG'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        setState(() {
          _pickedImage = picked;
        });
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF1E3A8A)),
              ),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(c);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF1E3A8A)),
              ),
              title: const Text(
                'Ambil Foto',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
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
        const SnackBar(
          content: Text('Silakan pilih foto terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      currentStep = STEP_UPLOADING;
    });

    try {
      final resp = await PosMitraService.updateProfile(
        photoFilePath: _pickedImage!.path,
      );
      
      if (!mounted) return;
      
      if (resp['success'] == true) {
        setState(() {
          _isUploading = false;
          currentStep = STEP_SUKSES;
        });
        
        // Auto close setelah 1.5 detik
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          Navigator.pop(context, true);
        });
      } else {
        setState(() {
          _isUploading = false;
          currentStep = STEP_PILIH_FOTO;
        });
        
        final msg = resp['message'] ?? 'Gagal mengunggah foto';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        currentStep = STEP_PILIH_FOTO;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () {
            if (currentStep == STEP_UPLOADING) {
              // Jangan izinkan back saat uploading
              return;
            }
            Navigator.pop(context, currentStep == STEP_SUKSES);
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
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildStepContent(),
            ),
          ),
          if (currentStep != STEP_UPLOADING) // Sembunyikan button saat uploading
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
      case 0: // STEP PILIH FOTO
        return _buildPilihFotoStep();
      case 1: // STEP UPLOADING
        return _buildUploadingStep();
      case 2: // STEP SUKSES
        return _buildSuksesStep();
      default:
        return _buildPilihFotoStep();
    }
  }

  Widget _buildPilihFotoStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pastikan foto wajah terlihat jelas dengan latar belakang putih',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Preview Foto
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
            ),
            child: _pickedImage != null
                ? ClipOval(
                    child: Image.file(
                      File(_pickedImage!.path),
                      width: 180,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada foto',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
          
          const SizedBox(height: 24),
          
          // Tombol Pilih Foto
          OutlinedButton.icon(
            onPressed: _showImageOptions,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.add_a_photo, color: Color(0xFF1E3A8A)),
            label: const Text(
              'Pilih atau Ambil Foto',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Panduan Singkat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Persyaratan Foto:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBulletPoint('Latar belakang putih polos'),
                _buildBulletPoint('Wajah terlihat jelas'),
                _buildBulletPoint('Tanpa aksesori (topi/kacamata hitam)'),
                _buildBulletPoint('Format JPG/PNG, maksimal 2MB'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF757575),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF424242),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Mengunggah Foto...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mohon tunggu sebentar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuksesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
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
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Foto Profil Berhasil Diperbarui!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Foto profil Anda telah berhasil diunggah',
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

  String _getButtonText() {
    switch (currentStep) {
      case 0:
        return _pickedImage != null ? 'Simpan Foto' : 'Pilih Foto';
      case 2:
        return 'Kembali ke Profil';
      default:
        return 'Lanjut';
    }
  }

  void _handleButtonPress() {
    if (currentStep == STEP_PILIH_FOTO) {
      if (_pickedImage != null) {
        // Langsung upload
        _uploadPhoto();
      } else {
        // Buka pilihan foto
        _showImageOptions();
      }
    } else if (currentStep == STEP_SUKSES) {
      Navigator.pop(context, true);
    }
  }
}