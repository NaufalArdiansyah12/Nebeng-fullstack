import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  final String originLocationName;
  final String destinationLocationName;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;

  const LocationSection({
    Key? key,
    required this.originLocationName,
    required this.destinationLocationName,
    required this.onOriginTap,
    required this.onDestinationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLocationItem(
            icon: Icons.arrow_upward,
            iconColor: const Color(0xFF4CAF50),
            title: 'Lokasi Awal',
            subtitle: originLocationName.isNotEmpty ? originLocationName : null,
            onTap: onOriginTap,
          ),
          // Garis pemisah horizontal dan vertikal
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 36),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: const Color(0xFFFF9800),
            title: 'Lokasi Tujuan',
            subtitle: destinationLocationName.isNotEmpty
                ? destinationLocationName
                : null,
            onTap: onDestinationTap,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
