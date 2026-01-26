import 'package:flutter/material.dart';

/// Widget to display driver information
class DriverInfoCard extends StatelessWidget {
  final String driverName;
  final String driverPhoto;
  final String plateNumber;
  final Color accentColor;
  final VoidCallback? onCallPressed;
  final VoidCallback? onChatPressed;

  const DriverInfoCard({
    Key? key,
    required this.driverName,
    required this.driverPhoto,
    required this.plateNumber,
    required this.accentColor,
    this.onCallPressed,
    this.onChatPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  driverPhoto.isNotEmpty ? NetworkImage(driverPhoto) : null,
              child: driverPhoto.isEmpty
                  ? Icon(Icons.person, color: Colors.grey[600], size: 28)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '5.0',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      plateNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildActionButton(Icons.phone, accentColor, onCallPressed),
          const SizedBox(width: 10),
          _buildActionButton(
              Icons.chat_bubble_outline, accentColor, onChatPressed),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback? onPressed) {
    return InkWell(
      onTap: onPressed ?? () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
