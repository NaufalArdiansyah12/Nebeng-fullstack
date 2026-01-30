import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Booking Service - handles booking operations
class BookingService {
  /// Create booking (reserve seats) before payment
  static Future<Map<String, dynamic>> createBooking({
    required int rideId,
    required int userId,
    required int seats,
    required String bookingNumber,
    String? rideType,
    String? photoFilePath,
    String? weight,
    String? description,
    String? penerima,
    List<Map<String, dynamic>>? penumpang,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings');

    // If photoFilePath provided, send multipart request
    if (photoFilePath != null && photoFilePath.isNotEmpty) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
      });

      request.fields['ride_id'] = rideId.toString();
      request.fields['user_id'] = userId.toString();
      request.fields['seats'] = seats.toString();
      request.fields['booking_number'] = bookingNumber;
      if (rideType != null && rideType.isNotEmpty) {
        request.fields['ride_type'] = rideType;
      }
      if (weight != null && weight.isNotEmpty) {
        request.fields['weight'] = weight;
      }
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (penerima != null && penerima.isNotEmpty) {
        request.fields['penerima'] = penerima;
      }

      // Attach penumpang as nested form fields so Laravel validates as array
      if (penumpang != null && penumpang.isNotEmpty) {
        for (var i = 0; i < penumpang.length; i++) {
          final p = penumpang[i];
          request.fields['penumpang[$i][nama]'] = (p['nama'] ?? '').toString();
          if (p['nik'] != null)
            request.fields['penumpang[$i][nik]'] = p['nik'].toString();
          if (p['no_telepon'] != null)
            request.fields['penumpang[$i][no_telepon]'] =
                p['no_telepon'].toString();
          if (p['jenis_kelamin'] != null)
            request.fields['penumpang[$i][jenis_kelamin]'] =
                p['jenis_kelamin'].toString();
        }
      }

      final file = await http.MultipartFile.fromPath('photo', photoFilePath);
      request.files.add(file);

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(body['data']);
        }
        throw Exception('Unexpected response format');
      } else {
        final preview =
            resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
        throw Exception(
            'Failed to create booking: ${resp.statusCode}. Preview: $preview');
      }
    }

    // Fallback: JSON request (no photo)
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'ride_id': rideId,
        'user_id': userId,
        'seats': seats,
        'booking_number': bookingNumber,
        if (rideType != null && rideType.isNotEmpty) 'ride_type': rideType,
        if (weight != null && weight.isNotEmpty) 'weight': weight,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (penerima != null && penerima.isNotEmpty) 'penerima': penerima,
        if (penumpang != null && penumpang.isNotEmpty) 'penumpang': penumpang,
      }),
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to create booking: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Fetch bookings for authenticated user
  static Future<List<Map<String, dynamic>>> fetchBookings({
    required String token,
    String? type,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings/my')
        .replace(queryParameters: type != null ? {'type': type} : null);

    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) {
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
        if (body is List) {
          return List<Map<String, dynamic>>.from(body);
        }
        throw Exception('Unexpected response format');
      } catch (e) {
        final preview =
            resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
        throw Exception(
            'Expected JSON but received non-JSON response (status: ${resp.statusCode}). Preview: $preview');
      }
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to fetch bookings: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Fetch single booking details by id
  static Future<Map<String, dynamic>> fetchBooking({
    required int bookingId,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings/$bookingId');

    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    var resp = await http.get(uri, headers: headers);
    // Some backend implementations expect POST for this endpoint.
    // If GET returns 405 Method Not Allowed, fallback to POST.
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
        throw Exception('Unexpected response format');
      } catch (e) {
        final preview =
            resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
        throw Exception(
            'Expected JSON but received non-JSON response (status: ${resp.statusCode}). Preview: $preview');
      }
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to fetch booking: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
    required String token,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings/$bookingId/status');
    final resp = await http.put(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );

    final body = json.decode(resp.body);
    if ((resp.statusCode == 200 || resp.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to update booking status');
  }

  /// Cancel a booking
  static Future<Map<String, dynamic>> cancelBooking(
    int bookingId,
    String reason,
  ) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings/$bookingId/cancel');

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'cancellation_reason': reason,
      }),
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      throw Exception(body['message'] ?? 'Failed to cancel booking');
    }
    throw Exception('Failed to cancel booking: ${resp.statusCode}');
  }

  /// Get cancellation count for current month
  static Future<Map<String, dynamic>> getCancellationCount(int userId) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/$userId/cancellation-count');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {'count': 0});
      }
      return {'count': 0};
    }
    return {'count': 0};
  }

  /// Get comprehensive tracking info for a booking
  static Future<Map<String, dynamic>> getBookingTracking({
    required int bookingId,
    required String token,
    String bookingType = 'motor',
  }) async {
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
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/$endpoint/$bookingId/tracking');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to get tracking info: ${resp.statusCode}');
  }
}
