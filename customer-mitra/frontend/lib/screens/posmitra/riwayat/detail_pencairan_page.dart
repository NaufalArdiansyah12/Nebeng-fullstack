import 'package:flutter/material.dart';
import '../saldo/withdrawal_progress_page.dart';
import '../saldo/withdrawal_success_page.dart';

class DetailPencairanPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const DetailPencairanPage({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  String _formatCurrency(double amount) {
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    final isProses = transaction['status'] == 'Proses';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pencairan',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Status Header
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isProses
                                ? const Color(0xFFFFF3CD)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isProses ? Icons.hourglass_empty : Icons.check_circle_outline,
                            color: isProses
                                ? const Color(0xFFFFC107)
                                : const Color(0xFF4CAF50),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isProses ? 'Pencairan Proses' : 'Pencairan Berhasil',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isProses
                                    ? 'Pengajuan sedang di proses'
                                    : 'Pengajuan selesai',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Detail Information
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Jumlah Tarik Saldo',
                          'Rp${_formatCurrency(transaction['amount'])}',
                          isLarge: true,
                        ),
                        const SizedBox(height: 20),
                        Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow('Nomor Transaksi', '00110'),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Tanggal',
                          'Senin, 21 Oktober 2024',
                        ),
                        if (!isProses) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Pencairan',
                            'Kamis, 24 Oktober 2024',
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildDetailRow('Waktu', '09:00 WIB'),
                        const SizedBox(height: 16),
                        _buildDetailRow('Pembayaran', 'Transfer Bank BRI'),
                        const SizedBox(height: 16),
                        _buildDetailRow('No Rekening', '1295192851925184*'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isProses) {
                    // Navigate to progress page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WithdrawalProgressPage(
                          amount: transaction['amount'].abs(),
                          status: 'pending',
                        ),
                      ),
                    );
                  } else {
                    // Navigate to success page to show receipt
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WithdrawalSuccessPage(
                          amount: transaction['amount'].abs(),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isProses ? 'Lihat Progres' : 'Lihat Bukti',
                  style: const TextStyle(
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
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 15 : 13,
            color: const Color(0xFF757575),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              color: const Color(0xFF212121),
              fontWeight: isLarge ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}