import 'package:flutter/material.dart';
import 'verifikasi_form_page.dart';
import 'verifikasi_capture_page.dart';
import 'verifikasi_type_page.dart';

class VerifikasiUploadPage extends StatefulWidget {
  final VerificationType verificationType;

  const VerifikasiUploadPage({
    Key? key,
    required this.verificationType,
  }) : super(key: key);

  @override
  State<VerifikasiUploadPage> createState() => _VerifikasiUploadPageState();
}

class _VerifikasiUploadPageState extends State<VerifikasiUploadPage> {
  bool _isLoading = false;

  String get _verificationTitle {
    switch (widget.verificationType) {
      case VerificationType.face:
        return 'Verifikasi Wajah';
      case VerificationType.ktp:
        return 'Verifikasi e-KTP';
      case VerificationType.faceKtp:
        return 'Verifikasi Wajah dan e-KTP';
    }
  }

  String get _documentType {
    switch (widget.verificationType) {
      case VerificationType.face:
        return 'Foto Wajah';
      case VerificationType.ktp:
        return 'e-KTP';
      case VerificationType.faceKtp:
        return 'Foto Wajah dengan e-KTP';
    }
  }

  List<String> get _requirements {
    switch (widget.verificationType) {
      case VerificationType.face:
        return [
          'Pastikan wajah terlihat jelas',
          'Gunakan pencahayaan yang cukup',
          'Tidak menggunakan aksesoris yang menutupi wajah',
          'Foto diambil dari jarak dekat',
        ];
      case VerificationType.ktp:
        return [
          'Pastikan seluruh bagian KTP terlihat jelas',
          'Foto tidak blur atau buram',
          'Informasi pada KTP dapat terbaca dengan jelas',
          'Tidak ada pantulan cahaya pada KTP',
        ];
      case VerificationType.faceKtp:
        return [
          'Wajah dan KTP terlihat jelas dalam satu frame',
          'Pastikan informasi pada KTP dapat terbaca',
          'Wajah tidak tertutup oleh KTP',
          'Gunakan pencahayaan yang baik',
        ];
    }
  }

  List<String> get _avoidList {
    switch (widget.verificationType) {
      case VerificationType.face:
        return [
          'Foto blur atau tidak fokus',
          'Wajah tertutup aksesoris',
          'Pencahayaan terlalu gelap',
          'Menggunakan filter atau edit foto',
        ];
      case VerificationType.ktp:
        return [
          'KTP tidak lengkap atau terpotong',
          'Foto terlalu gelap atau terang',
          'KTP rusak atau tidak terbaca',
          'Menggunakan fotocopy',
        ];
      case VerificationType.faceKtp:
        return [
          'Wajah atau KTP tidak terlihat jelas',
          'KTP menutupi wajah',
          'Foto terlalu jauh',
          'Pencahayaan tidak merata',
        ];
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
          _verificationTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Panduan Upload Dokumen',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sample document image
                  Center(
                    child: Container(
                      width: 200,
                      height: 250,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.verificationType == VerificationType.face
                            ? Icon(
                                Icons.face,
                                size: 100,
                                color: Colors.grey.shade400,
                              )
                            : widget.verificationType == VerificationType.ktp
                                ? Icon(
                                    Icons.credit_card,
                                    size: 100,
                                    color: Colors.grey.shade400,
                                  )
                                : Icon(
                                    Icons.how_to_reg,
                                    size: 100,
                                    color: Colors.grey.shade400,
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Sample Document',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Requirements section
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Persyaratan:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._requirements.map((req) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                req,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  // Things to avoid section
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cancel,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Yang harus dihindari:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._avoidList.map((avoid) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                avoid,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 40),
                  // Lanjut button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lanjut',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  void _handleNext() {
    if (widget.verificationType == VerificationType.face) {
      // For face verification, go directly to capture page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifikasiCapturePage(
            verificationType: widget.verificationType,
          ),
        ),
      );
    } else {
      // For KTP and Face+KTP, go to form page first
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerifikasiFormPage(
            verificationType: widget.verificationType,
          ),
        ),
      );
    }
  }
}
