import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../messages/chat_detail_page.dart';
import '../mitra_tracking_map/models/tracking_state.dart';
import '../mitra_tracking_map/services/tracking_service.dart';
import '../mitra_tracking_map/utils/tracking_helpers.dart';
import '../mitra_tracking_map/utils/persistence_helper.dart';
import '../mitra_tracking_map/widgets/tracking_map_widget.dart';
import '../mitra_tracking_map/widgets/qr_only_screen.dart';
import '../mitra_tracking_map/widgets/customer_rating_screen.dart';
import '../mitra_tracking_map/widgets/info_card_widgets.dart';
import '../mitra_tracking_map/widgets/overlay_widgets.dart';
import 'widgets/detail_tebengan_scaffold.dart';
import 'services/rating_service.dart';
import 'services/status_service.dart';
import 'services/vehicle_info_extractor.dart';
import 'services/formatting_helper.dart';
import 'cancellation_page.dart';
import '../../../utils/chat_helper.dart';
import '../../../services/api_service.dart';

class MitraTebenganDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MitraTebenganDetailPage({Key? key, required this.item})
      : super(key: key);

  @override
  State<MitraTebenganDetailPage> createState() =>
      _MitraTebenganDetailPageState();
}

class _MitraTebenganDetailPageState extends State<MitraTebenganDetailPage> {
  // Rating state
  bool _isCheckingRating = true;
  bool _hasRating = false;
  int _selectedRating = 0;
  final Set<String> _selectedFeedback = {};
  File? _proofImage;
  bool _isSubmittingRating = false;

  final List<String> _feedbackOptions = [
    'Tidak jemput sesuai',
    'Ramah banget!',
    'Tepat Waktu',
  ];

  // Tracking state
  late TrackingState _state;
  late TrackingService _trackingService;
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    print('🔍 widget.item structure: ${jsonEncode(widget.item)}');
    _checkExistingRating();

