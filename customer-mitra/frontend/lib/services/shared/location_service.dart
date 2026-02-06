import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Location Service - handles location operations
class LocationService {
  /// Fetch locations from backend
  static Future<List<Map<String, dynamic>>> fetchLocations() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/locations');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode == 200) {
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
        // if backend returns raw array
        if (body is List) {
          return List<Map<String, dynamic>>.from(body);
        }
        throw Exception('Unexpected response format');
      } catch (e) {
        // JSON parsing failed -> likely HTML (error page) returned
        final preview =
            resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
        throw Exception(
            'Expected JSON but received non-JSON response (status: ${resp.statusCode}). Preview: $preview');
      }
    } else {
      final contentType = resp.headers['content-type'] ?? '';
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to fetch locations: ${resp.statusCode}. Content-Type: $contentType. Preview: $preview');
    }
  }

  /// Report mitra last location
  static Future<bool> reportMitraLocation({
    required String token,
    required double lat,
    required double lng,
    DateTime? at,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/location');
    final body = json.encode({
      'lat': lat,
      'lng': lng,
      'timestamp': (at ?? DateTime.now()).toIso8601String(),
    });

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return true;
    }
    return false;
  }

  /// Send driver location update for booking
  static Future<bool> updateBookingLocation({
    required int bookingId,
    required String token,
    required double lat,
    required double lng,
    DateTime? timestamp,
    double? accuracy,
    double? speed,
    String bookingType = 'motor',
  }) async {
    try {
      String endpoint;
      if (bookingType == 'mobil') {
        endpoint = 'booking-mobil';
      } else if (bookingType == 'barang') {
        endpoint = 'booking-barang';
      } else if (bookingType == 'titip') {
        endpoint = 'booking-titip-barang';
      } else {
        endpoint = 'bookings';
      }

      final uri = Uri.parse(
          '${ApiConfig.baseUrl}/api/v1/$endpoint/$bookingId/location');
      print('🌐 Sending to: $uri');

      final resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'lat': lat,
          'lng': lng,
          if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
          if (accuracy != null) 'accuracy': accuracy,
          if (speed != null) 'speed': speed,
        }),
      );

      print('📡 Response status: ${resp.statusCode}');
      print('📡 Response body: ${resp.body}');

      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        return body is Map && body['success'] == true;
      }
      return false;
    } catch (e) {
      print('❌ Error in updateBookingLocation: $e');
      return false;
    }
  }

  /// Fetch latest location for a booking (used by tracking page)
  static Future<Map<String, dynamic>> fetchBookingLocation({
    required int bookingId,
    String? token,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings/$bookingId/location');
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Try GET first
    var resp = await http.get(uri, headers: headers);

    // If backend expects POST for this route, fallback to POST on 405
    if (resp.statusCode == 405) {
      resp = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (headers['Authorization'] != null)
            'Authorization': headers['Authorization']!,
        },
        body: json.encode({}),
      );
    }

    if (resp.statusCode == 200) {
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
        if (body is Map && body['lat'] != null) {
          // some endpoints return raw object
          return Map<String, dynamic>.from(body);
        }
        throw Exception('Unexpected response format');
      } catch (e) {
        final preview =
            resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
        throw Exception(
            'Expected JSON but received non-JSON response. Preview: $preview');
      }
    } else if (resp.statusCode == 304) {
      // Not modified - return empty map to indicate no new data
      return {};
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to fetch booking location: ${resp.statusCode}. Preview: $preview');
    }
  }
}
