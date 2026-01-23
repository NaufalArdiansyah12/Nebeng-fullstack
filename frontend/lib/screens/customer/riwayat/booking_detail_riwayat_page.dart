import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../ubah_jadwal/ubah_jadwal_page.dart';
import '../driver_tracking_page.dart';
import '../../../services/api_service.dart';

class BookingDetailRiwayatPage extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailRiwayatPage({Key? key, required this.booking})
      : super(key: key);

  @override
  State<BookingDetailRiwayatPage> createState() =>
      _BookingDetailRiwayatPageState();
}

class _BookingDetailRiwayatPageState extends State<BookingDetailRiwayatPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allPassengers = [];
  bool isLoadingPassengers = false;
  Map<String, dynamic>? trackingData;
  String currentStatus = 'pending';
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  Duration? _timeUntilDeparture;
  AnimationController? _dotsAnimationController;
  int _currentDot = 0;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.booking['status'] ?? 'pending';
    _fetchTrackingData();
    _startCountdown();
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (_dotsAnimationController!.isCompleted) {
          setState(() {
            _currentDot = (_currentDot + 1) % 3;
          });
          _dotsAnimationController!.reset();
          _dotsAnimationController!.forward();
        }
      });
    _dotsAnimationController!.forward();
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    if (bookingType == 'mobil') {
      _fetchAllPassengers();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _dotsAnimationController?.dispose();
    super.dispose();
  }

  void _startCountdown() {
    final ride = widget.booking['ride'] ?? {};
    final departureDate = ride['departure_date'] ?? '';
    final departureTime = ride['departure_time'] ?? '';

    try {
      if (departureDate.isNotEmpty && departureTime.isNotEmpty) {
        final departureDateTimeParts = departureDate.split('T')[0].split('-');
        final departureTimeParts = departureTime.split(':');

        final departureDateTime = DateTime(
          int.parse(departureDateTimeParts[0]),
          int.parse(departureDateTimeParts[1]),
          int.parse(departureDateTimeParts[2]),
          int.parse(departureTimeParts[0]),
          int.parse(departureTimeParts[1]),
        );

        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final now = DateTime.now();
          final difference = departureDateTime.difference(now);

          if (difference.isNegative) {
            setState(() {
              _timeUntilDeparture = null;
            });
            timer.cancel();
          } else {
            setState(() {
              _timeUntilDeparture = difference;
            });
          }
        });
      }
    } catch (e) {
      print('Error starting countdown: $e');
    }
  }

  Future<void> _fetchTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final bookingId = widget.booking['id'];
      final data = await ApiService.getBookingTracking(
        bookingId: bookingId,
        token: token,
      );

      setState(() {
        trackingData = data;
        currentStatus = data['status'] ?? widget.booking['status'] ?? 'pending';
      });

      // Auto refresh untuk status aktif
      if (currentStatus == 'in_progress' ||
          currentStatus == 'paid' ||
          currentStatus == 'confirmed') {
        _refreshTimer?.cancel();
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _fetchTrackingData();
        });
      }
    } catch (e) {
      print('Error fetching tracking: $e');
    }
  }

  Future<void> _fetchAllPassengers() async {
    setState(() {
      isLoadingPassengers = true;
    });
    try {
      final rideId = widget.booking['ride_id'] ?? widget.booking['car_ride_id'];
      if (rideId != null) {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UbahJadwalPage(booking: widget.booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show different layout for in_progress status
    if (currentStatus == 'in_progress') {
      return _buildInProgressLayout();
    }

    return _buildDefaultLayout();
  }

  Widget _buildInProgressLayout() {
    final ride = widget.booking['ride'] ?? {};
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    final driver = ride['user'] ?? {};
    final driverName = driver['name'] ?? 'Jamal Driver';
    final driverPhoto = driver['photo_url'] ?? '';
    final kendaraan = ride['kendaraan_mitra'] ?? {};
    final vehicle =
        (kendaraan['brand'] ?? 'Bus') + ' ' + (kendaraan['model'] ?? '');
    final origin = ride['origin_location']?['name'] ?? 'Yogyakarta';
    final originAddress = ride['origin_location']?['address'] ??
        'Patehan, Kecamatan Kraton, Kota Yogyakarta...';
    final destination = ride['destination_location']?['name'] ?? 'Purwokerto';
    final destinationAddress =
        ride['destination_location']?['address'] ?? 'Alun-alun Purwokerto';
    final rawDate = (ride['departure_date'] ?? '').toString();
    final rawTime = (ride['departure_time'] ?? '').toString();
    final arrivalTime = (ride['arrival_time'] ?? '18:45').toString();
    final dateOnly = _formatDateOnly(rawDate);
    final price = ride['price'] ?? widget.booking['total_price'] ?? 20000;

    // Get driver location from tracking data
    double? driverLat = trackingData?['location']?['lat'];
    double? driverLng = trackingData?['location']?['lng'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Perjalanan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Maps Section (Placeholder)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue[100]!,
                  Colors.blue[200]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Map placeholder pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                  ),
                ),
                // Driver marker
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Driver dalam perjalanan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'No Pesanan :',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      Text(
                        widget.booking['booking_number'] ?? 'FR-234567899754',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Animated Dots
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentDot == index
                                ? const Color(0xFF1E3A8A)
                                : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Text
                  const Center(
                    child: Text(
                      'PERJALANAN SEDANG BERLANGSUNG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Date and Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateOnly,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${rawTime.substring(0, 5)} - $arrivalTime',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Vehicle Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.isNotEmpty ? vehicle.trim() : 'Bus',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Transportasi Umum',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.directions_bus, size: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Driver Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: driverPhoto.isNotEmpty
                              ? NetworkImage(driverPhoto)
                              : null,
                          child: driverPhoto.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            driverName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.message),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Origin Location
                  _buildLocationCard(
                    icon: Icons.circle,
                    iconColor: Colors.grey,
                    title: origin,
                    subtitle: originAddress,
                  ),
                  const SizedBox(height: 12),

                  // Destination Location
                  _buildLocationCard(
                    icon: Icons.circle,
                    iconColor: Colors.red,
                    title: destination,
                    subtitle: destinationAddress,
                  ),
                  const SizedBox(height: 24),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Biaya',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        _formatPrice(price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.black87),
                      ),
                      child: const Text(
                        'Batalkan Pesanan',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Color(0xFF0F4AA3)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Visit',
              style: TextStyle(color: Color(0xFF0F4AA3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLayout() {
    final ride = widget.booking['ride'] ?? {};
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    final user = widget.booking['user'] ?? {};

    String title = 'Booking';
    IconData headerIcon = Icons.directions_car;
    Color accentColor = const Color(0xFF0F4AA3);

    if (bookingType == 'motor') {
      title = 'Nebeng Motor';
      headerIcon = Icons.two_wheeler;
    } else if (bookingType == 'mobil') {
      title = 'Nebeng Mobil';
      headerIcon = Icons.directions_car;
    } else if (bookingType == 'barang') {
      title = 'Nebeng Barang';
      headerIcon = Icons.local_shipping;
    } else if (bookingType == 'titip') {
      title = 'Titip Barang';
      headerIcon = Icons.inventory_2;
    }

    String rawDate = (ride['departure_date'] ?? '').toString();
    String rawTime = (ride['departure_time'] ?? '').toString();
    final dateOnly = _formatDateOnly(rawDate);

    String origin = '';
    String destination = '';
    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? '';
    }
    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? '';
    }

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

    final driver = ride['user'] ?? {};
    final driverName = driver['name'] ?? 'Driver';
    final driverPhoto = driver['photo_url'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Perjalanan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Gradient
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      headerIcon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(currentStatus),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Countdown Section (only for waiting status)
            if (currentStatus == 'paid' || currentStatus == 'confirmed')
              _buildCountdownSection(rawDate, rawTime),

            const SizedBox(height: 16),

            // Driver Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: driverPhoto.isNotEmpty
                          ? NetworkImage(driverPhoto)
                          : null,
                      child: driverPhoto.isEmpty
                          ? Icon(Icons.person,
                              color: Colors.grey[600], size: 28)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '5.0',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              plate,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(Icons.phone, accentColor),
                  const SizedBox(width: 10),
                  _buildActionButton(Icons.chat_bubble_outline, accentColor),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Route Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Origin
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Penjemputannnnnnn',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              origin,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${rawTime.split(':').take(2).join(':')} • $dateOnly',
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

                  const SizedBox(height: 24),

                  // Destination
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tujuan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '13:00 • $dateOnly',
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
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Penumpang section
            if (bookingType == 'motor' || bookingType == 'mobil') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Informasi Penumpang',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (bookingType == 'mobil' && allPassengers.isNotEmpty) ...[
                Builder(builder: (_) {
                  final currentBookingId = widget.booking['id']?.toString();
                  final matchedList = allPassengers
                      .where((b) => (b['id']?.toString() == currentBookingId))
                      .toList();

                  if (matchedList.isEmpty) {
                    return _buildSimplePassengerCard(
                        user['name'] ?? 'Customer');
                  }

                  final matched = matchedList.first;
                  final bookingUser = matched['user'] ?? {};
                  final bookingUserName = bookingUser['name'] ?? 'Pemesan';
                  final seats = matched['seats'] ?? 1;
                  final penumpangList = List<Map<String, dynamic>>.from(
                      matched['penumpang'] ?? []);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookingUserName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Pemesan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$seats kursi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (penumpangList.isNotEmpty) ...[
                          ...penumpangList.asMap().entries.map((penEntry) {
                            final penIdx = penEntry.key;
                            final penumpang = penEntry.value;
                            final nama =
                                penumpang['nama'] ?? 'Penumpang ${penIdx + 1}';
                            final nik = penumpang['nik'];
                            final noTelp = penumpang['no_telepon'];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${penIdx + 1}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[700],
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (nik != null && nik.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'NIK: $nik',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        if (noTelp != null &&
                                            noTelp.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Telp: $noTelp',
                                            style: TextStyle(
                                              fontSize: 12,
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
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Belum ada data penumpang untuk booking ini.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ] else ...[
                _buildSimplePassengerCard(user['name'] ?? 'Customer'),
              ],
              const SizedBox(height: 16),
            ],

            // Price Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildPriceRow('Harga per Kursi', pricePerSeat, false),
                  const SizedBox(height: 14),
                  _buildPriceRow(
                    (bookingType == 'motor' || bookingType == 'mobil')
                        ? 'Jumlah Kursi'
                        : 'Total Penumpang',
                    seats,
                    false,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Colors.grey[200]),
                  ),
                  _buildPriceRow('Total Pembayaran', totalPrice, true),
                  if (bookingType == 'barang' || bookingType == 'titip') ...[
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      'No Pesanan',
                      widget.booking['id']?.toString() ?? 'FR-234567899754324',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Waktu Pemesanan',
                      _formatDateTime(
                          widget.booking['created_at'] ?? '', '09:00-16:00'),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Pembayaran', 'Transfer'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Bukti Pengiriman', 'Lihat Foto'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: (bookingType == 'mobil' ||
              bookingType == 'motor' ||
              bookingType == 'barang' ||
              bookingType == 'titip')
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final rawId = widget.booking['id'];
                            final bookingId = rawId is int
                                ? rawId
                                : int.tryParse(rawId?.toString() ?? '') ?? 0;
                            if (bookingId > 0) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DriverTrackingPage(bookingId: bookingId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('ID booking tidak tersedia.'),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0F4AA3)),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F4AA3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Lacak Perjalanan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onReschedulePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4AA3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSimplePassengerCard(String name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4AA3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF0F4AA3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            'Penumpang',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? const Color(0xFF0F4AA3) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
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

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'Sedang Berlangsung';
      case 'completed':
        return 'Trip Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'paid':
      case 'confirmed':
        return 'Menunggu';
      default:
        return 'Menunggu Pembayaran';
    }
  }

  Widget _buildCountdownSection(String rawDate, String rawTime) {
    final dateOnly = _formatDateOnly(rawDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Jadwal Berangkat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$dateOnly Jam ${rawTime.substring(0, 5)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          if (_timeUntilDeparture != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCountdownBox(
                  _timeUntilDeparture!.inDays.toString().padLeft(2, '0'),
                  'Hari',
                ),
                const SizedBox(width: 12),
                _buildCountdownBox(
                  (_timeUntilDeparture!.inHours % 24)
                      .toString()
                      .padLeft(2, '0'),
                  'Jam',
                ),
                const SizedBox(width: 12),
                _buildCountdownBox(
                  (_timeUntilDeparture!.inMinutes % 60)
                      .toString()
                      .padLeft(2, '0'),
                  'Menit',
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Waktu keberangkatan telah tiba',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountdownBox(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for map-like pattern
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw grid lines
    const gridSize = 30.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
