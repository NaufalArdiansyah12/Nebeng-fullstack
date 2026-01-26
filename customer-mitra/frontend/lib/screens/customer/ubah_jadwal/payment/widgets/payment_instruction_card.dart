import 'package:flutter/material.dart';

class PaymentInstructionCard extends StatelessWidget {
  final String bankCode;
  final String virtualAccount;

  const PaymentInstructionCard({
    Key? key,
    required this.bankCode,
    required this.virtualAccount,
  }) : super(key: key);

  String _getBankName(String code) {
    final bankNames = {
      'bri': 'BRI',
      'bca': 'BCA',
      'bni': 'BNI',
      'mandiri': 'Mandiri',
      'permata': 'Permata',
    };
    return bankNames[code.toLowerCase()] ?? code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cara Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Transfer ke Virtual Account ${_getBankName(bankCode)} di atas dengan nominal yang tertera.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setelah transfer, tekan tombol "Saya sudah bayar" untuk menyelesaikan perubahan jadwal.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
