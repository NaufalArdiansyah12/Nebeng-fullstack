import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/verifikasi_service.dart';
import 'verifikasi_success_page.dart';
import 'verifikasi_type_page.dart';

class VerifikasiCapturePage extends StatefulWidget {
  final VerificationType verificationType;
  final String? namaLengkap;
  final String? nik;
  final String? tanggalLahir;
  final String? alamat;

  const VerifikasiCapturePage({
    Key? key,
    required this.verificationType,
    this.namaLengkap,
    this.nik,
    this.tanggalLahir,
    this.alamat,
  }) : super(key: key);

  @override
  State<VerifikasiCapturePage> createState() => _VerifikasiCapturePageState();
}

class _VerifikasiCapturePageState extends State<VerifikasiCapturePage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isLoading = false;

  String get _title {
    switch (widget.verificationType) {
      case VerificationType.face:
        return 'Ambil Foto Wajah';
      case VerificationType.ktp:
        return 'Ambil Foto KTP';
      case VerificationType.faceKtp:
        return 'Ambil Foto Wajah & KTP';
    }
  }

  String get _instruction {
    switch (widget.verificationType) {
      case VerificationType.face:
        return 'Posisikan wajah Anda di dalam bingkai.\nPastikan pencahayaan cukup dan wajah terlihat jelas.';
      case VerificationType.ktp:
        return 'Posisikan KTP Anda di dalam bingkai.\nPastikan seluruh bagian KTP terlihat jelas.';
      case VerificationType.faceKtp:
        return 'Posisikan wajah dan KTP Anda di dalam bingkai.\nPastikan keduanya terlihat jelas.';
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
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Instruction text
                  Text(
                    _instruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Preview or placeholder
                  Expanded(
                    child: Center(
                      child: _imageFile != null
                          ? Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  width: 300,
                                  height: 400,
                                ),
                              ),
                            )
                          : Container(
                              width: 300,
                              height: 400,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF1E40AF),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    widget.verificationType ==
                                            VerificationType.face
                                        ? Icons.face
                                        : widget.verificationType ==
                                                VerificationType.ktp
                                            ? Icons.credit_card
                                            : Icons.how_to_reg,
                                    size: 80,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Belum ada foto',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Action buttons
                  if (_imageFile != null)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _imageFile = null;
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Ambil Ulang'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E40AF),
                              side: const BorderSide(color: Color(0xFF1E40AF)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _uploadPhoto,
                            icon: const Icon(Icons.check),
                            label: const Text('Gunakan Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Ambil Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pilih dari Galeri'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E40AF),
                              side: const BorderSide(color: Color(0xFF1E40AF)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan ambil foto terlebih dahulu'),
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

      Map<String, dynamic> response;

      switch (widget.verificationType) {
        case VerificationType.face:
          response = await VerifikasiService.uploadFacePhoto(
            token: token,
            photo: _imageFile!,
          );
          break;
        case VerificationType.ktp:
          response = await VerifikasiService.uploadKtpPhoto(
            token: token,
            photo: _imageFile!,
            namaLengkap: widget.namaLengkap!,
            nik: widget.nik!,
            tanggalLahir: widget.tanggalLahir!,
            alamat: widget.alamat!,
          );
          break;
        case VerificationType.faceKtp:
          response = await VerifikasiService.uploadFaceKtpPhoto(
            token: token,
            photo: _imageFile!,
            namaLengkap: widget.namaLengkap!,
            nik: widget.nik!,
            tanggalLahir: widget.tanggalLahir!,
            alamat: widget.alamat!,
          );
          break;
      }

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
