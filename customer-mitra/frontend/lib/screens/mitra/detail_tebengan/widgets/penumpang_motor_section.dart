import 'package:flutter/material.dart';
import '../services/booking_data_service.dart';
import '../../widgets/mitra_barang_card.dart';
import 'passenger_tile.dart';

class PenumpangMotorSection extends StatelessWidget {
  final Map<String, dynamic> ride;
  final Function(Map<String, dynamic>?) onChatPressed;

  const PenumpangMotorSection({
    Key? key,
    required this.ride,
    required this.onChatPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final serviceType = ride['service_type']?.toString().toLowerCase();

    return FutureBuilder<Map<String, dynamic>?>(
      future: BookingDataService.getMotorBooking(ride['id']),
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
        final userMap = booking?['user'] is Map
            ? Map<String, dynamic>.from(booking!['user'] as Map)
            : <String, dynamic>{};
        final customerName = userMap['name'] ?? '-';
        final photo = booking?['photo']?.toString() ?? '';
        final weight = booking?['weight']?.toString() ?? '';
        final description = booking?['description']?.toString() ?? '';
        final hasBarangData =
            photo.isNotEmpty || weight.isNotEmpty || description.isNotEmpty;

        // If service_type is 'both', show both passenger and barang info
        if (serviceType == 'both') {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Passenger Info
              const Text(
                'Informasi Penumpang',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: PassengerTile(
                  name: customerName,
                  subtitle: 'Chat customer',
                  onTap: () => onChatPressed(booking),
                ),
              ),
              const SizedBox(height: 20),

              // Barang Info
              const Text(
                'Informasi Barang',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              MitraBarangCard(
                photoUrl: photo,
                weight: weight,
                description: description,
              ),
            ],
          );
        }
        // If service_type is 'barang' or has barang data, show only barang
        else if (serviceType == 'barang' || hasBarangData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer/Pemesan Info untuk barang
              const Text(
                'Pemesan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: Row(
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
                            customerName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pemilik Barang',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.blue[700],
                      ),
                      onPressed: () => onChatPressed(booking),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Informasi Barang
              const Text(
                'Informasi Barang',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              MitraBarangCard(
                photoUrl: photo,
                weight: weight,
                description: description,
              ),
            ],
          );
        }
        // Default: show passenger info
        else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informasi Penumpang',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: PassengerTile(
                  name: customerName,
                  subtitle: 'Chat customer',
                  onTap: () => onChatPressed(booking),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
