import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../ubah_jadwal/ubah_jadwal_page.dart';
import '../../../services/api_service.dart';

// Import extracted components
import 'booking_detail/widgets/booking_header.dart';
import 'booking_detail/widgets/countdown_section.dart';
import 'booking_detail/widgets/driver_info_card.dart';
import 'booking_detail/widgets/route_card.dart';
import 'booking_detail/widgets/passenger_card.dart';
import 'booking_detail/widgets/price_card.dart';
import 'booking_detail/widgets/in_progress_layout.dart';
import 'booking_detail/widgets/waiting_at_pickup_layout.dart';
import 'booking_detail/widgets/arrived_at_destination_layout.dart';
import 'booking_detail/utils/booking_formatters.dart';
import 'booking_detail/utils/countdown_helper.dart';

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
  Duration? _timeUntilDeparture;
  AnimationController? _dotsAnimationController;
  int _currentDot = 0;

  // Movement tracking
  double? _previousLat;
  double? _previousLng;
  bool _isDriverMoving = false;
  DateTime? _lastLocationUpdate;

  final CountdownHelper _countdownHelper = CountdownHelper();

  // Polling intervals
  static const Duration _movingInterval = Duration(seconds: 5);
  static const Duration _stationaryInterval = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    currentStatus = widget.booking['status'] ?? 'pending';
    _fetchTrackingData();
    _startCountdown();
    _initDotsAnimation();

    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    if (bookingType == 'mobil') {
      _fetchAllPassengers();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownHelper.dispose();
    _dotsAnimationController?.dispose();
    super.dispose();
  }

  void _initDotsAnimation() {
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
  }

  void _startCountdown() {
    final ride = widget.booking['ride'] ?? {};
    final departureDate = ride['departure_date'] ?? '';
    final departureTime = ride['departure_time'] ?? '';

    _countdownHelper.start(
      departureDate: departureDate,
      departureTime: departureTime,
      onUpdate: (duration) {
        if (mounted) {
          setState(() {
            _timeUntilDeparture = duration;
          });
        }
      },
    );
  }

  Future<void> _fetchTrackingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final bookingId = widget.booking['id'];
      final bookingType =
          (widget.booking['booking_type'] ?? 'motor').toString().toLowerCase();

      final data = await ApiService.getBookingTracking(
        bookingId: bookingId,
        token: token,
        bookingType: bookingType,
      );

      // Deteksi gerakan driver
      final location = data['location'];
      if (location != null) {
        final lat = _parseDouble(location['lat']);
        final lng = _parseDouble(location['lng']);
        final speed = _parseDouble(data['speed']) ?? 0.0;

        if (lat != null && lng != null) {
          bool wasMoving = _isDriverMoving;

          // Hitung jarak jika ada posisi sebelumnya
          if (_previousLat != null && _previousLng != null) {
            final distance =
                _calculateDistance(_previousLat!, _previousLng!, lat, lng);
            _isDriverMoving = distance > 10 || speed > 1.0;
          } else {
            _isDriverMoving = speed > 1.0;
          }

          _previousLat = lat;
          _previousLng = lng;
          _lastLocationUpdate = DateTime.now();

          // Restart timer dengan interval baru jika status gerakan berubah
          if (wasMoving != _isDriverMoving) {
            _startPolling();
          }
        }
      }

      setState(() {
        trackingData = data;
        currentStatus = data['status'] ?? widget.booking['status'] ?? 'pending';
      });

      // Auto refresh untuk status aktif (tidak termasuk in_progress karena sudah dihapus)
      if (currentStatus == 'menuju_penjemputan' ||
          currentStatus == 'sudah_di_penjemputan' ||
          currentStatus == 'menuju_tujuan' ||
          currentStatus == 'sudah_sampai_tujuan' ||
          currentStatus == 'paid' ||
          currentStatus == 'confirmed' ||
          currentStatus == 'scheduled') {
        if (_refreshTimer == null || !_refreshTimer!.isActive) {
          _startPolling();
        }
      }
    } catch (e) {
      print('Error fetching tracking: $e');
    }
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    final interval = _isDriverMoving ? _movingInterval : _stationaryInterval;
    _refreshTimer = Timer.periodic(interval, (timer) {
      _fetchTrackingData();
    });
    print(
        '📍 Polling interval: ${interval.inSeconds}s (${_isDriverMoving ? "MOVING" : "STATIONARY"})');
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
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
    // Show different layout based on status
    if (currentStatus == 'menuju_penjemputan') {
      return InProgressLayout(
        booking: widget.booking,
        trackingData: trackingData,
        currentDot: _currentDot,
        isDriverMoving: _isDriverMoving,
        lastLocationUpdate: _lastLocationUpdate,
        currentStatus: currentStatus,
      );
    }

    if (currentStatus == 'sudah_di_penjemputan') {
      return WaitingAtPickupLayout(
        booking: widget.booking,
        trackingData: trackingData,
      );
    }

    if (currentStatus == 'menuju_tujuan') {
      return InProgressLayout(
        booking: widget.booking,
        trackingData: trackingData,
        currentDot: _currentDot,
        isDriverMoving: _isDriverMoving,
        lastLocationUpdate: _lastLocationUpdate,
        currentStatus: currentStatus,
      );
    }

    if (currentStatus == 'sudah_sampai_tujuan') {
      return ArrivedAtDestinationLayout(
        booking: widget.booking,
        trackingData: trackingData,
      );
    }

    return _buildDefaultLayout();
  }

  Widget _buildDefaultLayout() {
    final ride = widget.booking['ride'] ?? {};
    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    final user = widget.booking['user'] ?? {};

    // Determine booking type properties
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

    // Extract ride information
    String rawDate = (ride['departure_date'] ?? '').toString();
    String rawTime = (ride['departure_time'] ?? '').toString();
    final dateOnly = BookingFormatters.formatDateOnly(rawDate);

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
    final pricePerSeat = BookingFormatters.formatPrice(price);
    final totalPrice = BookingFormatters.formatPrice(
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
            // Header Card
            BookingHeader(
              title: title,
              headerIcon: headerIcon,
              accentColor: accentColor,
              currentStatus: currentStatus,
            ),

            // Countdown Section (only for waiting status)
            if (currentStatus == 'paid' || currentStatus == 'confirmed')
              CountdownSection(
                rawDate: rawDate,
                rawTime: rawTime,
                timeUntilDeparture: _timeUntilDeparture,
              ),

            const SizedBox(height: 16),

            // Driver Info Card
            DriverInfoCard(
              driverName: driverName,
              driverPhoto: driverPhoto,
              plateNumber: plate,
              accentColor: accentColor,
            ),

            const SizedBox(height: 16),

            // Route Card
            RouteCard(
              origin: origin,
              destination: destination,
              departureTime: rawTime.split(':').take(2).join(':'),
              dateOnly: dateOnly,
            ),

            const SizedBox(height: 16),

            // Passenger Section
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
              _buildPassengerSection(bookingType, user, accentColor),
              const SizedBox(height: 16),
            ],

            // Price Card
            PriceCard(
              pricePerSeat: pricePerSeat,
              seats: seats,
              totalPrice: totalPrice,
              bookingType: bookingType,
              booking: widget.booking,
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(bookingType),
    );
  }

  Widget _buildPassengerSection(
      String bookingType, Map<String, dynamic> user, Color accentColor) {
    if (bookingType == 'mobil' && allPassengers.isNotEmpty) {
      final currentBookingId = widget.booking['id']?.toString();
      final matchedList = allPassengers
          .where((b) => (b['id']?.toString() == currentBookingId))
          .toList();

      if (matchedList.isEmpty) {
        return PassengerCard(
          name: user['name'] ?? 'Customer',
          accentColor: accentColor,
        );
      }

      final matched = matchedList.first;
      final bookingUser = matched['user'] ?? {};
      final bookingUserName = bookingUser['name'] ?? 'Pemesan';
      final seats = matched['seats'] ?? 1;
      final penumpangList =
          List<Map<String, dynamic>>.from(matched['penumpang'] ?? []);

      return DetailedPassengerCard(
        bookingUserName: bookingUserName,
        seats: seats,
        penumpangList: penumpangList,
        accentColor: accentColor,
      );
    }

    return PassengerCard(
      name: user['name'] ?? 'Customer',
      accentColor: accentColor,
    );
  }

  Widget? _buildBottomNavigationBar(String bookingType) {
    if (bookingType != 'mobil' &&
        bookingType != 'motor' &&
        bookingType != 'barang' &&
        bookingType != 'titip') {
      return null;
    }

    return SafeArea(
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
                    // Tracking sudah tersedia di halaman in_progress
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Tracking lokasi tersedia saat perjalanan berlangsung'),
                        duration: Duration(seconds: 2),
                      ),
                    );
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
    );
  }
}
