import 'package:flutter/material.dart';

/// Widget to display service type badge for motor rides
class ServiceTypeBadge extends StatelessWidget {
  final String? serviceType;
  final Color accentColor;

  const ServiceTypeBadge({
    Key? key,
    this.serviceType,
    required this.accentColor,
  }) : super(key: key);

  String _getServiceTypeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'tebengan':
        return 'Hanya Penumpang';
      case 'barang':
        return 'Hanya Titip Barang';
      case 'both':
        return 'Penumpang & Titip Barang';
      default:
        return 'Tidak diketahui';
    }
  }

  IconData _getServiceTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'tebengan':
        return Icons.person;
      case 'barang':
        return Icons.inventory_2;
      case 'both':
        return Icons.people_alt;
      default:
        return Icons.info_outline;
    }
  }

  Color _getServiceTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'tebengan':
        return const Color(0xFF10B981); // Green
      case 'barang':
        return const Color(0xFFF59E0B); // Orange
      case 'both':
        return const Color(0xFF3B82F6); // Blue
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (serviceType == null || serviceType!.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = _getServiceTypeLabel(serviceType);
    final icon = _getServiceTypeIcon(serviceType);
    final color = _getServiceTypeColor(serviceType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jenis Tebengan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              serviceType!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
