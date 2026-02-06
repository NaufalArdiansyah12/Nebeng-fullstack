import 'package:flutter/material.dart';
import 'dart:async';
import 'withdrawal_success_page.dart';

class WithdrawalProgressPage extends StatefulWidget {
  final double amount;

  const WithdrawalProgressPage({
    Key? key,
    required this.amount,
  }) : super(key: key);

  @override
  State<WithdrawalProgressPage> createState() => _WithdrawalProgressPageState();
}

class _WithdrawalProgressPageState extends State<WithdrawalProgressPage> {
  int currentStep = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> steps = [
    {
      'title': 'Pengajuan Telah Diajukan - Senin, 21 Okt',
      'subtitle':
          'Sistem Berhasil menerima Pengajuan Anda di hari Senin, 21 Okt di jam 09:00 WIB.',
      'time': '09:00 WIB',
    },
    {
      'title': 'Memverifikasi Pengajuan Anda - Selasa, 22 Okt',
      'subtitle':
          'Syifa A: Admin sedang memverifikasikan yang telah Anda Kirimkan.',
      'time': '',
    },
    {
      'title': 'Pengajuan Disetujui - Rabu, 23 Okt',
      'subtitle':
          'Permintaan Anda telah lolos verifikasi oleh Syifa dan segera ditransfer ke rekening Anda yang terdaftar.',
      'time': '',
    },
    {
      'title': 'Pengajuan Sedang Dikirim - Kamis, 24 Okt',
      'subtitle':
          'Dana sedang dikirim menuju rekening anda dan segera sampai.',
      'time': '',
    },
    {
      'title': 'Pengajuan Telah DiTransfer - Kamis, 24 Okt',
      'subtitle':
          'Dana telah tiba di rekening Anda. Silahkan cek history transfer di mobile banking Anda. Terima kasih.',
      'time': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto progress through steps
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (currentStep < steps.length - 1) {
        setState(() {
          currentStep++;
        });
      } else {
        timer.cancel();
        // Navigate to success page after last step
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    WithdrawalSuccessPage(amount: widget.amount),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
        title: const Text(
          'Progres Tarik Saldo',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline
                  ...List.generate(steps.length, (index) {
                    final step = steps[index];
                    final isCompleted = index <= currentStep;
                    final isLast = index == steps.length - 1;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline indicator
                        Column(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted
                                      ? const Color(0xFF1E3A8A)
                                      : const Color(0xFFE0E0E0),
                                  width: 2,
                                ),
                              ),
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 60,
                                color: isCompleted
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFE0E0E0),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        step['title'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isCompleted
                                              ? const Color(0xFF212121)
                                              : const Color(0xFF9E9E9E),
                                        ),
                                      ),
                                    ),
                                    if (step['time'].isNotEmpty)
                                      Text(
                                        step['time'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isCompleted
                                              ? const Color(0xFF757575)
                                              : const Color(0xFF9E9E9E),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  step['subtitle'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCompleted
                                        ? const Color(0xFF757575)
                                        : const Color(0xFFBDBDBD),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Rincian Dana Saldo', ''),
                        const SizedBox(height: 8),
                        _buildDetailRow('Total Dana Asli',
                            'Rp${_formatCurrency(widget.amount)}'),
                        const SizedBox(height: 16),
                        _buildDetailRow('Estimasi Tarik Saldo', ''),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                            'Rp${_formatCurrency(widget.amount)}', '',
                            isLarge: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF1E3A8A),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Durasi Proses Refund',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w500,
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
          // Buttons
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
            child: Column(
              children: [
                if (currentStep < steps.length - 1)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Lihat Bukti Status
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: Color(0xFF1E3A8A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Bukti Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ),
                if (currentStep < steps.length - 1) const SizedBox(height: 12),
                SizedBox(
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
              ],
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
        if (value.isNotEmpty)
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