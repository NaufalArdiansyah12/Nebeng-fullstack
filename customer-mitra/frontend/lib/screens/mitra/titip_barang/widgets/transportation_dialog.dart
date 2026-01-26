import 'package:flutter/material.dart';

class TransportationDialog extends StatelessWidget {
  final String? selectedTransportation;

  const TransportationDialog({
    Key? key,
    this.selectedTransportation,
  }) : super(key: key);

  static Future<String?> show(BuildContext context,
      {String? currentSelection}) {
    return showDialog<String?>(
      context: context,
      builder: (context) => TransportationDialog(
        selectedTransportation: currentSelection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih transportasi yang akan digunakan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            _buildTransportationOption(
              context,
              'Kereta',
              Icons.train,
              'kereta',
            ),
            const SizedBox(height: 12),
            _buildTransportationOption(
              context,
              'Pesawat',
              Icons.flight,
              'pesawat',
            ),
            const SizedBox(height: 12),
            _buildTransportationOption(
              context,
              'Bus',
              Icons.directions_bus,
              'bus',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationOption(
      BuildContext context, String label, IconData icon, String value) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10367d),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
