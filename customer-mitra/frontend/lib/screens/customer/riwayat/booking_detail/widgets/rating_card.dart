import 'package:flutter/material.dart';

class RatingCard extends StatelessWidget {
  final Map<String, dynamic>? existingRating;
  final VoidCallback onRatePressed;
  final String driverName;

  const RatingCard({
    Key? key,
    this.existingRating,
    required this.onRatePressed,
    required this.driverName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasRating = existingRating != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasRating
                      ? Colors.amber.withOpacity(0.1)
                      : const Color(0xFF0F4AA3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: hasRating ? Colors.amber : const Color(0xFF0F4AA3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRating ? 'Rating Anda' : 'Beri Rating',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRating
                          ? 'Terima kasih atas penilaian Anda'
                          : 'Bagaimana pengalaman perjalanan Anda?',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasRating) ...[
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 20),

            // Display Rating
            Row(
              children: [
                Text(
                  'Rating untuk $driverName',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stars Display
            Row(
              children: [
                ...List.generate(5, (index) {
                  final starValue = index + 1;
                  final rating = existingRating!['rating'] ?? 0;
                  return Icon(
                    starValue <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color:
                        starValue <= rating ? Colors.amber : Colors.grey[300],
                    size: 28,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '${existingRating!['rating'] ?? 0}.0',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Review Text
            if (existingRating!['review'] != null &&
                existingRating!['review'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ulasan Anda',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      existingRating!['review'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Date
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(existingRating!['created_at'] ?? ''),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 20),

            // Button to Rate
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRatePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4AA3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.star_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Beri Rating Driver',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
