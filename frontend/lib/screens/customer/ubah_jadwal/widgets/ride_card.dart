import 'package:flutter/material.dart';
import '../ubah_jadwal_detail_page.dart';

class RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final Map<String, dynamic> booking;
  final DateTime selectedDate;

  const RideCard({
    Key? key,
    required this.ride,
    required this.booking,
    required this.selectedDate,
  }) : super(key: key);

  String _formatCardDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
    }
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}';
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp. 0';
    final numPrice = double.tryParse(price.toString()) ?? 0;
    final formatted = numPrice.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return 'Rp. $formatted';
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      return '${parts[0]}:${parts[1]}';
    } catch (e) {
      return time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final departureTime = ride['departure_time'] ?? '';
    final price = ride['price_per_seat'] ?? ride['price'] ?? 0;
    final availableSeats = ride['available_seats'] ?? 0;
    final departureDate = ride['departure_date'];

    // Get full location info
    String originCity = '';
    String originAddress = '';
    String destCity = '';
    String destAddress = '';

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      final locName = ride['origin_location']['name'] ?? '';
      final locAddress = ride['origin_location']['address'] ?? '';

      if (locName.contains(' - ')) {
        final parts = locName.split(' - ');
        originCity = parts[0];
        originAddress = parts.length > 1 ? parts[1] : locAddress;
      } else {
        originCity = locName;
        originAddress = locAddress;
      }
    }

    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      final locName = ride['destination_location']['name'] ?? '';
      final locAddress = ride['destination_location']['address'] ?? '';

      if (locName.contains(' - ')) {
        final parts = locName.split(' - ');
        destCity = parts[0];
        destAddress = parts.length > 1 ? parts[1] : locAddress;
      } else {
        destCity = locName;
        destAddress = locAddress;
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UbahJadwalDetailPage(
              booking: booking,
              selectedRide: ride,
              selectedDate: selectedDate,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Price Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCardDate(departureDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _formatPrice(price),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Origin
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'Y',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        originCity,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        originAddress,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vertical line
            Padding(
              padding: const EdgeInsets.only(left: 11, top: 4, bottom: 4),
              child: Container(
                width: 2,
                height: 16,
                color: Colors.grey[300],
              ),
            ),

            // Destination
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destCity,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        destAddress,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time
            Row(
              children: [
                Text(
                  _formatTime(departureTime),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bottom row: Available Seats and Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sisa $availableSeats Kursi',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UbahJadwalDetailPage(
                          booking: booking,
                          selectedRide: ride,
                          selectedDate: selectedDate,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Selengkapnya',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F4AA3),
                      fontWeight: FontWeight.w600,
                    ),
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
