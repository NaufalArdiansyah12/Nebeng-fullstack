import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/chat_service.dart';
import '../../utils/chat_helper.dart';
import 'messages/chat_detail_page.dart';

class MitraTrackingMapPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MitraTrackingMapPage({Key? key, required this.item}) : super(key: key);

  @override
  State<MitraTrackingMapPage> createState() => _MitraTrackingMapPageState();
}

class _MitraTrackingMapPageState extends State<MitraTrackingMapPage> {
  // Controllers & Services
  final MapController _mapController = MapController();
  final ChatService _chatService = ChatService();

  // Location & Tracking State
  Timer? _locationTimer;
  Timer? _countdownTimer;
  Timer? _pickupTimer;
  Position? _lastPosition;
  bool _isTracking = false;
  bool _isMoving = false;

  // Persistent tracking & pickup state
  bool _menujuActive = false; // true after pressing "menuju titik jemput"
  bool _isAtPickup = false; // true when arrived at pickup
  bool _pickedUp = false; // true after passenger picked up
  Duration _pickupWait = const Duration(minutes: 15);
  Duration _pickupRemaining = const Duration(minutes: 15);
  bool _canCancelPickup = false;

  // Countdown state
  Duration? _timeUntilDeparture;
  bool _isDepartureReady = false;

  // Route Data
  final List<LatLng> _routePoints = [];
  List<LatLng> _routeToOrigin = [];
  List<LatLng> _mainRoute = [];

  // Location Data
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  // Booking Info
  String _bookingType = 'motor';

  // API Config
  final String baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    _detectBookingType();
    _extractOriginDestination();
    _fetchMainRoute();
    _startCountdownTimer();
    _loadPersistentState();
    // Tracking will start only when driver clicks button
    // _checkAndStartTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _countdownTimer?.cancel();
    _pickupTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ==================== BOOKING TYPE DETECTION ====================

  void _detectBookingType() {
    final itemType = (widget.item['type'] ?? '').toString().toLowerCase();
    final ride = widget.item['ride'] ?? {};
    final mitraVehicle = ride['kendaraan_mitra'] ?? {};
    final rawType = (mitraVehicle['type'] ??
            mitraVehicle['vehicle_type'] ??
            mitraVehicle['transportation'] ??
            '')
        .toString()
        .toLowerCase();
    final serviceType = (ride['service_type'] ?? '').toString().toLowerCase();
    final rideType = (ride['ride_type'] ?? '').toString().toLowerCase();

    // Priority 1: Check item type (from mitra history)
    if (itemType.contains('titip')) {
      _bookingType = 'titip';
    } else if (itemType.contains('barang') && !itemType.contains('titip')) {
      _bookingType = 'barang';
    } else if (itemType.contains('mobil') || itemType.contains('car')) {
      _bookingType = 'mobil';
    } else if (itemType.contains('motor')) {
      _bookingType = 'motor';
    }
    // Priority 2: Check service/ride type
    else if (serviceType.contains('titip') || rideType.contains('titip')) {
      _bookingType = 'titip';
    } else if (serviceType.contains('barang') || rideType.contains('barang')) {
      _bookingType = 'barang';
    }
    // Priority 3: Check vehicle type
    else if (rawType.contains('mobil') ||
        rawType.contains('car') ||
        serviceType.contains('mobil') ||
        serviceType.contains('car')) {
      _bookingType = 'mobil';
    } else {
      _bookingType = 'motor';
    }
  }

  // ==================== LOCATION PARSING ====================

  LatLng? _parseLatLng(dynamic loc) {
    if (loc == null || loc is! Map) return null;

    final latCandidates = [loc['lat'], loc['latitude']];
    final lngCandidates = [loc['lng'], loc['longitude'], loc['long']];

    double? lat;
    double? lng;

    for (final v in latCandidates) {
      if (v != null) {
        lat = v is num ? v.toDouble() : double.tryParse(v.toString());
        if (lat != null) break;
      }
    }

    for (final v in lngCandidates) {
      if (v != null) {
        lng = v is num ? v.toDouble() : double.tryParse(v.toString());
        if (lng != null) break;
      }
    }

    if (lat != null && lng != null) return LatLng(lat, lng);
    return null;
  }

