import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'mitra_tracking_map_page.dart';

class MitraTebenganDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MitraTebenganDetailPage({Key? key, required this.item})
      : super(key: key);

  @override
  State<MitraTebenganDetailPage> createState() =>
      _MitraTebenganDetailPageState();
}

class _MitraTebenganDetailPageState extends State<MitraTebenganDetailPage> {
  @override
  void initState() {
    super.initState();
    print('🔍 widget.item structure: ${jsonEncode(widget.item)}');
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp 0,00';
    double amount = 0;
    if (price is int) amount = price.toDouble();
    if (price is double) amount = price;
    if (price is String) amount = double.tryParse(price) ?? 0;
    int intAmount = amount.round();
    final formatted = intAmount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return 'Rp $formatted,00';
  }

  String _formatDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty && timeStr.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt == null) {
      return '${dateStr}${timeStr.isNotEmpty ? ' | $timeStr' : ''}';
    }
    if (timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        dt = DateTime(dt.year, dt.month, dt.day, h, m);
      }
    }
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year | $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.item['ride'] ?? {};
    final origin = (ride['origin_location'] is Map)
        ? (ride['origin_location']['name'] ?? '')
        : '';
    final destination = (ride['destination_location'] is Map)
        ? (ride['destination_location']['name'] ?? '')
        : '';
    final date = ride['departure_date'] ?? '';
    final time = ride['departure_time'] ?? '';
    final kode = ride['code'] ?? '';
    final headerDate = _formatDateTime(date.toString(), time.toString());
    final status = (ride['status'] ?? '').toString().toLowerCase();

    String statusLabel = 'Proses';
    Color statusBgColor = const Color(0xFFDDD6FE);

    if (status.contains('completed') || status == 'completed') {
      statusLabel = 'Selesai';
      statusBgColor = const Color(0xFFD1FAE5);
    } else if (status.contains('active') || status == 'active') {
      statusLabel = 'Proses';
      statusBgColor = const Color(0xFFDDD6FE);
    } else if (status.contains('cancel') || status == 'cancelled') {
      statusLabel = 'Dibatalkan';
      statusBgColor = const Color(0xFFFEE2E2);
    }

    final income = (widget.item['income'] ?? 0);
    final incomeLabel =
        (status.contains('completed')) ? 'Pendapatan' : 'Estimasi Pendapatan';

    final mitraVehicle = ride['kendaraan_mitra'] ?? {};

    // Nama Mitra
    String ownerName = '';
    final candidates = <String?>[
      if (ride['mitra'] is Map) (ride['mitra']['name'] ?? '')?.toString(),
      if (widget.item['mitra'] is Map)
        (widget.item['mitra']['name'] ?? '')?.toString(),
      if (ride['owner'] is Map) (ride['owner']['name'] ?? '')?.toString(),
      if (widget.item['owner'] is Map)
        (widget.item['owner']['name'] ?? '')?.toString(),
      if (ride['user'] is Map) (ride['user']['name'] ?? '')?.toString(),
      if (widget.item['user'] is Map)
        (widget.item['user']['name'] ?? '')?.toString(),
      (widget.item['mitra_name'] ?? '')?.toString(),
      (ride['mitra_name'] ?? '')?.toString(),
      (widget.item['owner_name'] ?? '')?.toString(),
      (mitraVehicle['owner_name'] ?? '')?.toString(),
      (mitraVehicle['owner'] ?? '')?.toString(),
      (mitraVehicle['driver_name'] ?? '')?.toString(),
    ];
    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        ownerName = c.toString().trim();
        break;
      }
    }
    if (ownerName.isEmpty) ownerName = '-';

    // Transportasi
    String _transportationLabel(Map vehicle, String serviceType) {
      final rawType = (vehicle['type'] ??
              vehicle['vehicle_type'] ??
              vehicle['transportation'] ??
              '')
          .toString()
          .toLowerCase();
      final sType = serviceType.toString().toLowerCase();
      if (rawType.contains('motor') || sType.contains('motor')) return 'Motor';
      if (rawType.contains('mobil') ||
          rawType.contains('car') ||
          sType.contains('mobil') ||
          sType.contains('car')) return 'Mobil';
      return 'Motor';
    }

    final transportasi = _transportationLabel(
        mitraVehicle, (ride['service_type'] ?? '').toString());
    final plat = (mitraVehicle['plat_number'] ??
            mitraVehicle['plate_number'] ??
            mitraVehicle['license_plate'] ??
            '-')
        .toString();

    final vehicleModel = (mitraVehicle['name'] ??
            mitraVehicle['vehicle_name'] ??
            mitraVehicle['model'] ??
            mitraVehicle['tipe'] ??
            '-')
        .toString();
    final warna =
        (mitraVehicle['color'] ?? mitraVehicle['warna'] ?? '-').toString();

    // seat count
    String kursi = '-';
    if ((mitraVehicle['seat_count'] ?? '').toString().isNotEmpty) {
      kursi = mitraVehicle['seat_count'].toString();
    } else if ((mitraVehicle['jumlah_kursi'] ?? '').toString().isNotEmpty) {
      kursi = mitraVehicle['jumlah_kursi'].toString();
    } else if ((ride['seat_count'] ?? '').toString().isNotEmpty) {
      kursi = ride['seat_count'].toString();
    } else if ((mitraVehicle['seats'] ?? '').toString().isNotEmpty) {
      kursi = mitraVehicle['seats'].toString();
    }

    final rideType = (widget.item['type'] ?? '').toString().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Detail Tebengan',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(headerDate, kode, statusLabel, statusBgColor,
                  origin, destination, incomeLabel, income),
              const SizedBox(height: 20),
              // Tracking Map Button
              Builder(builder: (context) {
                final ride = widget.item['ride'] ?? {};
                final status = (ride['status'] ?? '').toString().toLowerCase();
                final showTrackingButton = status.contains('active') ||
                    status.contains('progress') ||
                    status == 'paid' ||
                    status == 'confirmed';

                if (showTrackingButton) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MitraTrackingMapPage(
                                item: widget.item,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text(
                          'Buka Peta Tracking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              _buildInfoMitra(
                  ownerName, transportasi, plat, vehicleModel, warna, kursi),
              const SizedBox(height: 20),
              // Informasi Penebeng - berbeda untuk setiap jenis
              if (rideType == 'motor')
                _buildPenumpangMotor(ride)
              else if (rideType == 'mobil')
                _buildPenumpangMobil(ride)
              else if (rideType == 'barang')
                _buildPenumpangBarang(ride)
              else if (rideType == 'titip')
                _buildPenumpangTitipBarang(ride),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      String headerDate,
      String kode,
      String statusLabel,
      Color statusBgColor,
      String origin,
      String destination,
      String incomeLabel,
      dynamic income) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '$headerDate | $kode',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusLabel == 'Selesai'
                        ? const Color(0xFF059669)
                        : statusLabel == 'Dibatalkan'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Origin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.grey[300],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      origin.isNotEmpty ? origin : '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Alun-alun ${origin.isNotEmpty ? origin : '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Destination
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.isNotEmpty ? destination : '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Alun-alun ${destination.isNotEmpty ? destination : '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                incomeLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                _formatPrice(income),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMitra(String ownerName, String transportasi, String plat,
      String vehicleModel, String warna, String kursi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Mitra',
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
          child: Column(
            children: [
              _infoRow('Nama Mitra', ownerName),
              _infoRow('Transportasi', transportasi),
              _infoRow('Nomor Plat', plat),
              _infoRow('Tipe', vehicleModel),
              _infoRow('Warna', warna),
              _infoRow('Jumlah Kursi', kursi, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  // TEBENGAN MOTOR - hanya tampilkan customer
  Widget _buildPenumpangMotor(Map<String, dynamic> ride) {
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
        FutureBuilder<Map<String, dynamic>?>(
          future: _getMotorBooking(ride['id']),
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
            final customerName = booking?['user']?['name'] ?? '-';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: _buildPassengerTile(customerName, 'Chat customer'),
            );
          },
        ),
      ],
    );
  }

  // TEBENGAN MOBIL - tampilkan pemesan di atas + list penumpang dari penumpang_booking_mobil
  Widget _buildPenumpangMobil(Map<String, dynamic> ride) {
    final rideId = ride['id'];

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
        FutureBuilder<Map<String, dynamic>>(
          future: _getMobilBookingWithPassengers(rideId),
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
            final customerName = data['customer_name'] ?? '-';
            final totalSeats = data['total_seats'] ?? 0;
            final passengers = data['passengers'] as List<dynamic>;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pemesan
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
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
                                  : 'J',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                                customerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pemesan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalSeats kursi',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List Penumpang
                  ...passengers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final passenger = entry.value;
                    final nama = passenger['nama'] ?? '-';
                    final telp = passenger['no_telp'] ?? '';
                    final isLast = index == passengers.length - 1;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: !isLast
                            ? Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                              )
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
                                '${index + 1}',
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
            );
          },
        ),
      ],
    );
  }

  // TEBENGAN BARANG - tampilkan customer + foto barang + kapasitas
  Widget _buildPenumpangBarang(Map<String, dynamic> ride) {
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
          future: _getBarangBooking(ride['id']),
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
            final customerName = booking?['user']?['name'] ?? '-';
            final customerPhone = booking?['user']?['phone'] ??
                booking?['user']?['no_telepon'] ??
                '';
            final meta = booking?['meta'];
            final senderName = meta is Map
                ? (meta['sender_name']?.toString() ?? customerName)
                : customerName;
            final senderPhone = meta is Map
                ? (meta['sender_phone']?.toString() ?? customerPhone)
                : customerPhone;

            // Convert relative photo URL to absolute URL
            String photo = booking?['photo']?.toString() ?? '';
            if (photo.isNotEmpty && !photo.startsWith('http')) {
              final baseUrl = ApiService.baseUrl;
              photo =
                  photo.startsWith('/') ? '$baseUrl$photo' : '$baseUrl/$photo';
            }

            final description = booking?['description']?.toString() ?? '-';
            final weight = booking?['weight']?.toString() ?? '-';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              senderName.isNotEmpty
                                  ? senderName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                                senderName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pengirim${senderPhone.isNotEmpty ? ' • $senderPhone' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Barang yang Dikirim',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Kapasitas: $weight',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
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
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey[400]),
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // TITIP BARANG - sama dengan barang + data penerima
  Widget _buildPenumpangTitipBarang(Map<String, dynamic> ride) {
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
          future: _getTitipBarangBooking(ride['id']),
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
            final customerName = booking?['user']?['name'] ?? '-';
            final customerPhone = booking?['user']?['phone'] ??
                booking?['user']?['no_telepon'] ??
                '';
            final meta = booking?['meta'];
            final senderName = meta is Map
                ? (meta['sender_name']?.toString() ?? customerName)
                : customerName;
            final senderPhone = meta is Map
                ? (meta['sender_phone']?.toString() ?? customerPhone)
                : customerPhone;

            // Parse penerima from JSON string or Map or pipe-separated format
            String receiverName = '-';
            String receiverPhone = '';
            final penerimaData = booking?['penerima'];
            if (penerimaData is String && penerimaData.isNotEmpty) {
              // Try JSON format first
              if (penerimaData.startsWith('{')) {
                try {
                  final decoded = jsonDecode(penerimaData);
                  if (decoded is Map) {
                    receiverName = decoded['name']?.toString() ??
                        decoded['receiver_name']?.toString() ??
                        '-';
                    receiverPhone = decoded['phone']?.toString() ??
                        decoded['receiver_phone']?.toString() ??
                        '';
                  }
                } catch (e) {
                  print('Error parsing penerima JSON: $e');
                }
              } else {
                // Try pipe-separated format: "Name|Phone"
                final parts = penerimaData.split('|');
                if (parts.isNotEmpty) {
                  receiverName = parts[0].trim();
                  if (parts.length > 1) {
                    receiverPhone = parts[1].trim();
                  }
                }
              }
            } else if (penerimaData is Map) {
              receiverName = penerimaData['name']?.toString() ??
                  penerimaData['receiver_name']?.toString() ??
                  '-';
              receiverPhone = penerimaData['phone']?.toString() ??
                  penerimaData['receiver_phone']?.toString() ??
                  '';
            }

            // Fallback to meta if penerima not found
            if (receiverName == '-' && meta is Map) {
              receiverName = meta['receiver_name']?.toString() ?? '-';
              receiverPhone = meta['receiver_phone']?.toString() ?? '';
            }

            // Convert relative photo URL to absolute URL
            String photo = booking?['photo']?.toString() ?? '';
            if (photo.isNotEmpty && !photo.startsWith('http')) {
              final baseUrl = ApiService.baseUrl;
              photo =
                  photo.startsWith('/') ? '$baseUrl$photo' : '$baseUrl/$photo';
            }

            final description = booking?['description']?.toString() ?? '-';
            final weight = booking?['weight']?.toString() ?? '-';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              senderName.isNotEmpty
                                  ? senderName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                                senderName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pengirim${senderPhone.isNotEmpty ? ' • $senderPhone' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receiverName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Penerima${receiverPhone.isNotEmpty ? ' • $receiverPhone' : ''}',
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
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Barang yang Dikirim',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Kapasitas: $weight',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
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
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey[400]),
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // API Calls
  Future<Map<String, dynamic>?> _getMotorBooking(dynamic rideId) async {
    try {
      print('🔍 Fetching motor booking for ride ID: $rideId');

      // Gunakan endpoint passengers untuk mendapatkan booking motor
      final passengers = await ApiService.getRidePassengers(rideId, 'motor');

      if (passengers.isNotEmpty) {
        // Untuk motor, biasanya hanya 1 booking
        final booking = passengers.first;
        print('✅ Motor booking found: ${booking['id']}');
        return booking;
      }

      print('❌ No motor booking found for ride ID: $rideId');
      return null;
    } catch (e) {
      print('❌ Error fetching motor booking: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getMobilBookingWithPassengers(
      dynamic rideId) async {
    try {
      // Ambil booking mobil + penumpang dari penumpang_booking_mobil
      final passengers = await ApiService.getRidePassengers(rideId, 'mobil');

      // Extract customer name dan total seats dari booking pertama
      String customerName = 'John Customer';
      int totalSeats = 0;
      List<dynamic> allPassengers = [];

      for (var booking in passengers) {
        if (booking['user'] != null && booking['user']['name'] != null) {
          customerName = booking['user']['name'];
        }
        if (booking['seats'] != null) {
          totalSeats += (booking['seats'] as int);
        }
        if (booking['penumpang'] is List) {
          allPassengers.addAll(booking['penumpang']);
        }
      }

      return {
        'customer_name': customerName,
        'total_seats': totalSeats,
        'passengers': allPassengers,
      };
    } catch (e) {
      return {
        'customer_name': '-',
        'total_seats': 0,
        'passengers': [],
      };
    }
  }

  Future<Map<String, dynamic>?> _getBarangBooking(dynamic rideId) async {
    try {
      // Ambil booking barang berdasarkan ride_id
      final rideIdInt = int.tryParse(rideId.toString()) ?? 0;
      if (rideIdInt == 0) return null;

      final bookings = await ApiService.getRidePassengers(rideIdInt, 'barang');

      if (bookings.isNotEmpty) {
        return bookings.first;
      }
      return null;
    } catch (e) {
      print('Error fetching barang booking: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getTitipBarangBooking(dynamic rideId) async {
    try {
      // Ambil booking titip barang berdasarkan ride_id
      final rideIdInt = int.tryParse(rideId.toString()) ?? 0;
      if (rideIdInt == 0) return null;

      final bookings = await ApiService.getRidePassengers(rideIdInt, 'titip');

      if (bookings.isNotEmpty) {
        return bookings.first;
      }
      return null;
    } catch (e) {
      print('Error fetching titip barang booking: $e');
      return null;
    }
  }

  Widget _buildPassengerTile(String name, String subtitle,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFBBF24),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'N',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
