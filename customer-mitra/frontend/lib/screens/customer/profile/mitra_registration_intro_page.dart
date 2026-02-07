import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../mitra/verification/verification_documents_page.dart';
import '../../../services/shared/verification_service.dart';

class MitraRegistrationIntroPage extends StatefulWidget {
  const MitraRegistrationIntroPage({Key? key}) : super(key: key);

  @override
  State<MitraRegistrationIntroPage> createState() =>
      _MitraRegistrationIntroPageState();
}

class _MitraRegistrationIntroPageState
    extends State<MitraRegistrationIntroPage> {
  bool _isCheckingStatus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Bergabung Jadi Mitra',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dapatkan penghasilan tambahan dengan berbagi perjalanan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E40AF).withOpacity(0.1),
                      const Color(0xFF10B981).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      size: 80,
                      color: const Color(0xFF1E40AF),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.money_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Benefits
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Keuntungan Menjadi Mitra:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitItem(
                        icon: Icons.schedule,
                        iconColor: const Color(0xFF1E40AF),
                        title: 'Jadwal Fleksibel',
                        description:
                            'Tentukan jadwal kerja sesuai waktu luangmu',
                      ),
                      _buildBenefitItem(
                        icon: Icons.payments_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'Penghasilan Tambahan',
                        description:
                            'Dapatkan uang dari setiap perjalanan yang kamu lakukan',
                      ),
                      _buildBenefitItem(
                        icon: Icons.security,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Asuransi Perjalanan',
                        description:
                            'Terlindungi dengan asuransi selama menjalankan layanan',
                      ),
                      _buildBenefitItem(
                        icon: Icons.support_agent,
                        iconColor: const Color(0xFFEF4444),
                        title: 'Dukungan 24/7',
                        description: 'Tim support siap membantu kapan saja',
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Syarat Menjadi Mitra:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRequirementItem(
                                'Memiliki kendaraan pribadi (motor/mobil)'),
                            _buildRequirementItem('KTP yang masih berlaku'),
                            _buildRequirementItem(
                                'SIM yang sesuai dengan kendaraan'),
                            _buildRequirementItem('STNK kendaraan'),
                            _buildRequirementItem('Rekening bank aktif'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Mulai Daftar button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isCheckingStatus ? null : _handleStartRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor:
                        const Color(0xFF1E40AF).withOpacity(0.5),
                  ),
                  child: _isCheckingStatus
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Mulai Daftar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // Kembali button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: Color(0xFF1E40AF), width: 1.5),
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
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartRegistration() async {
    setState(() => _isCheckingStatus = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        _showErrorDialog('Sesi Anda telah berakhir. Silakan login kembali.');
        return;
      }

      // Check verification status
      final statusResp =
          await VerificationService.getMitraVerificationStatus(token);

      if (!mounted) return;

      if (statusResp['success'] == true) {
        final status = statusResp['status'] ?? 'not_submitted';

        if (status == 'approved') {
          // Already approved as mitra
          _showStatusDialog(
            title: 'Sudah Menjadi Mitra',
            message: 'Anda sudah terdaftar sebagai mitra dan telah disetujui!',
            icon: Icons.check_circle,
            iconColor: const Color(0xFF10B981),
            buttonText: 'OK',
          );
        } else if (status == 'pending') {
          // Verification is pending
          _showStatusDialog(
            title: 'Sedang Direview',
            message:
                'Dokumen verifikasi Anda sedang dalam proses review oleh tim kami. Mohon tunggu notifikasi lebih lanjut.',
            icon: Icons.pending,
            iconColor: const Color(0xFFF59E0B),
            buttonText: 'Mengerti',
          );
        } else if (status == 'rejected') {
          // Rejected - can resubmit
          _showStatusDialog(
            title: 'Verifikasi Ditolak',
            message:
                'Maaf, verifikasi Anda ditolak. Anda bisa melengkapi dokumen kembali.',
            icon: Icons.cancel,
            iconColor: const Color(0xFFEF4444),
            buttonText: 'Lengkapi Ulang',
            onConfirm: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VerificationDocumentsPage(),
                ),
              );
            },
          );
        } else {
          // Not submitted yet - proceed to verification
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VerificationDocumentsPage(),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      // If no verification found, proceed to verification page
      if (e.toString().contains('not_submitted') ||
          e.toString().contains('Belum ada verifikasi')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificationDocumentsPage(),
          ),
        );
      } else {
        _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onConfirm ?? () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