  void _extractOriginDestination() {
    final ride = widget.item['ride'] ?? {};
    final origin = ride['origin_location'];
    final destination = ride['destination_location'];

    _originLatLng = _parseLatLng(origin);
    _destinationLatLng = _parseLatLng(destination);
  }

  // ==================== COUNTDOWN TIMER ====================

  void _startCountdownTimer() {
    final ride = widget.item['ride'] ?? {};
    final departureDate = ride['departure_date'];
    final departureTime = ride['departure_time'];

    if (departureDate == null || departureTime == null) {
      setState(() {
        _isDepartureReady = true;
      });
      return;
    }

    try {
      DateTime departureDateTime;
      String dateStr = departureDate.toString();
      String timeStr = departureTime.toString();

      // Handle ISO 8601 format: "2026-01-30T00:00:00.000000Z"
      if (dateStr.contains('T')) {
        DateTime dateOnly = DateTime.parse(dateStr);
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          departureDateTime = DateTime(
            dateOnly.year,
            dateOnly.month,
            dateOnly.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
            timeParts.length >= 3 ? int.parse(timeParts[2].split('.')[0]) : 0,
          );
        } else {
          throw FormatException('Invalid time format');
        }
      } else if (dateStr.contains(' ')) {
        departureDateTime = DateTime.parse(dateStr);
      } else {
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
          throw FormatException('Invalid date/time parts');
        }
      }

      final initialDifference = departureDateTime.difference(DateTime.now());

      if (initialDifference.isNegative || initialDifference.inSeconds <= 0) {
        setState(() {
          _timeUntilDeparture = Duration.zero;
          _isDepartureReady = true;
        });
        return;
      } else {
        setState(() {
          _timeUntilDeparture = initialDifference;
          _isDepartureReady = false;
        });
      }

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final now = DateTime.now();
        final difference = departureDateTime.difference(now);

        if (difference.isNegative || difference.inSeconds <= 0) {
          setState(() {
            _timeUntilDeparture = Duration.zero;
            _isDepartureReady = true;
          });
          timer.cancel();
        } else {
          setState(() {
            _timeUntilDeparture = difference;
            _isDepartureReady = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isDepartureReady = true;
        _timeUntilDeparture = null;
      });
    }
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ==================== ROUTE FETCHING ====================

  Future<void> _fetchMainRoute() async {
    if (_originLatLng == null || _destinationLatLng == null) return;

    try {
      final src = '${_originLatLng!.longitude},${_originLatLng!.latitude}';
      final dst =
          '${_destinationLatLng!.longitude},${_destinationLatLng!.latitude}';
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$src;$dst?overview=full&geometries=geojson');

      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data != null &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coords.map<LatLng>((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          setState(() {
            _mainRoute = points;
          });
        }
      }
    } catch (e, st) {
      // Error handling
    }
  }

  Future<void> _fetchRouteToOrigin() async {
    if (_lastPosition == null) return;

    // Attempt to fetch origin if missing
    if (_originLatLng == null) {
      try {
        final bookingId = await _resolveBookingId();
        if (bookingId != null) {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('api_token');
          if (token != null) {
            final booking = await ApiService.fetchBooking(
                bookingId: bookingId, token: token);
            final ride = booking['ride'] ?? booking;
            final origin = ride['origin_location'] ?? ride['origin'];
            final parsed = _parseLatLng(origin);
            if (parsed != null) {
              _originLatLng = parsed;
              if (_destinationLatLng != null) {
                _fetchMainRoute();
              }
            }
          }
        }
      } catch (e, st) {
        // Error handling
      }
    }

    if (_originLatLng == null) return;

    try {
      final src = '${_lastPosition!.longitude},${_lastPosition!.latitude}';
      final dst = '${_originLatLng!.longitude},${_originLatLng!.latitude}';
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$src;$dst?overview=full&geometries=geojson');

      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data != null &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coords.map<LatLng>((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();

          setState(() {
            _routeToOrigin = points;
          });
        }
      }
    } catch (e, st) {
      // Error handling
    }
  }

