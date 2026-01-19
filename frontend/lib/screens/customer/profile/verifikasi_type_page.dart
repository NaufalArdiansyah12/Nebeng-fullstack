import 'package:flutter/material.dart';
import 'verifikasi_upload_page.dart';

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
      body: SafeArea(
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
              ),
              const SizedBox(height: 16),
              // Verifikasi e-KTP option
              _buildVerificationOption(
                type: VerificationType.ktp,
                icon: Icons.credit_card,
                title: 'Verifikasi e-ktp',
                isSelected: _selectedType == VerificationType.ktp,
              ),
              const SizedBox(height: 16),
              // Verifikasi wajah dan e-KTP option
              _buildVerificationOption(
                type: VerificationType.faceKtp,
                icon: Icons.how_to_reg,
                title: 'Verifikasi wajah dan e-ktp',
                isSelected: _selectedType == VerificationType.faceKtp,
              ),
              const Spacer(),
              // Lanjut button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedType != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerifikasiUploadPage(
                                verificationType: _selectedType!,
                              ),
                            ),
                          );
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
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1E40AF) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
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
                color: isSelected
                    ? const Color(0xFF1E40AF).withOpacity(0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF1E40AF)
                    : const Color(0xFF6B7280),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFF4B5563),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1E40AF),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
