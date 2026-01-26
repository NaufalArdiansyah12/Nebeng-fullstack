import 'package:flutter/material.dart';
import '../utils/booking_formatters.dart';

/// Widget to display countdown to departure
class CountdownSection extends StatelessWidget {
  final String rawDate;
  final String rawTime;
  final Duration? timeUntilDeparture;

  const CountdownSection({
    Key? key,
    required this.rawDate,
    required this.rawTime,
    this.timeUntilDeparture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateOnly = BookingFormatters.formatDateOnly(rawDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Jadwal Berangkat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dateOnly Jam ${rawTime.substring(0, 5)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          if (timeUntilDeparture != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountdownBox(
                  timeUntilDeparture!.inDays.toString().padLeft(2, '0'),
                  'Hari',
                ),
                const SizedBox(width: 12),
                _buildCountdownBox(
                  (timeUntilDeparture!.inHours % 24).toString().padLeft(2, '0'),
                  'Jam',
                ),
                const SizedBox(width: 12),
                _buildCountdownBox(
                  (timeUntilDeparture!.inMinutes % 60)
                      .toString()
                      .padLeft(2, '0'),
                  'Menit',
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Waktu keberangkatan telah tiba',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
