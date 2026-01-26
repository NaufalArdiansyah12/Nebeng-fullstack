import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class MitraTrackingMapPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MitraTrackingMapPage({Key? key, required this.item}) : super(key: key);

  @override
  State<MitraTrackingMapPage> createState() => _MitraTrackingMapPageState();
}

class _MitraTrackingMapPageState extends State<MitraTrackingMapPage> {
  Timer? _locationTimer;
  Position? _lastPosition;
  bool _isTracking = false;
  bool _isMoving = false;
  final List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  // Base URL for API
  final String baseUrl = ApiService.baseUrl;

  // Route (driving) from current position to origin (fetched from routing service)
  List<LatLng> _routeToOrigin = [];

  // Route from origin to destination (main route)
  List<LatLng> _mainRoute = [];

  // Origin/destination coordinates
  LatLng? _originLatLng;
  LatLng? _destinationLatLng;

  // Booking type detection
  String _bookingType = 'motor'; // 'motor' or 'mobil'

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

  @override
  void initState() {
    super.initState();
    print('🗺️ MitraTrackingMapPage initialized');
    _detectBookingType();
    _extractOriginDestination();
    _fetchMainRoute(); // Fetch main route on init
    _checkAndStartTracking();
  }

  void _detectBookingType() {
    final ride = widget.item['ride'] ?? {};
    final mitraVehicle = ride['kendaraan_mitra'] ?? {};
    final rawType = (mitraVehicle['type'] ??
            mitraVehicle['vehicle_type'] ??
            mitraVehicle['transportation'] ??
            '')
        .toString()
        .toLowerCase();
    final serviceType = (ride['service_type'] ?? '').toString().toLowerCase();

    if (rawType.contains('mobil') ||
        rawType.contains('car') ||
        serviceType.contains('mobil') ||
        serviceType.contains('car')) {
      _bookingType = 'mobil';
    } else {
      _bookingType = 'motor';
    }
    print('🚗 Booking type detected: $_bookingType');
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _extractOriginDestination() {
    final ride = widget.item['ride'] ?? {};
    final origin = ride['origin_location'];
    final destination = ride['destination_location'];

    _originLatLng = _parseLatLng(origin);
    _destinationLatLng = _parseLatLng(destination);

    print('📍 Origin: $_originLatLng, Destination: $_destinationLatLng');
  }

  // Fetch main route from origin to destination
  Future<void> _fetchMainRoute() async {
    if (_originLatLng == null || _destinationLatLng == null) {
      print('⚠️ Cannot fetch main route: origin or destination missing');
      return;
    }

    try {
      final src = '${_originLatLng!.longitude},${_originLatLng!.latitude}';
      final dst =
          '${_destinationLatLng!.longitude},${_destinationLatLng!.latitude}';
      print('🧭 Fetching main route from $src to $dst');

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
          print('✅ Main route fetched, ${points.length} points');
        } else {
          print('No routes returned for main route');
        }
      } else {
        print('Main route fetch failed: ${resp.statusCode}');
      }
    } catch (e, st) {
      print('Failed to fetch main route: $e');
      print(st);
    }
  }

  Future<void> _checkAndStartTracking() async {
    final ride = widget.item['ride'] ?? {};
    final status = (ride['status'] ?? '').toString().toLowerCase();

    print('🔍 Checking tracking - Status: $status');

    if (status.contains('active') ||
        status.contains('progress') ||
        status == 'paid' ||
        status == 'confirmed' ||
        status == 'menuju_penjemputan') {
      print('✅ Status valid, starting tracking...');
      await _startLocationTracking();
    } else {
      print('❌ Status tidak valid untuk tracking: $status');
    }
  }

  Future<void> _startLocationTracking() async {
    print('🚀 Starting location tracking...');

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location service not enabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permission denied forever');
      return;
    }

    print('✅ Location permission granted');
    setState(() => _isTracking = true);

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
      print('📍 Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 10),
      );

      print(
          '📍 Position: ${position.latitude}, ${position.longitude} (timestamp: ${DateTime.fromMillisecondsSinceEpoch(position.timestamp!.millisecondsSinceEpoch)})');

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

        print(
            '🚗 Movement check - Distance: ${distance.toStringAsFixed(4)}m, IsMoving: $_isMoving ${_isMoving ? "✅ BERGERAK" : "🟧 DIAM"}');

        if (wasMoving != _isMoving) {
          print(
              '🔄 Movement status changed: ${_isMoving ? "MOVING ✅" : "STATIONARY 🟧"}');
          _startPeriodicUpdate();
        }
      } else {
        print('📍 First position captured');
        _isMoving = false;
      }

      // Add to route
      final newPoint = LatLng(position.latitude, position.longitude);
      _routePoints.add(newPoint);

      // Center map on current position
      _mapController.move(newPoint, 15.0);

      _lastPosition = position;

      if (mounted) {
        setState(() {});
      }

      // If we already marked menuju_penjemputan, refresh route to origin
      final ride = widget.item['ride'] ?? {};
      final status = (ride['status'] ?? '').toString().toLowerCase();
      if (status == 'menuju_penjemputan') {
        _fetchRouteToOrigin();
      }

      // Resolve bookingId, rideId and type
      final rideId = ride['id'] as int?;
      final type = (widget.item['type'] ?? '').toString().toLowerCase();
      int? bookingId = await _resolveBookingId();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      // If origin missing and we have bookingId, fetch booking to populate origin
      if (_originLatLng == null && bookingId != null && token != null) {
        try {
          print('🔍 Attempting to fetch booking $bookingId for origin');
          final booking =
              await ApiService.fetchBooking(bookingId: bookingId, token: token);
          print('📦 Booking fetched: ${booking.runtimeType}');
          try {
            print('📦 Booking keys: ${booking.keys.toList()}');
          } catch (e) {}
          final fetchedRide = booking['ride'] ?? booking;
          print(
              '🔎 Ride object keys: ${fetchedRide is Map ? (fetchedRide as Map).keys.toList() : 'not a map'}');
          final origin =
              fetchedRide['origin_location'] ?? fetchedRide['origin'] ?? null;
          final parsed = _parseLatLng(origin);
          if (parsed != null) {
            _originLatLng = parsed;
            print('🔁 Fetched origin from booking: $_originLatLng');
            // Re-fetch main route if we now have complete coordinates
            if (_destinationLatLng != null) {
              _fetchMainRoute();
            }
          } else {
            print('⚠️ No origin field in booking/ride');
          }
        } catch (e) {
          print('Failed to fetch booking for origin: $e');
        }
      }

      if (bookingId == null) {
        print('❌ Booking ID not found!');
        return;
      }

      if (token == null) {
        print('❌ API token not found; cannot send location');
        return;
      }

      print(
          '🚀 Sending location to server - BookingID: $bookingId, Type: $_bookingType');

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

      if (success) {
        print('✅ Lokasi terkirim: ${position.latitude}, ${position.longitude}');
      } else {
        print('❌ Failed to send location');
      }
    } catch (e, stackTrace) {
      print('❌ Error sending location: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<Map<String, dynamic>?> _getMotorBooking(int? rideId) async {
    if (rideId == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return null;
      final passengers =
          await ApiService.getRidePassengers(rideId, 'tebengan_motor');
      if (passengers.isNotEmpty) {
        return passengers[0];
      }
    } catch (e) {
      print('Error getting motor booking: $e');
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
      print('Error getting mobil booking: $e');
    }
    return {};
  }

  Future<int?> _resolveBookingId() async {
    int? bookingId;
    final ride = widget.item['ride'] ?? {};
    final rideId = ride['id'];

    print(
        '🔍 _resolveBookingId - widget.item keys: ${widget.item.keys.toList()}');
    print('🔍 widget.item[id]: ${widget.item['id']}');
    print('🔍 ride_id: $rideId');
    print('🔍 _bookingType: $_bookingType');

    if (widget.item['id'] != null) {
      bookingId = widget.item['id'] as int?;
      print('⚠️ Found widget.item[id]: $bookingId');
    }

    if (bookingId == null && widget.item['booking'] is Map) {
      final booking = widget.item['booking'] as Map<String, dynamic>;
      if (booking['id'] != null) {
        bookingId = booking['id'] as int?;
        print('✅ Found booking.id: $bookingId');
      }
    }

    if (bookingId == null && widget.item['booking_id'] != null) {
      bookingId = widget.item['booking_id'] as int?;
      print('✅ Found booking_id: $bookingId');
    }

    if (bookingId == null && rideId != null) {
      print(
          '🔍 Resolving booking ID from ride_id: $rideId, type: $_bookingType');
      if (_bookingType == 'motor') {
        final motorBooking = await _getMotorBooking(rideId);
        bookingId = motorBooking?['id'];
        print('🏍️ Motor booking ID: $bookingId');
      } else if (_bookingType == 'mobil') {
        final mobilBooking = await _getMobilBookingByRideId(rideId);
        bookingId = mobilBooking?['id'];
        print('🚗 Mobil booking ID: $bookingId');
      }
    } else if (bookingId != null && rideId != null) {
      // bookingId sudah ada, tapi kita perlu pastikan itu bukan ride_id
      print(
          '⚠️ BookingId already set to $bookingId, checking if it\'s actually a ride_id...');
      // Jika bookingId == rideId, kemungkinan besar itu ride_id, bukan booking_id
      if (bookingId == rideId) {
        print('⚠️ BookingId matches ride_id! Fetching actual booking_id...');
        if (_bookingType == 'motor') {
          final motorBooking = await _getMotorBooking(rideId);
          bookingId = motorBooking?['id'];
          print('🏍️ Corrected motor booking ID: $bookingId');
        } else if (_bookingType == 'mobil') {
          final mobilBooking = await _getMobilBookingByRideId(rideId);
          bookingId = mobilBooking?['id'];
          print('🚗 Corrected mobil booking ID: $bookingId');
        }
      }
    }

    print('✅ Final resolved booking ID: $bookingId');
    return bookingId;
  }

  Future<Map<String, dynamic>?> _getMobilBookingByRideId(int? rideId) async {
    if (rideId == null) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) return null;

      // Query booking_mobil by ride_id
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
      print('❌ Error getting mobil booking by ride_id: $e');
    }
    return null;
  }

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

      // Update local state if possible
      setState(() {
        final ride = widget.item['ride'] ?? {};
        if (ride is Map) {
          ride['status'] = 'menuju_penjemputan';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status diupdate: Menuju titik jemput')),
      );

      // Fetch driving route to origin (display as road-following polyline)
      await _fetchRouteToOrigin();

      // If we have current position and origin, move map to show route
      if (_lastPosition != null && _originLatLng != null) {
        final cur = LatLng(_lastPosition!.latitude, _lastPosition!.longitude);
        _mapController.move(cur, 14.0);
      } else if (_originLatLng != null) {
        _mapController.move(_originLatLng!, 14.0);
      }
    } catch (e, st) {
      print('Error updating status: $e');
      print(st);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update status: $e')),
      );
    }
  }

  Future<void> _fetchRouteToOrigin() async {
    if (_lastPosition == null) {
      print('⚠️ Cannot fetch route to origin: no current position');
      return;
    }

    // If origin is missing, attempt to fetch booking details to get origin_location
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
            final origin = ride['origin_location'] ?? ride['origin'] ?? null;
            if (origin != null) {
              final lat = origin['lat'];
              final lng = origin['lng'];
              if (lat != null && lng != null) {
                _originLatLng = LatLng(
                  lat is num
                      ? lat.toDouble()
                      : double.tryParse(lat.toString()) ?? 0,
                  lng is num
                      ? lng.toDouble()
                      : double.tryParse(lng.toString()) ?? 0,
                );
                print('🔁 Fetched origin from booking: $_originLatLng');
              }
            }
          }
        }
      } catch (e, st) {
        print('Failed to fetch booking for origin: $e');
        print(st);
      }
    }

    if (_originLatLng == null) {
      print('⚠️ No origin coordinates available, skipping route fetch');
      return;
    }

    try {
      final src = '${_lastPosition!.longitude},${_lastPosition!.latitude}';
      final dst = '${_originLatLng!.longitude},${_originLatLng!.latitude}';
      print('🧭 Fetching route from current position to origin: $src to $dst');

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
          print('✅ Route to origin fetched, ${points.length} points');
        } else {
          print('No routes returned by routing service');
        }
      } else {
        print('Routing service returned ${resp.statusCode}');
      }
    } catch (e, st) {
      print('Failed to fetch route to origin: $e');
      print(st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.item['ride'] ?? {};
    final origin = ride['origin_location'] ?? {};
    final destination = ride['destination_location'] ?? {};
    final originName = origin['name'] ?? 'Lokasi Asal';
    final originAddress = origin['address'] ?? '';
    final destinationName = destination['name'] ?? 'Lokasi Tujuan';
    final bookingNumber = widget.item['booking_number'] ?? ride['code'] ?? '-';

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
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

              // Main route line from origin to destination (rendered using OSRM route)
              if (_mainRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _mainRoute,
                      strokeWidth: 4.0,
                      color: Colors.grey.shade600,
                      borderStrokeWidth: 1.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Route from current position to origin (when driver hasn't reached pickup)
              // This shows the actual driving route the driver will take
              if (_routeToOrigin.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeToOrigin,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Tracking route (actual path traveled by driver)
              if (_routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.green,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Markers
              MarkerLayer(
                markers: [
                  // Origin marker (pickup point)
                  if (_originLatLng != null)
                    Marker(
                      point: _originLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                  // Destination marker
                  if (_destinationLatLng != null)
                    Marker(
                      point: _destinationLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.flag,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                  // Route points (breadcrumbs of actual path)
                  ..._routePoints.map((point) => Marker(
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
                      )),
                  // Current position (driver's location)
                  if (_lastPosition != null)
                    Marker(
                      point: LatLng(
                          _lastPosition!.latitude, _lastPosition!.longitude),
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
                    ),
                ],
              ),
            ],
          ),

          // Top button "Pesan"
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Material(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(25),
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    // Chat functionality
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
          ),

          // Back button
          Positioned(
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
          ),

          // Bottom info card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                  // Booking number and mitra info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No Pemesanan:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child:
                                  const Icon(Icons.person, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'POS Mitra',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.phone,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.message,
                                  color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Origin location
                  Padding(
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
                          child: const Icon(Icons.location_on,
                              color: Color(0xFF1E3A8A)),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
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
                  ),

                  // Action button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _markMenujuPenjemputan();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Menuju titik jemput',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
