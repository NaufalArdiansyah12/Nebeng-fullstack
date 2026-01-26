import 'package:flutter/material.dart';

class BarangTransportationDialog extends StatelessWidget {
  final String? selectedTransportation;

  const BarangTransportationDialog({
    Key? key,
    this.selectedTransportation,
  }) : super(key: key);

  static Future<String?> show(BuildContext context,
      {String? currentSelection}) {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          BarangTransportationDialog(selectedTransportation: currentSelection),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Transportasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildTransportationOption(
              context: context,
              icon: Icons.train,
              label: 'Kereta',
              value: 'kereta',
            ),
            const SizedBox(height: 12),
            _buildTransportationOption(
              context: context,
              icon: Icons.flight,
              label: 'Pesawat',
              value: 'pesawat',
            ),
            const SizedBox(height: 12),
            _buildTransportationOption(
              context: context,
              icon: Icons.directions_bus,
              label: 'Bus',
              value: 'bus',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isSelected = selectedTransportation == value;
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E40AF).withOpacity(0.1) : null,
          border: Border.all(
            color: isSelected ? const Color(0xFF1E40AF) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1E40AF) : Colors.grey[600],
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF1E40AF) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
