import 'package:flutter/material.dart';
import '../../nebeng_motor/utils/theme.dart';

class UkuranPicker {
  static Future<void> show(
      BuildContext context, ValueChanged<String?> onSelect) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pilih Kapasitas Bagasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildOption(
                      context,
                      title: 'Kecil',
                      subtitle: 'Maksimal 5 Kg',
                      onTap: () {
                        onSelect('Kecil');
                        Navigator.pop(context);
                      },
                    ),
                    _buildOption(
                      context,
                      title: 'Sedang',
                      subtitle: 'Maksimal 10 Kg',
                      onTap: () {
                        onSelect('Sedang');
                        Navigator.pop(context);
                      },
                    ),
                    _buildOption(
                      context,
                      title: 'Besar',
                      subtitle: 'Maksimal 20 Kg',
                      onTap: () {
                        onSelect('Besar');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildOption(BuildContext context,
      {required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: NebengMotorTheme.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.card_travel,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
