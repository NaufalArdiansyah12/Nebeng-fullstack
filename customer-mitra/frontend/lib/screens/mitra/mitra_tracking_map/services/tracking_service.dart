import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

/// Service class for tracking-related operations
class TrackingService {
  final String baseUrl = ApiService.baseUrl;

  /// Fetch route between two points
  Future<List<LatLng>> fetchRoute(LatLng from, LatLng to) async {
    try {
      final src = '${from.longitude},${from.latitude}';
      final dst = '${to.longitude},${to.latitude}';
      final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$src;$dst?overview=full&geometries=geojson');

      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data != null &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          return coords.map<LatLng>((c) {
            final lng = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      }
    } catch (e) {
      // Ignore errors
    }
    return [];
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Check if location services are enabled and permissions granted
  Future<bool> checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Update booking location
  Future<bool> updateBookingLocation({
    required int bookingId,
    required String token,
    required double lat,
    required double lng,
    required DateTime timestamp,
    required double accuracy,
    required double speed,
    required String bookingType,
  }) async {
    return await ApiService.updateBookingLocation(
      bookingId: bookingId,
      token: token,
      lat: lat,
      lng: lng,
      timestamp: timestamp,
      accuracy: accuracy,
      speed: speed,
      bookingType: bookingType,
    );
  }

  /// Update booking status
  Future<dynamic> updateBookingStatus({
    required int bookingId,
    required String status,
    required String token,
  }) async {
    return await ApiService.updateBookingStatus(
      bookingId: bookingId,
      status: status,
      token: token,
    );
  }

  /// Fetch booking data
  Future<Map<String, dynamic>> fetchBooking({
    required int bookingId,
    required String token,
  }) async {
    return await ApiService.fetchBooking(
      bookingId: bookingId,
      token: token,
    );
  }

  /// Resolve booking ID from ride ID
  Future<int?> resolveBookingId(
    Map<String, dynamic> item,
    String bookingType,
  ) async {
    int? bookingId;
    final ride = item['ride'] ?? {};
    final rideId = ride['id'];

    // Try to get bookingId from various sources
    if (item['id'] != null) {
      bookingId = item['id'] as int?;
    }

    if (bookingId == null && item['booking'] is Map) {
      final booking = item['booking'] as Map<String, dynamic>;
      if (booking['id'] != null) {
        bookingId = booking['id'] as int?;
      }
    }

    if (bookingId == null && item['booking_id'] != null) {
      bookingId = item['booking_id'] as int?;
    }

    // Fetch bookingId by rideId if not found
    if (bookingId == null && rideId != null) {
      bookingId = await _fetchBookingIdByType(rideId, bookingType);
    } else if (bookingId != null && rideId != null && bookingId == rideId) {
      // If bookingId equals rideId, it's likely the rideId, not bookingId
      bookingId = await _fetchBookingIdByType(rideId, bookingType);
    }

    return bookingId;
  }

  Future<int?> _fetchBookingIdByType(int rideId, String bookingType) async {
    switch (bookingType) {
      case 'motor':
        final motorBooking = await getMotorBooking(rideId);
        return motorBooking?['id'];
      case 'mobil':
        final mobilBooking = await getMobilBookingByRideId(rideId);
        return mobilBooking?['id'];
      case 'barang':
        final barangBooking = await getBarangBookingByRideId(rideId);
        return barangBooking?['id'];
      case 'titip':
        final titipBooking = await getTitipBarangBookingByRideId(rideId);
        return titipBooking?['id'];
      default:
        return null;
    }
  }

  /// Get motor booking by ride ID
  Future<Map<String, dynamic>?> getMotorBooking(int? rideId) async {
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
      // Ignore errors
    }
    return null;
  }

  /// Get mobil booking by ride ID
  Future<Map<String, dynamic>?> getMobilBookingByRideId(int? rideId) async {
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
      // Ignore errors
    }
    return null;
  }

  /// Get barang booking by ride ID
  Future<Map<String, dynamic>?> getBarangBookingByRideId(int? rideId) async {
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
      // Ignore errors
    }
    return null;
  }

  /// Get titip barang booking by ride ID
  Future<Map<String, dynamic>?> getTitipBarangBookingByRideId(
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
      // Ignore errors
    }
    return null;
  }
}
