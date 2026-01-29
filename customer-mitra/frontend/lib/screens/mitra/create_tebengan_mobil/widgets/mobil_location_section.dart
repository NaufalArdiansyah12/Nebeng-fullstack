import 'package:flutter/material.dart';

class MobilLocationSection extends StatelessWidget {
  final String originLocationName;
  final String destinationLocationName;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;

  const MobilLocationSection({
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
        border: Border.all(
          color: Colors.black26,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildLocationItem(
            icon: Icons.trip_origin,
            iconColor: const Color(0xFF4CAF50),
            title: 'Lokasi Awal',
            subtitle: originLocationName.isNotEmpty ? originLocationName : null,
            onTap: onOriginTap,
          ),
          const SizedBox(height: 16),
          _buildLocationItem(
            icon: Icons.location_on,
            iconColor: const Color(0xFFFF9800),
            title: 'Lokasi Tujuan',
            subtitle: destinationLocationName.isNotEmpty
                ? destinationLocationName
                : null,
            onTap: onDestinationTap,
          ),
          const SizedBox(height: 20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon == Icons.arrow_upward
                        ? Icons.trip_origin
                        : Icons.location_on,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 56),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
