import 'package:flutter/material.dart';
import 'verifikasi_type_page.dart';
import 'verifikasi_wajah_ktp_capture_page.dart';

class VerifikasiWajahKtpPanduanPage extends StatelessWidget {
  final VerificationType verificationType;

  const VerifikasiWajahKtpPanduanPage({
    Key? key,
    required this.verificationType,
  }) : super(key: key);

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
          'Ketentuan',
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
              // Instructions
              const Text(
                '• Sesuaikan posisi wajah dan KTP dalam bingkai yang tersedia agar memudahkan verifikasi',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Ambil foto ditempat yang terang',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Semua info dikartu harus jelas dan terbaca',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Pastikan hasil foto sesuai dengan contoh dibawah ini',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Example Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildExampleImage(
                    icon: Icons.person,
                    label: 'Benar',
                    isCorrect: true,
                  ),
                  _buildExampleImage(
                    icon: Icons.blur_on,
                    label: 'Blur',
                    isCorrect: false,
                  ),
                  _buildExampleImage(
                    icon: Icons.dark_mode,
                    label: 'Gelap',
                    isCorrect: false,
                  ),
                ],
              ),

              const Spacer(),

              // Mulai Foto Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerifikasiWajahKtpCapturePage(
                          verificationType: verificationType,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Foto',
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
      ),
    );
  }

  Widget _buildExampleImage({
    required IconData icon,
    required String label,
    required bool isCorrect,
  }) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.badge_outlined,
                size: 40,
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(height: 8),
              Icon(
                icon,
                size: 30,
                color: const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: isCorrect ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
