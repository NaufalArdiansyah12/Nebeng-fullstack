import 'package:flutter/material.dart';
import '../services/booking_data_service.dart';
import '../../widgets/mitra_barang_card.dart';

class PenumpangMobilSection extends StatelessWidget {
  final Map<String, dynamic> ride;

  const PenumpangMobilSection({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rideId = ride['id'];
    final serviceType = (ride['service_type'] ?? '').toString().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          serviceType == 'both'
              ? 'Informasi Penumpang & Barang'
              : 'Informasi Penumpang',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Map<String, dynamic>>(
          future: BookingDataService.getMobilBookingWithPassengers(rideId),
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

            if (!snapshot.hasData || snapshot.data == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: const Text('Tidak ada data penumpang'),
              );
            }

            final data = snapshot.data!;
            final bookings = data['bookings'] as List<dynamic>;

            if (bookings.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.white,
                ),
                child: const Text('Tidak ada booking'),
              );
            }

            // Group bookings in expansion tiles
            return Column(
              children: bookings.asMap().entries.map((entry) {
                final index = entry.key;
                final booking = entry.value;
                final userMap = booking['user'] is Map
                    ? Map<String, dynamic>.from(booking['user'] as Map)
                    : <String, dynamic>{};
                final customerName = userMap['name'] ?? 'Customer ${index + 1}';
                final seats = booking['seats'] ?? 0;
                final passengers =
                    (booking['penumpang'] as List<dynamic>?) ?? [];
                final bookingNumber = booking['booking_number'] ?? '-';

                // Data barang per booking
                final photo = booking['photo']?.toString() ?? '';
                final weight = booking['weight']?.toString() ?? '';
                final description = booking['description']?.toString() ?? '';
                final hasBarangData = photo.isNotEmpty ||
                    weight.isNotEmpty ||
                    description.isNotEmpty;

                return Container(
                  margin: EdgeInsets.only(
                      bottom: index < bookings.length - 1 ? 12 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    color: Colors.white,
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      childrenPadding: const EdgeInsets.only(bottom: 12),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            customerName.isNotEmpty
                                ? customerName[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
                        'Booking #${bookingNumber.split('-').last} • $seats kursi',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          BookingDataService.getBookingCountLabel(
                              serviceType, passengers.length, hasBarangData),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      children: [
                        // Section Penumpang
                        if (serviceType != 'barang') ...[
                          if (passengers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                'Belum ada data penumpang',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            )
                          else
                            ...passengers.asMap().entries.map((passengerEntry) {
                              final pIndex = passengerEntry.key;
                              final passenger = passengerEntry.value;
                              final nama = passenger['nama'] ?? '-';
                              final telp = passenger['no_telepon'] ?? '';
                              final isLast = pIndex == passengers.length - 1;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: !isLast ||
                                          (serviceType == 'both' &&
                                              hasBarangData)
                                      ? Border(
                                          bottom: BorderSide(
                                              color: Colors.grey[200]!))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${pIndex + 1}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (telp.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Telp: $telp',
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
                              );
                            }).toList(),
                        ],

                        // Section Barang (for 'both' and 'barang' service types)
                        if ((serviceType == 'both' ||
                                serviceType == 'barang') &&
                            hasBarangData) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2,
                                    size: 18, color: Colors.orange[700]),
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
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: MitraBarangCard(
                              photoUrl: photo,
                              weight: weight,
                              description: description,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