  // ==================== LOCATION TRACKING ====================

  Future<void> _checkAndStartTracking() async {
    final ride = widget.item['ride'] ?? {};
    final status = (ride['status'] ?? '').toString().toLowerCase();

    if (status.contains('active') ||
        status.contains('progress') ||
        status == 'paid' ||
        status == 'confirmed' ||
        status == 'menuju_penjemputan') {
      await _startLocationTracking();
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    setState(() => _isTracking = true);
    // persist tracking active
    _savePersistentTracking(true);

    _sendLocationUpdate();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    _locationTimer?.cancel();
    final interval =
        _isMoving ? const Duration(seconds: 5) : const Duration(minutes: 1);
    _locationTimer = Timer.periodic(interval, (_) => _sendLocationUpdate());
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 10),
      );

      // Detect movement
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final wasMoving = _isMoving;
        bool movingByDistance = distance >= 0.2;
        _isMoving = movingByDistance;

        if (wasMoving != _isMoving) {
          _startPeriodicUpdate();
        }
      } else {
        _isMoving = false;
      }

      // Add to route
      final newPoint = LatLng(position.latitude, position.longitude);
      _routePoints.add(newPoint);

      // Center map on current position
      _mapController.move(newPoint, 15.0);

      _lastPosition = position;

      // persist last known position so marker survives page reloads
      _saveLastPosition(position.latitude, position.longitude);

      // Detect arrival at pickup
      if (!_isAtPickup && _originLatLng != null) {
        final double distanceToOrigin = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _originLatLng!.latitude,
          _originLatLng!.longitude,
        );
        if (distanceToOrigin <= 50.0) {
          _onArrivedAtPickup();
        }
      }

      if (mounted) {
        setState(() {});
      }

      // Refresh route to origin if status is menuju_penjemputan
      final ride = widget.item['ride'] ?? {};
      final status = (ride['status'] ?? '').toString().toLowerCase();
      if (status == 'menuju_penjemputan') {
        _fetchRouteToOrigin();
      }

      // Resolve bookingId and update location
      final rideId = ride['id'] as int?;
      int? bookingId = await _resolveBookingId();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      // Fetch origin if missing
      if (_originLatLng == null && bookingId != null && token != null) {
        try {
          final booking =
              await ApiService.fetchBooking(bookingId: bookingId, token: token);
          final fetchedRide = booking['ride'] ?? booking;
          final origin =
              fetchedRide['origin_location'] ?? fetchedRide['origin'];
          final parsed = _parseLatLng(origin);
          if (parsed != null) {
            _originLatLng = parsed;
            if (_destinationLatLng != null) {
              _fetchMainRoute();
            }
          }
        } catch (e) {
          // Error handling
        }
      }

      if (bookingId == null || token == null) return;

      final success = await ApiService.updateBookingLocation(
        bookingId: bookingId,
        token: token,
        lat: position.latitude,
        lng: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        speed: position.speed,
        bookingType: _bookingType,
      );
    } catch (e, stackTrace) {
      // Error handling
    }
  }

  // ==================== PERSISTENCE HELPERS ====================

  Future<void> _savePersistentTracking(bool active) async {
    try {
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mitra_tracking_active_$bookingId', active);
      setState(() => _menujuActive = active);
    } catch (e) {}
  }

  Future<void> _saveLastPosition(double lat, double lng) async {
    try {
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('mitra_last_lat_$bookingId', lat);
      await prefs.setDouble('mitra_last_lng_$bookingId', lng);
    } catch (e) {}
  }

  Future<void> _clearPersistentTracking() async {
    try {
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mitra_tracking_active_$bookingId');
      await prefs.remove('mitra_last_lat_$bookingId');
      await prefs.remove('mitra_last_lng_$bookingId');
    } catch (e) {}
  }

  Future<void> _loadPersistentState() async {
    try {
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;
      final prefs = await SharedPreferences.getInstance();
      final active = prefs.getBool('mitra_tracking_active_$bookingId') ?? false;
      final lat = prefs.getDouble('mitra_last_lat_$bookingId');
      final lng = prefs.getDouble('mitra_last_lng_$bookingId');

      if (lat != null && lng != null) {
        // create a synthetic Position so existing code can use it
        _lastPosition = Position(
          longitude: lng,
          latitude: lat,
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

      if (active) {
        setState(() => _menujuActive = true);
        await _startLocationTracking();
      }
      if (mounted) setState(() {});
    } catch (e) {}
  }

  // ==================== ARRIVAL & PICKUP HANDLERS ====================

  void _onArrivedAtPickup() {
    if (_isAtPickup) return;
    setState(() {
      _isAtPickup = true;
      _pickupRemaining = _pickupWait;
      _canCancelPickup = false;
    });

    _pickupTimer?.cancel();
    _pickupTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        final newSec = _pickupRemaining.inSeconds - 1;
        if (newSec <= 0) {
          _pickupRemaining = Duration.zero;
          _canCancelPickup = true;
          _pickupTimer?.cancel();
        } else {
          _pickupRemaining = Duration(seconds: newSec);
        }
      });
    });
  }

  Future<void> _markPickedUp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      // call API to mark passenger picked up (status name may vary)
      await ApiService.updateBookingStatus(
        bookingId: bookingId,
        status: 'sudah_di_penjemputan',
        token: token,
      );

      // stop waiting timer & set picked up
      _pickupTimer?.cancel();
      setState(() {
        _isAtPickup = false;
        _pickedUp = true;
        _canCancelPickup = false;
      });
      // keep tracking active but change persistent flag if needed
      _savePersistentTracking(false);
      // clear persisted since now in transit to destination; last position can remain
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status penjemputan: $e')),
      );
    }
  }

  Future<void> _markMenujuTujuan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await ApiService.updateBookingStatus(
        bookingId: bookingId,
        status: 'menuju_tujuan',
        token: token,
      );

      // clear persistent menuju state and remain tracking as appropriate
      await _clearPersistentTracking();
      setState(() {
        _pickedUp = false;
        _menujuActive = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status menuju tujuan: $e')),
      );
    }
  }

  Future<void> _cancelPickup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return;
      final bookingId = await _resolveBookingId();
      if (bookingId == null) return;

      await ApiService.updateBookingStatus(
        bookingId: bookingId,
        status: 'cancelled',
        token: token,
      );

      _pickupTimer?.cancel();
      await _clearPersistentTracking();

      if (mounted) {
        setState(() {
          _isAtPickup = false;
          _pickedUp = false;
          _menujuActive = false;
          _lastPosition = null;
        });
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan tebengan: $e')),
      );
    }
  }

  // ==================== BOOKING ID RESOLUTION ====================

  Future<int?> _resolveBookingId() async {
    int? bookingId;
    final ride = widget.item['ride'] ?? {};
    final rideId = ride['id'];

    // Try to get bookingId from various sources
    if (widget.item['id'] != null) {
      bookingId = widget.item['id'] as int?;
    }

    if (bookingId == null && widget.item['booking'] is Map) {
      final booking = widget.item['booking'] as Map<String, dynamic>;
      if (booking['id'] != null) {
        bookingId = booking['id'] as int?;
      }
    }

    if (bookingId == null && widget.item['booking_id'] != null) {
      bookingId = widget.item['booking_id'] as int?;
    }

    // Fetch bookingId by rideId if not found
    if (bookingId == null && rideId != null) {
      bookingId = await _fetchBookingIdByType(rideId);
    } else if (bookingId != null && rideId != null && bookingId == rideId) {
      // If bookingId equals rideId, it's likely the rideId, not bookingId
      bookingId = await _fetchBookingIdByType(rideId);
    }

    return bookingId;
  }

  Future<int?> _fetchBookingIdByType(int rideId) async {
    switch (_bookingType) {
      case 'motor':
        final motorBooking = await _getMotorBooking(rideId);
        return motorBooking?['id'];
      case 'mobil':
        final mobilBooking = await _getMobilBookingByRideId(rideId);
        return mobilBooking?['id'];
      case 'barang':
        final barangBooking = await _getBarangBookingByRideId(rideId);
        return barangBooking?['id'];
      case 'titip':
        final titipBooking = await _getTitipBarangBookingByRideId(rideId);
        return titipBooking?['id'];
      default:
        return null;
    }
  }

  // ==================== BOOKING FETCHERS ====================

  Future<Map<String, dynamic>?> _getMotorBooking(int? rideId) async {
    if (rideId == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/bookings/my?type=motor');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          final bookings = List<Map<String, dynamic>>.from(body['data']);
          for (var booking in bookings) {
            if (booking['ride_id'] == rideId) {
              return booking;
            }
          }
        }
      }

      // Fallback to getRidePassengers
      final passengers =
          await ApiService.getRidePassengers(rideId, 'tebengan_motor');
      if (passengers.isNotEmpty) {
        return passengers[0];
      }
    } catch (e) {
      // Error handling
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getMobilBookingByRideId(int? rideId) async {
    if (rideId == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/booking-mobil?ride_id=$rideId');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          final bookings = List<Map<String, dynamic>>.from(body['data']);
          if (bookings.isNotEmpty) {
            return bookings.first;
          }
        }
      }
    } catch (e) {
      // Error handling
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getBarangBookingByRideId(int? rideId) async {
    if (rideId == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/api/v1/booking-barang?ride_id=$rideId');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          final bookings = List<Map<String, dynamic>>.from(body['data']);
          if (bookings.isNotEmpty) {
            return bookings.first;
          }
        }
      }
    } catch (e) {
      // Error handling
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getTitipBarangBookingByRideId(
      int? rideId) async {
    if (rideId == null) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return null;

      final uri =
          Uri.parse('$baseUrl/api/v1/booking-titip-barang?ride_id=$rideId');
      final resp = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          final bookings = List<Map<String, dynamic>>.from(body['data']);
          if (bookings.isNotEmpty) {
            return bookings.first;
          }
        }
      }
    } catch (e) {
      // Error handling
    }
    return null;
  }

  Future<Map<String, dynamic>> _getMobilBookingWithPassengers(
      int? rideId) async {
    if (rideId == null) return {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return {};

      final passengers =
          await ApiService.getRidePassengers(rideId, 'tebengan_mobil');
      if (passengers.isNotEmpty) {
        return {'booking': passengers[0], 'passengers': passengers};
      }
    } catch (e) {
      // Error handling
    }
    return {};
  }

  // ==================== STATUS UPDATE ====================

  Future<void> _markMenujuPenjemputan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token tidak ditemukan')),
        );
        return;
      }

      final bookingId = await _resolveBookingId();
      if (bookingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking ID tidak ditemukan')),
        );
        return;
      }

      // Call API to update status
      final result = await ApiService.updateBookingStatus(
        bookingId: bookingId,
        status: 'menuju_penjemputan',
        token: token,
      );

      // Update local state
      setState(() {
        final ride = widget.item['ride'] ?? {};
        if (ride is Map) {
          ride['status'] = 'menuju_penjemputan';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status diupdate: Menuju titik jemput')),
      );

      // Fetch driving route to origin
      await _fetchRouteToOrigin();

      // Move map to show route
      if (_lastPosition != null && _originLatLng != null) {
        final cur = LatLng(_lastPosition!.latitude, _lastPosition!.longitude);
        _mapController.move(cur, 14.0);
      } else if (_originLatLng != null) {
        _mapController.move(_originLatLng!, 14.0);
      }

      // Start location tracking after button clicked
      await _startLocationTracking();
      // mark persistent menuju active
      _savePersistentTracking(true);
    } catch (e, st) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status: $e')),
      );
    }
  }

  // ==================== CHAT ====================

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

      final ride = widget.item['ride'] ?? {};
      final rideId = ride['id'] as int?;
      final customerId = widget.item['user_id'] as int?;

      if (rideId == null || customerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data booking tidak lengkap')),
        );
        return;
      }

      // Check if conversation exists
      final existingConv = await _chatService.getConversationByRideAndUsers(
        rideId: rideId,
        customerId: customerId,
        mitraId: mitraId,
      );

      String conversationId;
      if (existingConv != null) {
        conversationId = existingConv['id'] as String;
      } else {
        // Create new conversation
        final customerName = widget.item['user_name'] as String? ?? 'Customer';
        final customerPhoto = widget.item['user_photo'] as String?;

        final newConvId = await ChatHelper.createConversationAfterBooking(
          rideId: rideId,
          bookingType: _bookingType,
          customerData: {
            'id': customerId,
            'name': customerName,
            'photo': customerPhoto,
          },
          mitraData: {
            'id': mitraId,
            'name': mitraName,
            'photo': null,
          },
        );

        if (newConvId == null) {
          throw Exception('Failed to create conversation');
        }

        conversationId = newConvId;
      }

      // Navigate to chat page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MitraChatDetailPage(
              conversationId: conversationId,
              otherUserName: widget.item['user_name'] as String? ?? 'Customer',
              otherUserPhoto: widget.item['user_photo'] as String?,
              bookingType: _bookingType,
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

  // ==================== BUILD UI ====================

  @override
  Widget build(BuildContext context) {
    final ride = widget.item['ride'] ?? {};
    final origin = ride['origin_location'] ?? {};
    final destination = ride['destination_location'] ?? {};
    final originName = origin['name'] ?? 'Lokasi Asal';
    final originAddress = origin['address'] ?? '';
    final destinationName = destination['name'] ?? 'Lokasi Tujuan';

    // Get customer name
    String customerName = 'Customer';
    if (widget.item['customer_name'] != null &&
        widget.item['customer_name'].toString().isNotEmpty) {
      customerName = widget.item['customer_name'];
    } else if (widget.item['customer'] != null &&
        widget.item['customer']['name'] != null) {
      customerName = widget.item['customer']['name'];
    } else if (widget.item['user'] != null &&
        widget.item['user']['name'] != null) {
      customerName = widget.item['user']['name'];
    } else if (widget.item['user_name'] != null) {
      customerName = widget.item['user_name'];
    }

    // Get booking number
    String bookingNumber = '-';
    if (widget.item['booking_number'] != null &&
        widget.item['booking_number'].toString().isNotEmpty) {
      bookingNumber = widget.item['booking_number'].toString();
    } else if (ride['booking_number'] != null &&
        ride['booking_number'].toString().isNotEmpty) {
      bookingNumber = ride['booking_number'].toString();
    } else if (ride['code'] != null && ride['code'].toString().isNotEmpty) {
      bookingNumber = ride['code'].toString();
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopMessageButton(),
          _buildBackButton(),
          if (_timeUntilDeparture != null) _buildCountdownTimer(),
          _buildBottomInfoCard(
            bookingNumber: bookingNumber,
            customerName: customerName,
            originName: originName,
            originAddress: originAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _lastPosition != null
            ? LatLng(_lastPosition!.latitude, _lastPosition!.longitude)
            : _originLatLng ?? const LatLng(-7.797068, 110.370529),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nebeng',
        ),
        // Main route line removed - only show blue route to origin
        _buildRouteToOriginLine(),
        // Tracking route line removed per user request
        _buildMarkers(),
      ],
    );
  }

  Widget _buildMainRouteLine() {
    if (_mainRoute.isEmpty) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: _mainRoute,
          strokeWidth: 4.0,
          color: Colors.grey.shade600,
          borderStrokeWidth: 1.0,
          borderColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildRouteToOriginLine() {
    if (_routeToOrigin.isEmpty) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: _routeToOrigin,
          strokeWidth: 5.0,
          color: Colors.blueAccent,
          borderStrokeWidth: 2.0,
          borderColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildTrackingRouteLine() {
    if (_routePoints.length <= 1) return const SizedBox.shrink();

    return PolylineLayer(
      polylines: [
        Polyline(
          points: _routePoints,
          strokeWidth: 5.0,
          color: Colors.green,
          borderStrokeWidth: 2.0,
          borderColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildMarkers() {
    return MarkerLayer(
      markers: [
        if (_originLatLng != null) _buildOriginMarker(),
        if (_destinationLatLng != null) _buildDestinationMarker(),
        ..._buildRoutePointMarkers(),
        if (_lastPosition != null) _buildCurrentPositionMarker(),
      ],
    );
  }

  Marker _buildOriginMarker() {
    return Marker(
      point: _originLatLng!,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.location_on,
        color: Colors.green,
        size: 36,
      ),
    );
  }

  Marker _buildDestinationMarker() {
    return Marker(
      point: _destinationLatLng!,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.flag,
        color: Colors.red,
        size: 36,
      ),
    );
  }

  List<Marker> _buildRoutePointMarkers() {
    return _routePoints
        .map((point) => Marker(
              point: point,
              width: 12,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ))
        .toList();
  }

  Marker _buildCurrentPositionMarker() {
    return Marker(
      point: LatLng(_lastPosition!.latitude, _lastPosition!.longitude),
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.navigation,
            color: Colors.blue,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTopMessageButton() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(25),
          elevation: 4,
          child: InkWell(
            onTap: _openChatWithCustomer,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.message, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pesan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 50,
      left: 16,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          customBorder: const CircleBorder(),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color:
                _isDepartureReady ? Colors.green.shade600 : Colors.red.shade600,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isDepartureReady ? Icons.check_circle : Icons.timer,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isDepartureReady
                    ? 'Siap Berangkat!'
                    : 'Keberangkatan: ${_formatCountdown(_timeUntilDeparture!)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfoCard({
    required String bookingNumber,
    required String customerName,
    required String originName,
    required String originAddress,
  }) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBookingHeader(bookingNumber, customerName),
            const Divider(height: 1),
            _buildOriginInfo(originName, originAddress),
            // If arrived at pickup show waiting timer + actions
            if (_isAtPickup) _buildPickupWaitingCard(),
            // If picked up show button to go to destination
            if (_pickedUp) _buildGoToDestinationButton(),
            // If not in active menuju state and not picked up, show default action button
            if (!_menujuActive && !_pickedUp && !_isAtPickup)
              _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPickupWaitingCard() {
    final minutes =
        _pickupRemaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _pickupRemaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                const Text('Menunggu Costumer',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('$minutes:$seconds',
                    style: const TextStyle(
                        fontSize: 36,
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Sisa Waktu Tunggu',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openChatWithCustomer,
                        child: const Text('Hubungi Costumer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _markPickedUp,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A)),
                        child: const Text('Lanjutkan tebengan'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _canCancelPickup ? _cancelPickup : null,
                        child: const Text('Batalkan tebengan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoToDestinationButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _markMenujuTujuan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Menuju titik tujuan',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildBookingHeader(String bookingNumber, String customerName) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No Pemesanan:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  bookingNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Fitur telepon akan segera tersedia')),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.phone, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openChatWithCustomer,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3A8A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.message,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginInfo(String originName, String originAddress) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menuju Titik Jemput',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  originName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (originAddress.isNotEmpty)
                  Text(
                    originAddress,
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
          TextButton(
            onPressed: () {
              // Show detail
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.grey),
              ),
            ),
            child: const Text(
              'Detail',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isDepartureReady ? _markMenujuPenjemputan : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isDepartureReady ? const Color(0xFF1E3A8A) : Colors.grey,
            disabledBackgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _isDepartureReady ? 'Mulai Menuju' : 'Menunggu waktu keberangkatan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
