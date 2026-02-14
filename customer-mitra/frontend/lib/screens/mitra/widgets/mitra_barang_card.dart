import 'package:flutter/material.dart';
import '../../../services/shared/api_config.dart';

/// Widget to display item/package (barang) information for mitra
class MitraBarangCard extends StatelessWidget {
  final String? photoUrl;
  final String? weight;
  final String? description;

  const MitraBarangCard({
    Key? key,
    this.photoUrl,
    this.weight,
    this.description,
  }) : super(key: key);

  String _formatWeightLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'kecil') {
      return 'Kecil - Maksimal 5 Kg';
    }
    if (normalized == 'sedang') {
      return 'Sedang - Maksimal 10 Kg';
    }
    if (normalized == 'besar') {
      return 'Besar - Maksimal 20 Kg';
    }

    return value;
  }

  /// Convert relative path to full URL
  String? _getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;

    // If already a complete URL, return as-is
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // If path starts with /storage/, append to base URL
    if (path.startsWith('/storage/')) {
      return '${ApiConfig.baseUrl}$path';
    }

    // If path starts with storage/ (without leading slash)
    if (path.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$path';
    }

    // Default: treat as relative path from base URL
    return '${ApiConfig.baseUrl}/$path';
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = _getFullImageUrl(photoUrl);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Section
          if (fullImageUrl != null && fullImageUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fullImageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Foto tidak tersedia',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Weight Section
          if (weight != null && weight!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.scale, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berat Barang',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatWeightLabel(weight!),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Description Section
          if (description != null && description!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keterangan Barang',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Empty state if no data
          if ((fullImageUrl == null || fullImageUrl.isEmpty) &&
              (weight == null || weight!.isEmpty) &&
              (description == null || description!.isEmpty))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tidak ada informasi barang',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
