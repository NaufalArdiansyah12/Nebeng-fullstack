import 'package:flutter/material.dart';

class WithdrawalSuccessPage extends StatelessWidget {
  final double amount;

  const WithdrawalSuccessPage({
    Key? key,
    required this.amount,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Title
                      const Text(
                        'Penarikan Saldo Berhasil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Details Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Tanggal', '24 Okt 2024 | 09:00 WIB'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Nomor Transaksi', '353543634'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Penerima', 'Farras'),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                                'Jenis Transaksi', 'Transfer Bank BRI'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Sumber Dana', 'Maben'),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                                '', '3234 5638 6466 667', isSubValue: true),
                            const SizedBox(height: 16),
                            _buildDetailRow('Nominal', 'Rp. ${_formatCurrency(amount)}'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Biaya Admin', 'Rp. 0'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Success Message
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Selamat penarikan saldo Anda telah diterima. Silahkan periksa rekening bank Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Kembali Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isSubValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w400,
            ),
          )
        else
          const SizedBox(),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: isSubValue ? const Color(0xFF757575) : const Color(0xFF212121),
              fontWeight: isSubValue ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}