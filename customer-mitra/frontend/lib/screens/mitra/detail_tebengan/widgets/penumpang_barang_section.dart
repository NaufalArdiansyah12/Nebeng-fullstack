import 'package:flutter/material.dart';
import '../services/booking_data_service.dart';
import '../../../../services/api_service.dart';

class PenumpangBarangSection extends StatelessWidget {
  final Map<String, dynamic> ride;

  const PenumpangBarangSection({
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
    // Check vehicle type from kendaraan_mitra
    final kendaraanMitra = ride['kendaraan_mitra'] is Map
        ? Map<String, dynamic>.from(ride['kendaraan_mitra'] as Map)
        : <String, dynamic>{};
    final vehicleType =
        (kendaraanMitra['type'] ?? kendaraanMitra['vehicle_type'] ?? '')
            .toString()
            .toLowerCase();

    // Determine if motor or mobil
    final isMotor = vehicleType.contains('motor');
    final isMobil =
        vehicleType.contains('mobil') || vehicleType.contains('car');

    if (isMotor) {
      return _buildMotorBarangView();
    } else if (isMobil) {
      return _buildMobilBarangView();
    } else {
      // Default to motor view
      return _buildMotorBarangView();
    }
  }

  // Motor view - single barang display
  Widget _buildMotorBarangView() {
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
        FutureBuilder<Map<String, dynamic>?>(
          future: BookingDataService.getBarangBooking(ride['id']),
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

            final booking = snapshot.data;
            if (booking == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: const Text('Tidak ada data barang'),
              );
            }

            return _buildBarangCard(booking);
          },
        ),
      ],
    );
  }

  // Mobil view - multiple barang with dropdown
  Widget _buildMobilBarangView() {
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
          future: _getAllBarangBookings(),
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
                child: const Text('Tidak ada data barang'),
              );
            }

            return Column(
              children: bookings.asMap().entries.map((entry) {
                final index = entry.key;
                final booking = entry.value;
                return Container(
                  margin: EdgeInsets.only(
                      bottom: index < bookings.length - 1 ? 12 : 0),
                  child: _buildBarangExpansionTile(booking, index),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _getAllBarangBookings() async {
    try {
      final rideIdInt = int.tryParse(ride['id'].toString()) ?? 0;
      if (rideIdInt == 0) return [];

      final bookings = await ApiService.getRidePassengers(rideIdInt, 'barang');
      return bookings;
    } catch (e) {
      print('Error fetching all barang bookings: $e');
      return [];
    }
  }

  Widget _buildBarangExpansionTile(Map<String, dynamic> booking, int index) {
    final userMap = booking['user'] is Map
        ? Map<String, dynamic>.from(booking['user'] as Map)
        : <String, dynamic>{};
    final customerName = userMap['name'] ?? 'Pengirim ${index + 1}';
    final bookingNumber = booking['booking_number'] ?? '-';
    final weight = booking['weight']?.toString() ?? '-';

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
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2,
              color: Colors.orange[700],
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
            'Booking #${bookingNumber.split('-').last} • ${_formatWeightLabel(weight)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '1 barang',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBarangDetails(booking),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarangCard(Map<String, dynamic> booking) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        color: Colors.white,
      ),
      child: Column(
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
          _buildBarangDetails(booking),
        ],
      ),
    );
  }

  Widget _buildBarangDetails(Map<String, dynamic> booking) {
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
        // Barang info header
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
      ],
    );
  }
}
