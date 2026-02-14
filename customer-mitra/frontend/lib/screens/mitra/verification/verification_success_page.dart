import 'package:flutter/material.dart';
import '../main_page.dart';
import '../../customer/profile/profile_page.dart';

class VerificationSuccessPage extends StatelessWidget {
  const VerificationSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              /// ================= CONTENT =================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      /// Success Illustration
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF10B981).withOpacity(0.1),
                              const Color(0xFF059669).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(60),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        'Dokumen Berhasil Dikirim!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Terima kasih telah melengkapi dokumen verifikasi. Tim kami akan segera mereview dokumen Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF666666),
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 32),

                      /// Estimasi Review Box
                      _buildEstimateBox(),

                      const SizedBox(height: 24),

                      /// Next Step Box
                      _buildNextStepBox(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              /// ================= BUTTON SECTION =================
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MitraMainPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Kembali ke Beranda Mitra',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProfilePage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF1E40AF),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Profile',
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
            ],
          ),
        ),
      ),
    );
  }

  /// ================= COMPONENTS =================

  Widget _buildEstimateBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.schedule,
                  color: Color(0xFFF59E0B), size: 24),
              SizedBox(width: 12),
              Text(
                'Estimasi Review',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1 - 3 Hari Kerja',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  const Color(0xFFF59E0B).withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.notifications_active,
                  color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kami akan mengirimkan notifikasi jika dokumen sudah disetujui',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E40AF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Color(0xFF1E40AF), size: 20),
              SizedBox(width: 8),
              Text(
                'Langkah Selanjutnya:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _StepItem('Dokumen direview oleh tim kami'),
          _StepItem('Anda akan menerima notifikasi'),
          _StepItem(
              'Jika disetujui, Anda bisa mulai menerima orderan'),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String text;
  const _StepItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
