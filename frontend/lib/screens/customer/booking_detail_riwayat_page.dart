import 'package:flutter/material.dart';
import '../../screens/customer/ubah_jadwal/ubah_jadwal_page.dart';
import '../../services/api_service.dart';

class BookingDetailRiwayatPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailRiwayatPage({Key? key, required this.booking})
      : super(key: key);

  @override
  State<BookingDetailRiwayatPage> createState() =>
      _BookingDetailRiwayatPageState();
}

class _BookingDetailRiwayatPageState extends State<BookingDetailRiwayatPage> {
  List<Map<String, dynamic>> allPassengers = [];
  bool isLoadingPassengers = false;

  @override
  void initState() {
    super.initState();
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    if (bookingType == 'mobil') {
      _fetchAllPassengers();
    }
  }

  Future<void> _fetchAllPassengers() async {
    setState(() {
      isLoadingPassengers = true;
    });

    try {
      final rideId = widget.booking['ride_id'] ?? widget.booking['car_ride_id'];
      if (rideId != null) {
        // Fetch all bookings for this ride from backend
        final response = await ApiService.getRidePassengers(rideId, 'mobil');
        setState(() {
          allPassengers = List<Map<String, dynamic>>.from(response);
          isLoadingPassengers = false;
        });
      }
    } catch (e) {
      print('Error fetching passengers: $e');
      setState(() {
        isLoadingPassengers = false;
      });
    }
  }

