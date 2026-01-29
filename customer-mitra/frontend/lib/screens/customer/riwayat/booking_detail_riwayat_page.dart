import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../ubah_jadwal/ubah_jadwal_page.dart';
import '../../../services/api_service.dart';
import '../../../services/chat_service.dart';
import '../../../utils/chat_helper.dart';
import '../messages/chats_page.dart';

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
import 'booking_detail/widgets/rating_card.dart';
import 'booking_detail/widgets/rating_dialog.dart';
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
  bool _driverSourceLogged = false;

  // Rating state
  Map<String, dynamic>? existingRating;
  bool isLoadingRating = false;

  // Chat service
  final ChatService _chatService = ChatService();

  // Mitra data
  Map<String, dynamic>? mitraData;
  bool isLoadingMitra = false;

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
    print('🚀 initState called');
    currentStatus = widget.booking['status'] ?? 'pending';
    print('📞 Calling _fetchMitraData()');
    _fetchMitraData();
    _fetchTrackingData();
    _startCountdown();
    _initDotsAnimation();

    final bookingType =
        (widget.booking['booking_type'] ?? '').toString().toLowerCase();
    if (bookingType == 'mobil') {
      _fetchAllPassengers();
    }

    // Fetch rating if booking is completed
    if (currentStatus == 'completed') {
      _fetchRating();
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

  Future<void> _fetchMitraData() async {
    print('🔥 _fetchMitraData() started');
    try {
      setState(() {
        isLoadingMitra = true;
      });

      final ride = widget.booking['ride'] ?? {};
      final userId = ride['user_id'];

      print('🔍 ride data: $ride');
      print('🔍 user_id from ride: $userId');

      if (userId == null) {
        print('⚠️ user_id tidak ditemukan di ride');
        setState(() {
          isLoadingMitra = false;
        });
        return;
      }

      print('🔍 Fetching mitra data for user_id: $userId');

      // Fetch user data by ID
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print(
            '⚠️ Token tidak ditemukan — akan mencoba fallback dari booking data');

        // Coba ambil nama mitra dari data booking/ride jika tersedia
        final rideFallback = widget.booking['ride'] ?? {};
        final possibleDriver = rideFallback['user'] ??
            rideFallback['mitra'] ??
            widget.booking['mitra'] ??
            {};

        if (possibleDriver != null &&
            possibleDriver is Map &&
            possibleDriver.isNotEmpty) {
          setState(() {
            mitraData = Map<String, dynamic>.from(possibleDriver);
            isLoadingMitra = false;
          });
          print(
              'ℹ️ Menggunakan fallback mitra dari booking: ${mitraData?['name']}');
          return;
        }

        setState(() {
          isLoadingMitra = false;
        });
        return;
      }

      print('🔐 Token found, calling API...');
      final userData = await ApiService.getUserById(userId, token);

      print('📦 Received userData: $userData');

      if (mounted) {
        setState(() {
          mitraData = userData;
          isLoadingMitra = false;
        });
        print('✅ Mitra data loaded: ${userData['name']}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching mitra data: $e');
      print('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          isLoadingMitra = false;
        });
      }
    }
  }

  Future<void> _fetchRating() async {
    setState(() {
      isLoadingRating = true;
    });

    try {
      final bookingId = widget.booking['id'];
      String bookingType =
          (widget.booking['booking_type'] ?? '').toString().toLowerCase();
      if (bookingType.isEmpty) {
        bookingType = 'motor';
      }

      final rating = await ApiService.getRating(
        bookingId: bookingId,
        bookingType: bookingType,
      );

      if (mounted) {
        setState(() {
          existingRating = rating;
          isLoadingRating = false;
        });
      }
    } catch (e) {
      print('Error fetching rating: $e');
      if (mounted) {
        setState(() {
          isLoadingRating = false;
        });
      }
    }
  }

  Future<void> _showRatingDialog() async {
    await showDialog(
      context: context,
      builder: (context) => RatingDialog(
        booking: widget.booking,
        onRatingSubmitted: () {
          _fetchRating();
        },
      ),
    );
  }

  bool _canReschedule() {
    try {
      final ride = widget.booking['ride'] ?? {};
      final departureDate = ride['departure_date'] ?? '';
      final departureTime = ride['departure_time'] ?? '';

      if (departureDate.isEmpty) return false;

      // Parse tanggal dan waktu keberangkatan
      DateTime departureDateTime;
      try {
        // Format: YYYY-MM-DD HH:mm:ss
        if (departureTime.isNotEmpty) {
          final dateTimeParts = departureTime.split(' ');
          final time = dateTimeParts.length > 1 ? dateTimeParts[1] : '00:00:00';
          departureDateTime = DateTime.parse('$departureDate $time');
        } else {
          departureDateTime = DateTime.parse(departureDate);
        }
      } catch (e) {
        // Fallback: coba parse hanya tanggal
        departureDateTime = DateTime.parse(departureDate);
      }

      // Ambil waktu sekarang
      final now = DateTime.now();

      // Hitung selisih waktu
      final difference = departureDateTime.difference(now);

      // Bisa reschedule jika masih lebih dari 24 jam (1 hari)
      return difference.inHours >= 24;
    } catch (e) {
      print('Error checking reschedule eligibility: $e');
      return false;
    }
  }

  Future<void> _onReschedulePressed() async {
    if (!_canReschedule()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Ubah jadwal hanya dapat dilakukan minimal 1x24 jam sebelum keberangkatan'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UbahJadwalPage(booking: widget.booking),
      ),
    );
  }

  Future<void> _onCancelBookingPressed() async {
    // Show cancellation dialog
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return _CancellationDialog(booking: widget.booking);
      },
    );

    if (result == 'cancelled') {
      // Refresh atau kembali ke halaman sebelumnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking berhasil dibatalkan'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    }
  }

  Future<void> _openChatWithDriver() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final userName =
          prefs.getString('user_name') ?? prefs.getString('name') ?? 'Customer';

      if (userId == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User ID tidak ditemukan. Silakan login kembali.')),
        );
        return;
      }

      // Get ride and driver info. Prefer `mitraData` if available.
      final ride = widget.booking['ride'] ?? {};
      final driverFromRide = ride['user'] ?? {};
      final driverData = mitraData ?? driverFromRide;
      final mitraId = driverData['id'];
      final mitraName = driverData['name'] ?? 'Driver';
      final mitraPhoto = driverData['photo_url'] ?? driverData['photo'];
      final rideId = ride['id'] ?? widget.booking['ride_id'];
      final bookingType =
          (widget.booking['booking_type'] ?? 'motor').toString().toLowerCase();

      if (mitraId == null || rideId == null) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data driver tidak lengkap')),
        );
        return;
      }

      // Try to find existing conversation or create new one
      String? conversationId;

      // Check if conversation already exists
      final existingConv = await _chatService.getConversationByRideAndUsers(
        rideId: rideId,
        customerId: userId,
        mitraId: mitraId,
      );

      if (existingConv != null) {
        conversationId = existingConv['id'];
      } else {
        // Create new conversation
        conversationId = await ChatHelper.createConversationAfterBooking(
          rideId: rideId,
          bookingType: bookingType,
          customerData: {
            'id': userId,
            'name': userName,
            'photo': prefs.getString('photo_url'),
          },
          mitraData: {
            'id': mitraId,
            'name': mitraName,
            'photo': mitraPhoto,
          },
        );
      }

      Navigator.pop(context); // Close loading

      if (conversationId != null && conversationId.isNotEmpty) {
        // Navigate to chat page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: conversationId!,
              otherUserName: mitraName,
              otherUserPhoto: mitraPhoto,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka chat')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      print('Error opening chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka chat: $e')),
      );
    }
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
        mitraData: mitraData,
        onChatPressed: _openChatWithDriver,
      );
    }

    if (currentStatus == 'sudah_di_penjemputan') {
      return WaitingAtPickupLayout(
        booking: widget.booking,
        trackingData: trackingData,
        mitraData: mitraData,
        onChatPressed: _openChatWithDriver,
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
        mitraData: mitraData,
        onChatPressed: _openChatWithDriver,
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

    // Use mitraData if available, otherwise prefer ride['mitra'] or ride['user'].
    // Do NOT fallback to booking['user'] (that's the customer).
    final driver = mitraData ?? ride['mitra'] ?? ride['user'] ?? {};
    final driverName = driver['name'] ?? 'Driver';
    final driverPhoto = driver['photo_url'] ?? driver['photo'] ?? '';
    final driverRatingSummary = ride['driver_rating_summary'] ?? {};
    final averageRating = driverRatingSummary['average_rating'] is num
        ? (driverRatingSummary['average_rating'] as num).toDouble()
        : null;
    final totalRatings = driverRatingSummary['total_ratings'] is int
        ? driverRatingSummary['total_ratings'] as int
        : (driverRatingSummary['total_ratings'] is num
            ? (driverRatingSummary['total_ratings'] as num).toInt()
            : null);

    // Debug: log driver source once
    if (!_driverSourceLogged) {
      _driverSourceLogged = true;
      try {
        if (mitraData != null) {
          print('🔎 Driver source: mitraData loaded -> ${mitraData?['name']}');
        } else if (ride['mitra'] != null) {
          print('🔎 Driver source: ride["mitra"] -> ${ride['mitra']?['name']}');
        } else if (ride['user'] != null) {
          print('🔎 Driver source: ride["user"] -> ${ride['user']?['name']}');
        } else {
          print('🔎 Driver source: none, showing fallback');
        }
      } catch (e) {
        print('🔎 Error logging driver source: $e');
      }
    }

    // Debug log
    // print('📊 Rendering UI:');
    // print('   mitraData: $mitraData');
    // print('   isLoadingMitra: $isLoadingMitra');
    // print('   driverName: $driverName');
    // print('   driverPhoto: $driverPhoto');

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
              mitraName: driverName,
              accentColor: accentColor,
              averageRating: averageRating,
              totalRatings: totalRatings,
              onChatPressed: _openChatWithDriver,
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

            // Tombol Ubah Jadwal dan Batalkan Booking
            if ((bookingType == 'mobil' ||
                    bookingType == 'motor' ||
                    bookingType == 'barang' ||
                    bookingType == 'titip') &&
                _canReschedule() &&
                currentStatus != 'dibatalkan' &&
                currentStatus != 'cancelled') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Tombol Ubah Jadwal
                    SizedBox(
                      height: 52,
                      width: double.infinity,
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
                    const SizedBox(height: 12),
                    // Tombol Batalkan Booking
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _onCancelBookingPressed,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 2,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batalkan Booking',
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

            const SizedBox(height: 16),

            // Rating Card (only show for completed bookings)
            if (currentStatus == 'completed') ...[
              if (isLoadingRating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                RatingCard(
                  existingRating: existingRating,
                  onRatePressed: _showRatingDialog,
                  driverName: driverName,
                ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
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
}

// Cancellation Dialog Widget
class _CancellationDialog extends StatefulWidget {
  final Map<String, dynamic> booking;

  const _CancellationDialog({required this.booking});

  @override
  State<_CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<_CancellationDialog> {
  String? selectedReason;
  bool isLoading = false;
  int cancellationCount = 0;

  final List<String> cancellationReasons = [
    'Bencana Alam',
    'Kendaraan Rusak',
    'Masalah Kesehatan Pribadi',
    'Kebutuhan Mendesak yang Tidak Terduga',
    'Alasan Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCancellationCount();
  }

  Future<void> _fetchCancellationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        final response = await ApiService.getCancellationCount(userId);
        if (mounted) {
          setState(() {
            cancellationCount = response['count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error fetching cancellation count: $e');
    }
  }

  Future<void> _cancelBooking() async {
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih alasan pembatalan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pembatalan pada bulan ini: $cancellationCount/3',
                    style: const TextStyle(
                      color: Color(0xFF0F4AA3),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Anda telah membatalkan tebengan ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Harap diperhatikan bahwa jika Anda melakukan lebih dari 3 pembatalan dalam satu bulan, akun Anda akan otomatis diblokir sementara dari layanan kami. Apakah Anda yakin ingin melanjutkan pembatalan ini?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Batalkan tebengan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0F4AA3)),
                          foregroundColor: const Color(0xFF0F4AA3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      final bookingId = widget.booking['id'];
      await ApiService.cancelBooking(bookingId, selectedReason!);

      if (mounted) {
        Navigator.pop(context, 'cancelled');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan booking: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Pembatalan Tebengan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan alasan pembatalan tebengan Anda!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reason options
                  ...cancellationReasons.map((reason) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedReason = reason;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selectedReason == reason
                                  ? const Color(0xFF0F4AA3)
                                  : Colors.grey[300]!,
                              width: selectedReason == reason ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selectedReason == reason
                                        ? const Color(0xFF0F4AA3)
                                        : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: selectedReason == reason
                                    ? Center(
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF0F4AA3),
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: selectedReason == reason
                                        ? Colors.black87
                                        : Colors.grey[700],
                                    fontWeight: selectedReason == reason
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Footer buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _cancelBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Batalkan tebengan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F4AA3)),
                      foregroundColor: const Color(0xFF0F4AA3),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali',
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
        ],
      ),
    );
  }
}
