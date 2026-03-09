import 'package:flutter/material.dart';

class WithdrawalProgressPage extends StatelessWidget {
  final double amount;
  final String status;

  const WithdrawalProgressPage({
    Key? key,
    required this.amount,
    required this.status,
  }) : super(key: key);

  /// Daftar step beserta mapping status
  List<Map<String, String>> getSteps() {
    return [
      {'status': 'pending', 'title': 'Pengajuan Diajukan', 'subtitle': 'Sistem menerima pengajuan Anda.'},
      {'status': 'verifying', 'title': 'Pengajuan Diverifikasi', 'subtitle': 'Admin sedang memverifikasi pengajuan Anda.'},
      {'status': 'approved', 'title': 'Pengajuan Disetujui', 'subtitle': 'Pengajuan lolos verifikasi dan siap diproses.'},
      {'status': 'processing', 'title': 'Sedang Diproses', 'subtitle': 'Dana sedang diproses untuk dikirim ke rekening Anda.'},
      {'status': 'transferring', 'title': 'Dana Sedang Dikirim', 'subtitle': 'Dana sedang dikirim ke rekening Anda.'},
      {'status': 'completed', 'title': 'Pengajuan Selesai', 'subtitle': 'Dana telah diterima di rekening Anda.'},
      {'status': 'rejected', 'title': 'Pengajuan Ditolak', 'subtitle': 'Pengajuan ditolak. Silakan cek alasan di detail.'},
      {'status': 'refunded', 'title': 'Dana Dikembalikan', 'subtitle': 'Dana telah dikembalikan ke saldo Anda.'},
    ];
  }

  /// Mendapatkan index step saat ini
  int getCurrentStepIndex() {
    final steps = getSteps();
    final index = steps.indexWhere((step) => step['status'] == status);
    return index >= 0 ? index : 0;
  }

  /// Format currency Rp dengan titik ribuan
  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    final steps = getSteps();
    final currentStep = getCurrentStepIndex();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text(
          'Progres Tarik Saldo',
          style: TextStyle(color: Color(0xFF212121), fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline step
                  ...List.generate(steps.length, (index) {
                    final step = steps[index];
                    final isCompleted = index <= currentStep;
                    final isLast = index == steps.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            // Circle indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFF1E3A8A) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted ? const Color(0xFF1E3A8A) : const Color(0xFFE0E0E0),
                                  width: 2,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 60,
                                color: isCompleted ? const Color(0xFF1E3A8A) : const Color(0xFFE0E0E0),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Title & subtitle step
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step['title']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted ? const Color(0xFF212121) : const Color(0xFF9E9E9E),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step['subtitle']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted ? const Color(0xFF757575) : const Color(0xFFBDBDBD),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  // Detail Tarik Saldo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Tarik Saldo',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF212121)),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Total Dana', 'Rp ${_formatCurrency(amount)}'),
                        const SizedBox(height: 6),
                        _buildDetailRow('Status', status.toUpperCase(), isLarge: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tombol Kembali
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 15 : 13,
            color: const Color(0xFF424242),
            fontWeight: isLarge ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 15 : 13,
            color: const Color(0xFF424242),
            fontWeight: isLarge ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