  Future<void> _onReschedulePressed() async {
    // Navigate to new ubah jadwal page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UbahJadwalPage(booking: widget.booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.booking['ride'] ?? {};
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    final user = widget.booking['user'] ?? {};

    // Generate title based on booking type
    String title = 'Booking';
    if (bookingType == 'motor') {
      title = 'Nebeng Motor';
    } else if (bookingType == 'mobil') {
      title = 'Nebeng Mobil';
    } else if (bookingType == 'barang') {
      title = 'Nebeng Barang';
    } else if (bookingType == 'titip') {
      title = 'Titip Barang';
    }

    // Date/time
    String rawDate = (ride['departure_date'] ?? '').toString();
    String rawTime = (ride['departure_time'] ?? '').toString();
    final dateOnly = _formatDateOnly(rawDate);

    // Origin/destination
    String origin = '';
    String destination = '';
    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? '';
    }
    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? '';
    }

    // Vehicle info
    String vehicle = '';
    String plate = '';
    if (ride['kendaraan_mitra'] is Map && ride['kendaraan_mitra'] != null) {
      final kendaraan = ride['kendaraan_mitra'];
      vehicle = (kendaraan['brand'] ?? '') + ' ' + (kendaraan['model'] ?? '');
      vehicle = vehicle.trim();
      if (vehicle.isEmpty) {
        vehicle = kendaraan['name'] ?? '';
      }
      plate = kendaraan['plate_number'] ?? '';
    }

    final seats = (widget.booking['seats'] ?? 1).toString();
    final price = ride['price'] ??
        widget.booking['price'] ??
        widget.booking['total_price'] ??
        0;
    final pricePerSeat = _formatPrice(price);
    final totalPrice = _formatPrice(
        (double.tryParse(price.toString()) ?? 0) * (int.tryParse(seats) ?? 1));

    // Driver info from ride.user
    final driver = ride['user'] ?? {};
    final driverName = driver['name'] ?? 'Driver';
    final driverPhoto = driver['photo_url'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFF0F4AA3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bookingType == 'motor'
                            ? Icons.two_wheeler
                            : Icons.directions_car,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Trip Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0F4AA3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Detail Perjalanan
              Text(
                'Detail Perjalanan',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),

              // Driver Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: driverPhoto.isNotEmpty
                          ? NetworkImage(driverPhoto)
                          : null,
                      child: driverPhoto.isEmpty
                          ? Icon(Icons.person, color: Colors.grey[600])
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                '5.0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '•',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              SizedBox(width: 8),
                              Text(
                                plate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF0F4AA3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.phone, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF0F4AA3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.message, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Route info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Origin
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_upward,
                              color: Colors.white, size: 18),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rawTime.split(':').take(2).join(':')}  $origin',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Senin   $dateOnly',
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
                    SizedBox(height: 24),
                    // Destination
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.arrow_downward,
                              color: Colors.white, size: 18),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '13:00  $destination',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Senin   $dateOnly',
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
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Penumpang section
              if (bookingType == 'motor' || bookingType == 'mobil') ...[
                Text(
                  'Penumpang',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                if (bookingType == 'mobil' && allPassengers.isNotEmpty) ...[
                  // Find the booking entry that matches this booking id
                  Builder(builder: (_) {
                    final currentBookingId = widget.booking['id']?.toString();
                    final matchedList = allPassengers
                        .where((b) => (b['id']?.toString() == currentBookingId))
                        .toList();

                    if (matchedList.isEmpty) {
                      // no matching booking found, fallback to showing current user
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              user['name'] ?? 'Customer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Penumpang 1',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final matched = matchedList.first;
                    final bookingUser = matched['user'] ?? {};
                    final bookingUserName = bookingUser['name'] ?? 'Pemesan';
                    final seats = matched['seats'] ?? 1;
                    final penumpangList = List<Map<String, dynamic>>.from(
                        matched['penumpang'] ?? []);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  color: Colors.blue[700], size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$bookingUserName (Pemesan)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '$seats kursi',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (penumpangList.isNotEmpty) ...[
                          SizedBox(height: 8),
                          ...penumpangList.asMap().entries.map((penEntry) {
                            final penIdx = penEntry.key;
                            final penumpang = penEntry.value;
                            final nama =
                                penumpang['nama'] ?? 'Penumpang ${penIdx + 1}';
                            final nik = penumpang['nik'];
                            final noTelp = penumpang['no_telepon'];

                            return Padding(
                              padding: EdgeInsets.only(bottom: 8, left: 16),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${penIdx + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nama,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (nik != null &&
                                              nik.isNotEmpty) ...[
                                            SizedBox(height: 2),
                                            Text(
                                              'NIK: $nik',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                          if (noTelp != null &&
                                              noTelp.isNotEmpty) ...[
                                            SizedBox(height: 2),
                                            Text(
                                              'Telp: $noTelp',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ] else ...[
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Text(
                              'Belum ada data penumpang untuk booking ini.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                        SizedBox(height: 12),
                      ],
                    );
                  }),
                ] else ...[
                  // For motor or if mobil data not loaded yet, show current user only
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          user['name'] ?? 'Customer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Penumpang 1',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24),
              ],

              // Harga breakdown
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Harga',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Text(
                          pricePerSeat,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (bookingType == 'motor' || bookingType == 'mobil')
                              ? 'Total Penumpang'
                              : 'Total Penumpang',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Text(
                          seats,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          totalPrice,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    // Additional info ONLY for barang & titip
                    if (bookingType == 'barang' || bookingType == 'titip') ...[
                      SizedBox(height: 16),
                      _buildInfoRow(
                          'No Pesanan',
                          widget.booking['id']?.toString() ??
                              'FR-234567899754324'),
                      SizedBox(height: 8),
                      _buildInfoRow(
                          'Waktu Pemesanan',
                          _formatDateTime(widget.booking['created_at'] ?? '',
                              '09:00-16:00')),
                      SizedBox(height: 8),
                      _buildInfoRow('Pembayaran', 'Transfer'),
                      SizedBox(height: 8),
                      _buildInfoRow('Bukti Pengiriman', 'Lihat Foto'),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Add bottom padding when button is shown in bottomNavigationBar
              if (bookingType == 'mobil' || bookingType == 'motor')
                SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: (bookingType == 'mobil' || bookingType == 'motor')
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onReschedulePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0F4AA3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Ubah Jadwal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: label == 'Bukti Pengiriman'
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;

    if (timeStr.isNotEmpty) {
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        dt = DateTime(dt.year, dt.month, dt.day, hour, minute);
      }
    }

    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
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

    return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month]} ${dt.year}';
  }

  String _formatDateOnly(String dateStr) {
    if (dateStr.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;

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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp0';

    double amount = 0;
    if (price is int) {
      amount = price.toDouble();
    } else if (price is double) {
      amount = price;
    } else if (price is String) {
      amount = double.tryParse(price) ?? 0;
    }

    int intAmount = amount.round();
    final formatted = intAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return 'Rp$formatted';
  }
}