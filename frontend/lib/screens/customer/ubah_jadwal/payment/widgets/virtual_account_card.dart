import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VirtualAccountCard extends StatelessWidget {
  final String bankCode;
  final String virtualAccount;

  const VirtualAccountCard({
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

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: virtualAccount));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nomor VA berhasil disalin'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4AA3),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4AA3).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Virtual Account ${_getBankName(bankCode)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  virtualAccount,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _copyToClipboard(context),
                tooltip: 'Salin',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
