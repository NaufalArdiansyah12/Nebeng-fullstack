import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class PenumpangTitipBarangSection extends StatelessWidget {
  final Map<String, dynamic> ride;

  const PenumpangTitipBarangSection({
    Key? key,
    required this.ride,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Pengiriman',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAllTitipBarangBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final bookings = snapshot.data ?? [];
            if (bookings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: const Text('Tidak ada data pengiriman'),
              );
            }

            return Column(
              children: bookings.asMap().entries.map((entry) {
                final index = entry.key;
                final booking = entry.value;
                return Container(
                  margin: EdgeInsets.only(
                      bottom: index < bookings.length - 1 ? 12 : 0),
                  child: _buildTitipBarangExpansionTile(booking, index),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getAllTitipBarangBookings() async {
    try {
      final rideIdInt = int.tryParse(ride['id'].toString()) ?? 0;
      if (rideIdInt == 0) return [];

      final bookings = await ApiService.getRidePassengers(rideIdInt, 'titip');
      return bookings;
    } catch (e) {
      print('Error fetching all titip barang bookings: $e');
      return [];
    }
  }

  Widget _buildTitipBarangExpansionTile(
      Map<String, dynamic> booking, int index) {
    final userMap = booking['user'] is Map
        ? Map<String, dynamic>.from(booking['user'] as Map)
        : <String, dynamic>{};
    final customerName = userMap['name'] ?? 'Pengirim ${index + 1}';
    final bookingNumber = booking['booking_number'] ?? '-';
    final weight = booking['weight']?.toString() ?? '-';

    // Parse penerima untuk nama
    String receiverName = '-';
    if (booking['penerima'] != null) {
      final p = booking['penerima'];
      if (p is String && p.isNotEmpty) {
        if (p.startsWith('{')) {
          try {
            final decoded = Map<String, dynamic>.from(jsonDecode(p) as Map);
            receiverName = decoded['name']?.toString() ?? '-';
          } catch (e) {
            // Failed to parse JSON
          }
        } else {
          final parts = p.split('|');
          receiverName = parts.isNotEmpty ? parts[0].trim() : '-';
        }
      } else if (p is Map) {
        receiverName = p['name']?.toString() ?? '-';
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.purple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard,
              color: Colors.purple[700],
              size: 24,
            ),
          ),
          title: Text(
            customerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Booking #${bookingNumber.split('-').last} • Penerima: $receiverName',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              weight,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTitipBarangDetails(booking),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitipBarangDetails(Map<String, dynamic> booking) {
    final userMap = booking['user'] is Map
        ? Map<String, dynamic>.from(booking['user'] as Map)
        : <String, dynamic>{};
    final customerName = userMap['name'] ?? '-';
    final customerPhone = userMap['phone'] ?? userMap['no_telepon'] ?? '';
    final meta = booking['meta'];
    final senderName = meta is Map
        ? (meta['sender_name']?.toString() ?? customerName)
        : customerName;
    final senderPhone = meta is Map
        ? (meta['sender_phone']?.toString() ?? customerPhone)
        : customerPhone;

    // Parse penerima
    String receiverName = '-';
    String receiverPhone = '';
    if (booking['penerima'] != null) {
      final p = booking['penerima'];
      if (p is String && p.isNotEmpty) {
        if (p.startsWith('{')) {
          try {
            final decoded = Map<String, dynamic>.from(jsonDecode(p) as Map);
            receiverName = decoded['name']?.toString() ?? '-';
            receiverPhone = decoded['phone']?.toString() ?? '';
          } catch (e) {
            // Failed to parse JSON
          }
        } else {
          final parts = p.split('|');
          receiverName = parts.isNotEmpty ? parts[0].trim() : '-';
          if (parts.length > 1) receiverPhone = parts[1].trim();
        }
      } else if (p is Map) {
        receiverName = p['name']?.toString() ?? '-';
        receiverPhone = p['phone']?.toString() ?? '';
      }
    }

    // Convert relative photo URL to absolute URL
    String photo = booking['photo']?.toString() ?? '';
    if (photo.isNotEmpty && !photo.startsWith('http')) {
      final baseUrl = ApiService.baseUrl;
      photo = photo.startsWith('/') ? '$baseUrl$photo' : '$baseUrl/$photo';
    }

    final weight = booking['weight']?.toString() ?? '-';
    final description = booking['description']?.toString() ?? '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sender info
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (senderPhone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      senderPhone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // Barang info
        Row(
          children: [
            Icon(Icons.inventory_2, size: 20, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Text(
              'Data Barang',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.scale, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatWeightLabel(weight),
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (photo.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              photo,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.image, size: 50, color: Colors.grey[400]),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        // Receiver info (without address)
        Row(
          children: [
            Icon(Icons.person_outline, size: 20, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              'Informasi Penerima',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nama :',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              receiverName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'No. Tlp :',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              receiverPhone.isNotEmpty ? receiverPhone : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