    // Initialize tracking state
    _state = TrackingState();
    _trackingService = TrackingService();
    _initializeTracking();
    _startStatusRefreshTimer();
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    _state.dispose();
    super.dispose();
  }

  Future<void> _checkExistingRating() async {
    final bookingNumber = widget.item['booking_number'] as String?;
    final hasRating = await RatingService.checkExistingRating(bookingNumber);
    if (mounted) {
      setState(() {
        _hasRating = hasRating;
        _isCheckingRating = false;
      });
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih rating terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmittingRating = true);

    try {
      final bookingNumber = widget.item['booking_number'] as String?;
      if (bookingNumber == null) {
        throw Exception('Booking number tidak ditemukan');
      }

      final customerId = widget.item['customer']?['id'] as int? ?? 0;
      if (customerId == 0) {
        throw Exception('Customer ID tidak ditemukan');
      }

      await RatingService.submitRating(
        bookingNumber: bookingNumber,
        customerId: customerId,
        rating: _selectedRating,
        feedback: _selectedFeedback,
        proofImage: _proofImage,
      );

      if (mounted) {
        setState(() {
          _hasRating = true;
          _isSubmittingRating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating berhasil dikirim'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _proofImage = File(image.path);
      });
    }
  }

  // ==================== TRACKING METHODS ====================

  Future<void> _initializeTracking() async {
    _state.bookingType = BookingTypeHelper.detectBookingType(widget.item);
    _state.avoidTolls = _state.bookingType == 'motor';

    final locations = LocationHelper.extractOriginDestination(widget.item);
    _state.originLatLng = locations['origin'];
    _state.destinationLatLng = locations['destination'];

    await _fetchMainRoute();
    _startCountdownTimer();
    await _loadPersistentState();
    await _refreshStatusFromServer();
  }

  Future<void> _refreshStatusFromServer() async {
    try {
      final currentStatus = _getCurrentStatus();
      if (_isFinalStatus(currentStatus)) {
        _statusRefreshTimer?.cancel();
        return;
      }

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      try {
        final booking = await _trackingService.fetchBooking(
          bookingId: bookingId,
          token: token,
        );
        final status = (booking['status'] ?? '').toString().toLowerCase();

        if (status != currentStatus && mounted) {
          setState(() {
            if (widget.item['ride'] is Map) {
              widget.item['ride']['status'] = status;
            }
          });
          if (_isFinalStatus(status)) {
            _statusRefreshTimer?.cancel();
          }
        }
      } catch (e) {
        // Handle errors silently
      }
    } catch (e) {
      // Ignore
    }
  }

  void _startStatusRefreshTimer() {
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshStatusFromServer();
    });
  }

  String _getCurrentStatus() {
    return StatusService.getCurrentStatus(widget.item);
  }

  bool _isFinalStatus(String status) {
    return StatusService.isFinalStatus(status);
  }

  void _startCountdownTimer() {
    final ride = Map<String, dynamic>.from(widget.item['ride'] ?? {});
    final departureDate = ride['departure_date'];
    final departureTime = ride['departure_time'];

    if (departureDate == null || departureTime == null) {
      setState(() {
        _state.isDepartureReady = true;
      });
      return;
    }

    try {
      DateTime departureDateTime;
      String dateStr = departureDate.toString();
      String timeStr = departureTime.toString();

      final dateParts = dateStr.split('-');
      final timeParts = timeStr.split(':');
      if (dateParts.length >= 3 && timeParts.length >= 2) {
        departureDateTime = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          timeParts.length >= 3 ? int.parse(timeParts[2].split('.')[0]) : 0,
        );
      } else {
        throw FormatException('Invalid date/time');
      }

      final initialDifference = departureDateTime.difference(DateTime.now());

      if (initialDifference.isNegative || initialDifference.inSeconds <= 0) {
        setState(() {
          _state.timeUntilDeparture = Duration.zero;
          _state.isDepartureReady = true;
        });
        return;
      } else {
        setState(() {
          _state.timeUntilDeparture = initialDifference;
          _state.isDepartureReady = false;
        });
      }

      _state.countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = departureDateTime.difference(now);

        if (difference.isNegative || difference.inSeconds <= 0) {
          setState(() {
            _state.timeUntilDeparture = Duration.zero;
            _state.isDepartureReady = true;
          });
          timer.cancel();
        } else {
          setState(() {
            _state.timeUntilDeparture = difference;
            _state.isDepartureReady = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _state.isDepartureReady = true;
        _state.timeUntilDeparture = null;
      });
    }
  }

  Future<void> _fetchMainRoute() async {
    if (_state.originLatLng == null || _state.destinationLatLng == null) return;

    final points = await _trackingService.fetchRoute(
      _state.originLatLng!,
      _state.destinationLatLng!,
    );

    if (mounted) {
      setState(() {
        _state.mainRoute = points;
      });
    }
  }

  Future<void> _fetchRouteToOrigin() async {
    if (_state.lastPosition == null || _state.originLatLng == null) return;

    final currentPos = LatLng(
      _state.lastPosition!.latitude,
      _state.lastPosition!.longitude,
    );

    final points = await _trackingService.fetchRoute(
      currentPos,
      _state.originLatLng!,
    );

    if (mounted) {
      setState(() {
        _state.routeToOrigin = points;
      });
    }
  }

  Future<void> _fetchRouteToDestination() async {
    if (_state.lastPosition == null || _state.destinationLatLng == null) return;

    final currentPos = LatLng(
      _state.lastPosition!.latitude,
      _state.lastPosition!.longitude,
    );

    final points = await _trackingService.fetchRoute(
      currentPos,
      _state.destinationLatLng!,
    );

    if (mounted) {
      setState(() {
        _state.routeToDestination = points;
        _state.routeToOrigin = [];
      });
    }
  }

  Future<void> _startLocationTracking() async {
    if (!await _trackingService.checkLocationPermissions()) return;

    setState(() => _state.isTracking = true);

    final bookingId = await _resolveBookingId();
    if (bookingId != null) {
      await PersistenceHelper.savePersistentTracking(bookingId, true);
    }

    _sendLocationUpdate();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _state.locationTimer?.cancel();
    final interval = _state.isMoving
        ? const Duration(seconds: 5)
        : const Duration(minutes: 1);
    _state.locationTimer = Timer.periodic(
      interval,
      (_) => _sendLocationUpdate(),
    );
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final position = await _trackingService.getCurrentPosition();
      if (position == null) return;

      if (_state.lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _state.lastPosition!.latitude,
          _state.lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final wasMoving = _state.isMoving;
        _state.isMoving = distance >= 0.2;

        if (wasMoving != _state.isMoving) {
          _startPeriodicUpdate();
        }
      }

      final newPoint = LatLng(position.latitude, position.longitude);
      _state.routePoints.add(newPoint);
      _state.mapController.move(newPoint, 15.0);
      _state.lastPosition = position;

      final bookingId = await _resolveBookingId();
      if (bookingId != null) {
        await PersistenceHelper.saveLastPosition(
          bookingId,
          position.latitude,
          position.longitude,
        );

        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('api_token');
        if (token != null) {
          await _trackingService.updateBookingLocation(
            bookingId: bookingId,
            token: token,
            lat: position.latitude,
            lng: position.longitude,
            timestamp: DateTime.now(),
            accuracy: position.accuracy,
            speed: position.speed,
            bookingType: _state.bookingType,
          );
        }
      }

      // Auto-detect arrival
      final status = _getCurrentStatus();
      if (status == 'menuju_penjemputan' && _state.originLatLng != null) {
        final distanceToOrigin = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _state.originLatLng!.latitude,
          _state.originLatLng!.longitude,
        );
        if (distanceToOrigin <= 50.0) {
          await _markSudahDiPenjemputan();
        }
      }

      if (status == 'menuju_tujuan' && _state.destinationLatLng != null) {
        final distanceToDestination = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _state.destinationLatLng!.latitude,
          _state.destinationLatLng!.longitude,
        );
        if (distanceToDestination <= 50.0) {
          await _markSudahSampaiTujuan();
        }
      }

      if (mounted) setState(() {});

      if (status == 'menuju_penjemputan') {
        _fetchRouteToOrigin();
      } else if (status == 'menuju_tujuan') {
        _fetchRouteToDestination();
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadPersistentState() async {
    try {
      final bookingId = await _resolveBookingId();
      if (bookingId == null) {
        setState(() => _state.isLoadingState = false);
        return;
      }

      final persisted = await PersistenceHelper.loadPersistedState(bookingId);

      if (persisted['lat'] != null && persisted['lng'] != null) {
        _state.lastPosition = Position(
          longitude: persisted['lng'],
          latitude: persisted['lat'],
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token != null) {
        try {
          final booking = await _trackingService.fetchBooking(
            bookingId: bookingId,
            token: token,
          );
          final status = (booking['status'] ?? '').toString().toLowerCase();

          if (mounted) {
            setState(() {
              if (widget.item['ride'] is Map) {
                widget.item['ride']['status'] = status;
              }
            });
          }

          if (status == 'menuju_penjemputan') {
            await _startLocationTracking();
            await _fetchRouteToOrigin();
          } else if (status == 'sudah_di_penjemputan') {
            final arrivalMillis = persisted['arrivalMillis'];
            if (arrivalMillis != null) {
              _restorePickupTimer(arrivalMillis);
            }
          } else if (status == 'menuju_tujuan') {
            await _startLocationTracking();
            await _fetchRouteToDestination();
          } else if (status == 'sudah_sampai_tujuan' || status == 'completed') {
            await PersistenceHelper.clearPersistentTracking(bookingId);
          }
        } catch (e) {
          // Handle errors
        }
      }

      if (mounted) {
        setState(() => _state.isLoadingState = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state.isLoadingState = false);
      }
    }
  }

  void _restorePickupTimer(int arrivalMillis) {
    final arrivedAt = DateTime.fromMillisecondsSinceEpoch(arrivalMillis);
    final elapsed = DateTime.now().difference(arrivedAt);
    final remaining = _state.pickupWait - elapsed;

    if (remaining <= Duration.zero) {
      setState(() {
        _state.isAtPickup = true;
        _state.pickupRemaining = Duration.zero;
        _state.canCancelPickup = true;
      });
    } else {
      setState(() {
        _state.isAtPickup = true;
        _state.pickupRemaining = remaining;
        _state.canCancelPickup = false;
      });
      _startPickupTimerWithRemaining(remaining);
    }
  }

  void _startPickupTimerWithRemaining(Duration remaining) {
    _state.pickupTimer?.cancel();
    setState(() {
      _state.pickupRemaining = remaining;
      _state.canCancelPickup = remaining <= Duration.zero;
    });
    if (remaining <= Duration.zero) return;

    _state.pickupTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        final newSec = _state.pickupRemaining.inSeconds - 1;
        if (newSec <= 0) {
          _state.pickupRemaining = Duration.zero;
          _state.canCancelPickup = true;
          _state.pickupTimer?.cancel();
        } else {
          _state.pickupRemaining = Duration(seconds: newSec);
        }
      });
    });
  }

  Future<int?> _resolveBookingId() async {
    return await _trackingService.resolveBookingId(
      widget.item,
      _state.bookingType,
    );
  }

  Future<Map<String, dynamic>> _getBookingDetails() async {
    final bookingId = await _resolveBookingId();
    if (bookingId == null) {
      throw Exception('Booking ID tidak ditemukan');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    try {
      final booking = await _trackingService.fetchBooking(
        bookingId: bookingId,
        token: token,
      );

      final customerId = booking['user_id'] as int? ?? 0;
      if (customerId == 0) {
        throw Exception('Customer ID tidak ditemukan di booking');
      }

      return {
        'booking_id': bookingId,
        'customer_id': customerId,
      };
    } catch (e) {
      throw Exception('Tidak dapat menemukan data booking');
    }
  }

  Future<void> _markMenujuPenjemputan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'menuju_penjemputan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'menuju_penjemputan';
        }
      });

      await _fetchRouteToOrigin();
      await _startLocationTracking();
      await PersistenceHelper.savePersistentTracking(bookingId, true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status diupdate: Menuju titik jemput')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _markSudahDiPenjemputan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'sudah_di_penjemputan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'sudah_di_penjemputan';
        }
        _state.routeToOrigin = [];
      });

      await PersistenceHelper.savePickupArrival(
        bookingId,
        DateTime.now().millisecondsSinceEpoch,
      );
      _startPickupTimerWithRemaining(const Duration(minutes: 15));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sudah di titik penjemputan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _markMenujuTujuan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'menuju_tujuan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'menuju_tujuan';
        }
      });

      await _startLocationTracking();
      await _fetchRouteToDestination();
      await PersistenceHelper.savePersistentTracking(bookingId, false);
      await PersistenceHelper.saveEnRouteToDestination(bookingId, true);
      await PersistenceHelper.clearPickupArrival(bookingId);
      _state.pickupTimer?.cancel();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menuju titik tujuan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _markSudahSampaiTujuan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'sudah_sampai_tujuan',
        token: token,
      );

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'sudah_sampai_tujuan';
        }
        _state.routeToDestination = [];
      });

      await PersistenceHelper.clearPersistentTracking(bookingId);
      await PersistenceHelper.saveEnRouteToDestination(bookingId, false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tebengan selesai! Sudah sampai tujuan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update status: $e')),
        );
      }
    }
  }

  Future<void> _cancelPickup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;

      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await _trackingService.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
        token: token,
      );

      _state.pickupTimer?.cancel();
      await PersistenceHelper.clearPersistentTracking(bookingId);
      await PersistenceHelper.clearPickupArrival(bookingId);

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'cancelled';
        }
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membatalkan tebengan: $e')),
        );
      }
    }
  }

  Future<void> _cancelRide() async {
    // Get cancellation count first
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('api_token');

    if (userId == null || token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User tidak terautentikasi')),
        );
      }
      return;
    }

    int cancellationCount = 0;
    try {
      final countData = await ApiService.getMitraCancellationCount(
        mitraId: userId,
        token: token,
      );
      cancellationCount = countData['count'] ?? 0;
    } catch (e) {
      print('Error getting cancellation count: $e');
    }

    // Navigate to cancellation page
    final reason = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CancellationPage(
          cancellationCount: cancellationCount,
        ),
      ),
    );

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      final ride = Map<String, dynamic>.from(widget.item['ride'] ?? {});
      final rideId = ride['id'] as int?;
      if (rideId == null) {
        throw Exception('Ride ID tidak ditemukan');
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      await ApiService.cancelRide(
        rideId: rideId,
        rideType: _state.bookingType,
        cancellationReason: reason.trim(),
        token: token,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      setState(() {
        if (widget.item['ride'] is Map) {
          widget.item['ride']['status'] = 'cancelled';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tebengan berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
        // Return to previous page
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membatalkan tebengan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openChatWithCustomer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mitraId = prefs.getInt('user_id');
      final mitraName =
          prefs.getString('user_name') ?? prefs.getString('name') ?? 'Mitra';

      if (mitraId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan')),
        );
        return;
      }

      final ride = Map<String, dynamic>.from(widget.item['ride'] ?? {});
      final rideId = ride['id'] as int?;
      final customerId = widget.item['user_id'] as int?;

      if (rideId == null || customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data booking tidak lengkap')),
        );
        return;
      }

      final existingConv =
          await _state.chatService.getConversationByRideAndUsers(
        rideId: rideId,
        customerId: customerId,
        mitraId: mitraId,
      );

      String conversationId;
      if (existingConv != null) {
        conversationId = existingConv['id'] as String;
      } else {
        final customerName = widget.item['user_name'] as String? ?? 'Customer';
        final customerPhoto = widget.item['user_photo'] as String?;
        final customerPhone = widget.item['user_phone'] as String? ?? '';
        final mitraPhone = prefs.getString('phone') ?? '';

        final newConvId = await ChatHelper.createConversationAfterBooking(
          rideId: rideId,
          bookingType: _state.bookingType,
          customerData: {
            'id': customerId,
            'name': customerName,
            'photo': customerPhoto,
            'phone': customerPhone,
          },
          mitraData: {
            'id': mitraId,
            'name': mitraName,
            'photo': null,
            'phone': mitraPhone,
          },
        );

        if (newConvId == null) {
          throw Exception('Failed to create conversation');
        }

        conversationId = newConvId;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MitraChatDetailPage(
              conversationId: conversationId,
              otherUserName: widget.item['user_name'] as String? ?? 'Customer',
              otherUserPhoto: widget.item['user_photo'] as String?,
              bookingType: _state.bookingType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka chat: $e')),
        );
      }
    }
  }

  Future<void> _openChatWithBookingCustomer(
      Map<String, dynamic>? booking) async {
    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data booking tidak tersedia')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final mitraId = prefs.getInt('user_id');
      final mitraName =
          prefs.getString('user_name') ?? prefs.getString('name') ?? 'Mitra';

      if (mitraId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID tidak ditemukan')),
        );
        return;
      }

      final ride = Map<String, dynamic>.from(widget.item['ride'] ?? {});
      final rideId = ride['id'] as int?;
      final customerData = booking['user'] as Map<String, dynamic>?;
      final customerId = customerData?['id'] as int?;

      if (rideId == null || customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data booking tidak lengkap')),
        );
        return;
      }

      final existingConv =
          await _state.chatService.getConversationByRideAndUsers(
        rideId: rideId,
        customerId: customerId,
        mitraId: mitraId,
      );

      String conversationId;
      if (existingConv != null) {
        conversationId = existingConv['id'] as String;
      } else {
        final customerName = customerData?['name'] as String? ?? 'Customer';
        final customerPhoto = customerData?['profile_photo'] as String?;
        final customerPhone = customerData?['phone'] as String? ?? '';
        final mitraPhone = prefs.getString('phone') ?? '';

        final newConvId = await ChatHelper.createConversationAfterBooking(
          rideId: rideId,
          bookingType: _state.bookingType,
          customerData: {
            'id': customerId,
            'name': customerName,
            'photo': customerPhoto,
            'phone': customerPhone,
          },
          mitraData: {
            'id': mitraId,
            'name': mitraName,
            'photo': null,
            'phone': mitraPhone,
          },
        );

        if (newConvId == null) {
          throw Exception('Failed to create conversation');
        }

        conversationId = newConvId;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MitraChatDetailPage(
              conversationId: conversationId,
              otherUserName: customerData?['name'] as String? ?? 'Customer',
              otherUserPhoto: customerData?['profile_photo'] as String?,
              bookingType: _state.bookingType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka chat: $e')),
        );
      }
    }
  }

  String _formatPrice(dynamic price) {
    return FormattingHelper.formatPrice(price);
  }

  String _formatDateTime(String dateStr, String timeStr) {
    return FormattingHelper.formatDateTime(dateStr, timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final status = _getCurrentStatus();

    // Show rating screen when completed/selesai
    if (status == 'completed' || status == 'selesai') {
      return FutureBuilder<Map<String, dynamic>>(
        future: _getBookingDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildDetailView(); // Fallback to detail view
          }

          final bookingData = snapshot.data!;
          final bookingId = bookingData['booking_id'] as int;
          final customerId = bookingData['customer_id'] as int;

          return CustomerRatingScreen(
            bookingNumber: BookingInfoHelper.getBookingNumber(widget.item),
            customerName: BookingInfoHelper.getCustomerName(widget.item),
            totalFare: BookingInfoHelper.getTotalFare(widget.item),
            bookingId: bookingId,
            customerId: customerId,
          );
        },
      );
    }

    // Show QR only screen when sudah_sampai_tujuan
    if (status == 'sudah_sampai_tujuan') {
      return QROnlyScreen(
        qrCodeData: BookingInfoHelper.getQRCodeData(widget.item),
        bookingNumber: BookingInfoHelper.getBookingNumber(widget.item),
      );
    }

    // Show tracking map view for active statuses
    if (_shouldShowTrackingView(status)) {
      return _buildTrackingView(status);
    }

    // Default: Show detail view for 'paid' and other statuses
    return _buildDetailView();
  }

  bool _shouldShowTrackingView(String status) {
    return status == 'menuju_penjemputan' ||
        status == 'sudah_di_penjemputan' ||
        status == 'menuju_tujuan';
  }

  Widget _buildTrackingView(String status) {
    final originInfo = BookingInfoHelper.getOriginInfo(widget.item);
    final customerName = BookingInfoHelper.getCustomerName(widget.item);
    final bookingNumber = BookingInfoHelper.getBookingNumber(widget.item);

    return Scaffold(
      body: Stack(
        children: [
          TrackingMapWidget(
            mapController: _state.mapController,
            lastPosition: _state.lastPosition,
            originLatLng: _state.originLatLng,
            destinationLatLng: _state.destinationLatLng,
            routePoints: _state.routePoints,
            routeToOrigin: _state.routeToOrigin,
            mainRoute: _state.mainRoute,
            routeToDestination: _state.routeToDestination,
            currentStatus: status,
          ),
          TopMessageButton(onPressed: _openChatWithCustomer),
          BackButtonOverlay(onPressed: () => Navigator.pop(context)),
          if (_state.bookingType == 'mobil')
            TollToggleButton(
              avoidTolls: _state.avoidTolls,
              onToggle: () {
                setState(() => _state.avoidTolls = !_state.avoidTolls);
                if (status == 'menuju_penjemputan') {
                  _fetchRouteToOrigin();
                } else if (status == 'menuju_tujuan') {
                  _fetchRouteToDestination();
                }
              },
            ),
          if (_state.timeUntilDeparture != null)
            CountdownTimerOverlay(
              timeUntilDeparture: _state.timeUntilDeparture,
              isDepartureReady: _state.isDepartureReady,
              formatCountdown: FormatHelper.formatCountdown,
            ),
          BottomInfoCard(
            bookingNumber: bookingNumber,
            customerName: customerName,
            originName: originInfo['name']!,
            originAddress: originInfo['address']!,
            onCallPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Fitur telepon akan segera tersedia')),
              );
            },
            onMessagePressed: _openChatWithCustomer,
            statusUI: _buildStatusUI(status),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUI(String status) {
    if (_state.isLoadingState) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
              const SizedBox(height: 12),
              Text(
                'Memuat status tebengan...',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (status == 'menuju_penjemputan') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Menuju titik penjemputan...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (status == 'sudah_di_penjemputan') {
      return PickupWaitingCard(
        pickupRemaining: _state.pickupRemaining,
        canCancelPickup: _state.canCancelPickup,
        onContactCustomer: _openChatWithCustomer,
        onContinue: () async {
          _state.pickupTimer?.cancel();
          final bookingId = await _resolveBookingId();
          if (bookingId != null) {
            await PersistenceHelper.clearPickupArrival(bookingId);
          }
          await _markMenujuTujuan();
        },
        onCancel: _cancelPickup,
      );
    }

    if (status == 'menuju_tujuan') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Menuju titik tujuan...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ActionButton(
      isDepartureReady: _state.isDepartureReady,
      onPressed: _markMenujuPenjemputan,
    );
  }

  Widget _buildDetailView() {
    final ride = Map<String, dynamic>.from(widget.item['ride'] ?? {});

    final originLocation = ride['origin_location'] is Map
        ? Map<String, dynamic>.from(ride['origin_location'] as Map)
        : <String, dynamic>{};
    final origin = originLocation['name'] ?? '';

    final destinationLocation = ride['destination_location'] is Map
        ? Map<String, dynamic>.from(ride['destination_location'] as Map)
        : <String, dynamic>{};
    final destination = destinationLocation['name'] ?? '';

    final date = ride['departure_date'] ?? '';
    final time = ride['departure_time'] ?? '';
    final kode = ride['code'] ??
        ride['ride_code'] ??
        ride['booking_code'] ??
        widget.item['code'] ??
        widget.item['booking_number'] ??
        '';

    // Debug logging
    print('DEBUG date: $date');
    print('DEBUG time: $time');
    print('DEBUG kode: $kode');

    final headerDate = _formatDateTime(date.toString(), time.toString());
    print('DEBUG headerDate result: $headerDate');

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
    } else if (status == 'paid') {
      statusLabel = 'Dibayar';
      statusBgColor = const Color(0xFFD1FAE5);
    }

    final income = (widget.item['income'] ?? 0);
    final incomeLabel =
        (status.contains('completed')) ? 'Pendapatan' : 'Estimasi Pendapatan';

    // Extract vehicle info
    final vehicleInfo = VehicleInfoExtractor.extractVehicleInfo(widget.item);
    final rideType = (widget.item['type'] ?? '').toString().toLowerCase();

    return DetailTebenganScaffold(
      item: widget.item,
      state: _state,
      headerDate: headerDate,
      kode: kode,
      statusLabel: statusLabel,
      statusBgColor: statusBgColor,
      origin: origin,
      destination: destination,
      incomeLabel: incomeLabel,
      income: income,
      formatPrice: _formatPrice,
      ownerName: vehicleInfo['ownerName']!,
      transportasi: vehicleInfo['transportasi']!,
      plat: vehicleInfo['plat']!,
      vehicleModel: vehicleInfo['vehicleModel']!,
      warna: vehicleInfo['warna']!,
      kursi: vehicleInfo['kursi']!,
      rideType: rideType,
      ride: ride,
      onMarkMenujuPenjemputan: _markMenujuPenjemputan,
      onChatPressed: _openChatWithBookingCustomer,
      onCancelRide: _cancelRide,
      isCheckingRating: _isCheckingRating,
      hasRating: _hasRating,
      selectedRating: _selectedRating,
      selectedFeedback: _selectedFeedback,
      proofImage: _proofImage,
      isSubmittingRating: _isSubmittingRating,
      customerName: widget.item['customer_name'] as String? ?? 'Customer',
      feedbackOptions: _feedbackOptions,
      onRatingChanged: (rating) => setState(() => _selectedRating = rating),
      onFeedbackToggled: (option) {
        setState(() {
          if (_selectedFeedback.contains(option)) {
            _selectedFeedback.remove(option);
          } else {
            _selectedFeedback.add(option);
          }
        });
      },
      onPickImage: _pickImage,
      onSubmitRating: _submitRating,
      currentStatus: _getCurrentStatus(),
    );
  }
}
