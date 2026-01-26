import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'verifikasi_upload_page.dart';
import 'verifikasi_form_page.dart';
import 'verifikasi_wajah_ktp_panduan_page.dart';
import '../../../services/verifikasi_service.dart';

enum VerificationType {
  face,
  ktp,
  faceKtp,
}

class VerifikasiTypePage extends StatefulWidget {
  const VerifikasiTypePage({Key? key}) : super(key: key);

  @override
  State<VerifikasiTypePage> createState() => _VerifikasiTypePageState();
}

class _VerifikasiTypePageState extends State<VerifikasiTypePage> {
  VerificationType? _selectedType;
  bool _isLoadingStatus = true;
  bool _hasFaceVerification = false;
  bool _hasKtpVerification = false;
  bool _hasFaceKtpVerification = false;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null) {
        final data = await VerifikasiService.getVerification(token);

        setState(() {
          // Check which photos are uploaded
          _hasFaceVerification =
              data.photoWajah != null && data.photoWajah!.isNotEmpty;
          _hasKtpVerification =
              data.photoKtp != null && data.photoKtp!.isNotEmpty;
          _hasFaceKtpVerification =
              data.photoKtpWajah != null && data.photoKtpWajah!.isNotEmpty;
          _isLoadingStatus = false;
        });
      } else {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStatus = false;
      });
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
      body: _isLoadingStatus
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verifikasi Identitas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lengkapi langkah-langkah berikut ini',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Verifikasi wajah option
                    _buildVerificationOption(
                      type: VerificationType.face,
                      icon: Icons.face,
                      title: 'Verifikasi wajah',
                      isSelected: _selectedType == VerificationType.face,
                      isCompleted: _hasFaceVerification,
                    ),
                    const SizedBox(height: 16),
                    // Verifikasi e-KTP option
                    _buildVerificationOption(
                      type: VerificationType.ktp,
                      icon: Icons.credit_card,
                      title: 'Verifikasi e-ktp',
                      isSelected: _selectedType == VerificationType.ktp,
                      isCompleted: _hasKtpVerification,
                    ),
                    const SizedBox(height: 16),
                    // Verifikasi wajah dan e-KTP option
                    _buildVerificationOption(
                      type: VerificationType.faceKtp,
                      icon: Icons.how_to_reg,
                      title: 'Verifikasi wajah dan e-ktp',
                      isSelected: _selectedType == VerificationType.faceKtp,
                      isCompleted: _hasFaceKtpVerification,
                    ),
                    const Spacer(),
                    // Lanjut button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedType != null
                            ? () {
                                if (_selectedType == VerificationType.face) {
                                  // For face verification, go to upload page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VerifikasiUploadPage(
                                        verificationType: _selectedType!,
                                      ),
                                    ),
                                  );
                                } else if (_selectedType ==
                                    VerificationType.ktp) {
                                  // For KTP verification, go to form page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VerifikasiFormPage(
                                        verificationType: _selectedType!,
                                      ),
                                    ),
                                  );
                                } else {
                                  // For Face+KTP verification, go directly to panduan (data already exists from KTP verification)
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VerifikasiWajahKtpPanduanPage(
                                        verificationType: _selectedType!,
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Lanjut',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedType != null
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVerificationOption({
    required VerificationType type,
    required IconData icon,
    required String title,
    required bool isSelected,
    required bool isCompleted,
  }) {
    // Determine colors based on completion status
    final backgroundColor =
        isCompleted ? const Color(0xFF1E40AF) : Colors.white;
    final borderColor = isCompleted || isSelected
        ? const Color(0xFF1E40AF)
        : const Color(0xFFE5E7EB);
    final iconBackgroundColor = isCompleted
        ? Colors.white.withOpacity(0.2)
        : isSelected
            ? const Color(0xFF1E40AF).withOpacity(0.1)
            : const Color(0xFFF3F4F6);
    final iconColor = isCompleted
        ? Colors.white
        : isSelected
            ? const Color(0xFF1E40AF)
            : const Color(0xFF6B7280);
    final textColor = isCompleted
        ? Colors.white
        : isSelected
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: isCompleted
          ? null
          : () {
              setState(() {
                _selectedType = type;
              });
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isCompleted || isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isCompleted || isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCompleted || isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (isCompleted)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF1E40AF),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
