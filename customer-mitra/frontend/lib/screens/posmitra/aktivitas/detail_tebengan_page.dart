import 'package:flutter/material.dart';

class DetailTebenganPage extends StatelessWidget {
  final Map<String, dynamic> activity;

  const DetailTebenganPage({
    Key? key,
    required this.activity,
  }) : super(key: key);

  // Get ride_type and service_type from activity
  String get rideType => activity['rideType'] ?? 'motor';
  String get serviceType => activity['serviceTypeRaw'] ?? 'tebengan';

  // Check service type
  bool get isTebengan => serviceType == 'tebengan';
  bool get isBarangService => serviceType == 'barang';
  bool get isBoth => serviceType == 'both';

  // Check ride type
  bool get isMotor => rideType == 'motor';
  bool get isMobil => rideType == 'mobil';
  bool get isBarangVehicle => rideType == 'barang';

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
  }

  // Get service type label for display (based on serviceType + rideType)
  String get serviceTypeLabel {
    if (isTebengan) {
      if (isMotor) return 'Nebeng Motor';
      if (isMobil) return 'Nebeng Mobil';
      return 'Neberng';
    } else if (isBarangService) {
      if (isBarangVehicle) return 'Nebeng Barang';
      return 'Titip Barang';
    } else if (isBoth) {
      if (isMotor) return 'Nebeng Motor + Barang';
      if (isMobil) return 'Nebeng Mobil + Barang';
      return 'Tebengan + Barang';
    }
    return 'Tebengan';
  }

  // Get ride type icon (based on rideType only)
  IconData get rideTypeIcon {
    if (isMotor) return Icons.two_wheeler;
    if (isMobil) return Icons.directions_car;
    if (isBarangVehicle) return Icons.inventory;
    return Icons.directions_car;
  }

  // Get ride type color (based on rideType only)
  Color get rideTypeColor {
    if (isMotor) return const Color(0xFF4CAF50);
    if (isMobil) return const Color(0xFF2196F3);
    if (isBarangVehicle) return const Color(0xFF9C27B0);
    return const Color(0xFF2196F3);
  }

  // Get service type color (based on serviceType)
  Color get serviceTypeColor {
    if (isTebengan) {
      if (isMotor) return const Color(0xFF4CAF50);
      if (isMobil) return const Color(0xFF2196F3);
    } else if (isBarangService) {
      if (isBarangVehicle) return const Color(0xFF9C27B0);
      return const Color(0xFFFF9800);
    } else if (isBoth) {
      return const Color(0xFF7B68EE);
    }
    return const Color(0xFF2196F3);
  }

  @override
  Widget build(BuildContext context) {
    final passengers = (activity['passengers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final hasPassengers = passengers.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail $serviceTypeLabel',
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Trip Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity['date'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: activity['statusColor'].withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity['status'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: activity['statusColor'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (activity['slot'] != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: serviceTypeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rideTypeIcon,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            activity['slot'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Locations
                  ...List.generate(
                    activity['locations'].length,
                    (index) {
                      final location = activity['locations'][index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < activity['locations'].length - 1 ? 12 : 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: location['isPrimary']
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFFEF5350),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location['name'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    location['detail'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF757575),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[200]),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimasi Pendapatan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        activity['price'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Dynamic Card Based on Service Type
            // Logic:
            // - tebengan: Vehicle Card + Passengers Card
            // - barang: Package Card + Sender Card
            // - both: Vehicle Card + Package Card + Passengers Card + Sender Card

            // Show Vehicle Card if tebengan or both
            if (isTebengan || isBoth) ...[
              _buildVehicleCard(),
              const SizedBox(height: 16),
            ],

            // Show Package Card if barang or both
            if (isBarangService || isBoth) ...[
              _buildPackageCard(),
              const SizedBox(height: 16),
            ],

            // Show Passengers Card if tebengan or both
            if (isTebengan || isBoth) ...[
              _buildPassengersCard(passengers, hasPassengers),
              const SizedBox(height: 16),
            ],

            // Show Sender Card if barang or both
            if (isBarangService || isBoth) ...[
              _buildSenderCard(passengers, hasPassengers),
              const SizedBox(height: 16),
            ],

            // Error message if no passengers
            if (!hasPassengers)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pembatalan dapat dilakukan maksimal 2 hari sebelum tanggal keberangkatan. Jika melebihi, yang digunakan akan kami blokir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Build Vehicle Card for Tebengan (Motor/Mobil)
  Widget _buildVehicleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(
                rideTypeIcon,
                size: 20,
                color: rideTypeColor,
              ),
              const SizedBox(width: 8),
              Text(
                isMotor ? 'Informasi Kendaraan Motor' : 'Informasi Kendaraan Mobil',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nama Mitra', activity['driverName'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Jenis Kendaraan', isMotor ? 'Motor' : 'Mobil'),
          const SizedBox(height: 12),
          _buildInfoRow('Nomor Plat', activity['plateNumber'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Tipe', activity['vehicleModel'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Warna', activity['vehicleColor'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Jumlah Kursi', activity['seats']?.toString() ?? '-'),
        ],
      ),
    );
  }

  // Build Package Card for Barang
  Widget _buildPackageCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              Icon(
                Icons.inventory,
                size: 20,
                color: const Color(0xFF9C27B0),
              ),
              const SizedBox(width: 8),
              const Text(
                'Informasi Paket',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nama Mitra', activity['driverName'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Jenis Kendaraan', activity['vehicleType'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Nomor Plat', activity['plateNumber'] ?? '-'),
          const SizedBox(height: 12),
          _buildInfoRow('Berat Maksimum', '20 kg'),
          const SizedBox(height: 12),
          _buildInfoRow('Dimensi Maksimum', '50x40x30 cm'),
        ],
      ),
    );
  }

  // Build Passengers Card for Tebengan
  Widget _buildPassengersCard(List<Map<String, dynamic>> passengers, bool hasPassengers) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Penebeng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          if (!hasPassengers)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_off,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Penebeng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tunggu hingga ada penebeng yang bergabung',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          else
            ...List.generate(passengers.length, (index) {
              final passenger = passengers[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < passengers.length - 1 ? 12 : 0,
                ),
                child: InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: rideTypeColor,
                        child: Text(
                          passenger['initial'] ?? '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              passenger['name'] ?? 'Penebeng',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              passenger['role'] ?? 'Penebeng',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9E9E9E),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // Build Sender Card for Barang
  Widget _buildSenderCard(List<Map<String, dynamic>> senders, bool hasSenders) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Pengirim',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          if (!hasSenders)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Pengirim',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tunggu hingga ada yang menitipkan barang',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          else
            ...List.generate(senders.length, (index) {
              final sender = senders[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < senders.length - 1 ? 12 : 0,
                ),
                child: InkWell(
                  onTap: () {},
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF9C27B0),
                        child: Text(
                          sender['initial'] ?? '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sender['name'] ?? 'Pengirim',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sender['package_info'] ?? 'Barang',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9E9E9E),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
