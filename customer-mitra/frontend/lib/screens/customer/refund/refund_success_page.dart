import 'package:flutter/material.dart';
import 'refund_landing_page.dart';

class RefundSuccessPage extends StatelessWidget {
  final double refundAmount;

  const RefundSuccessPage({Key? key, required this.refundAmount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF0F4AA3),
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Pengajuan Refund Berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Date
              const Text(
                'Tanggal',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '21 Okt 2024 | 09:00 WIB',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Transaction ID
              const Text(
                'ID Transaksi',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '3535436364',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Divider
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 32),

              // Receiver Info
              _buildInfoRow('Penerima', 'Ailsya Nasywa'),
              const SizedBox(height: 16),
              _buildInfoRow('Jenis Transaksi', 'Transfer Bank BRI'),
              const SizedBox(height: 32),

              // Divider
              Container(
                height: 1,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 32),

              // Amount Info
              _buildInfoRow('Sumber Dana', 'Mahen'),
              const SizedBox(height: 12),
              _buildInfoRow('Nominal', 'Rp. 110.000'),
              const SizedBox(height: 12),
              _buildInfoRow('Biaya Admin', 'Rp. 0'),
              const SizedBox(height: 32),

              // Message
              const Text(
                'Selamat refund Anda telah diterima.\nSilahkan periksa rekening\nBank Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to RefundLandingPage with History tab selected
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const RefundLandingPage(initialTab: 1),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4AA3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Lihat Riwayat Refund',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
