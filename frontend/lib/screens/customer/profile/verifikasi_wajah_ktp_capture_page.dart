import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verifikasi_type_page.dart';
import 'verifikasi_success_page.dart';
import '../../../services/verifikasi_service.dart';
import '../../../models/verifikasi_model.dart';

class VerifikasiWajahKtpCapturePage extends StatefulWidget {
  final VerificationType verificationType;

  const VerifikasiWajahKtpCapturePage({
    Key? key,
    required this.verificationType,
  }) : super(key: key);

  @override
  State<VerifikasiWajahKtpCapturePage> createState() =>
      _VerifikasiWajahKtpCapturePageState();
}

class _VerifikasiWajahKtpCapturePageState
    extends State<VerifikasiWajahKtpCapturePage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;
  bool _isLoadingData = true;
  VerifikasiCustomer? _verifikasiData;

  @override
  void initState() {
    super.initState();
    _loadVerificationData();
  }

  Future<void> _loadVerificationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null) {
        final data = await VerifikasiService.getVerification(token);
        setState(() {
          _verifikasiData = data;
          _isLoadingData = false;
        });
      } else {
        throw Exception('Token tidak ditemukan');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verifikasi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Posisikan foto wajah dan\ne-ktp Anda di dalam bingkai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Preview or Frame
                    Expanded(
                      child: Center(
                        child: _imageFile == null
                            ? Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      const Color(0xFF1E40AF).withOpacity(0.1),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 120,
                                      color: const Color(0xFF1E40AF)
                                          .withOpacity(0.3),
                                    ),
                                    Positioned(
                                      bottom: 60,
                                      right: 40,
                                      child: Icon(
                                        Icons.credit_card,
                                        size: 60,
                                        color: const Color(0xFF1E40AF)
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _imageFile!,
                                  width: 300,
                                  height: 400,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Action Buttons
                    if (_imageFile == null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _showImageSourceBottomSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Ambil Foto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitPhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E40AF),
                                disabledBackgroundColor:
                                    const Color(0xFF9CA3AF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Berikutnya',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _retakePhoto,
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Color(0xFF1E40AF)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Kembali',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E40AF),
                                ),
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
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF1E40AF)),
              ),
              title: const Text(
                'Ambil Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.photo_library, color: Color(0xFF1E40AF)),
              ),
              title: const Text(
                'Pilih dari Galeri',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        Navigator.pop(context); // Close bottom sheet
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _submitPhoto() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ambil foto terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_verifikasiData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Data verifikasi tidak ditemukan. Silakan verifikasi KTP terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Use data from existing KTP verification
      final namaLengkap = _verifikasiData!.namaLengkap ?? '';
      final nik = _verifikasiData!.nik ?? '';
      final tanggalLahir = _verifikasiData!.tanggalLahir ?? '';
      final alamat = _verifikasiData!.alamat ?? 'Alamat sesuai KTP';

      await VerifikasiService.uploadFaceKtpPhoto(
        token: token,
        photo: _imageFile!,
        namaLengkap: namaLengkap,
        nik: nik,
        tanggalLahir: tanggalLahir,
        alamat: alamat,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifikasiSuccessPage(
              verificationType: widget.verificationType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload foto: $e'),
            backgroundColor: Colors.red,
          ),
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
}
