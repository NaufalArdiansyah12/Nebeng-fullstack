import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Ride Service - handles ride operations
class RideService {
  /// Fetch available rides
  static Future<List<Map<String, dynamic>>> fetchRides({
    int? originLocationId,
    int? destinationLocationId,
    String? date,
    String? rideType,
    int? userId,
  }) async {
    final queryParams = <String, String>{};
    if (originLocationId != null) {
      queryParams['origin_location_id'] = originLocationId.toString();
    }
    if (destinationLocationId != null) {
      queryParams['destination_location_id'] = destinationLocationId.toString();
    }
    if (date != null) {
      queryParams['date'] = date;
    }
    if (rideType != null) {
      queryParams['ride_type'] = rideType;
    }
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides')
        .replace(queryParameters: queryParams);
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});

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
          'Failed to fetch rides: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Fetch mitra's ride history (requires Bearer token)
  static Future<List<Map<String, dynamic>>> fetchMitraHistory({
    required String token,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/riwayat')
        .replace(queryParameters: queryParams);
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to fetch mitra history: ${resp.statusCode}');
  }

  /// Create ride (tebengan)
  static Future<Map<String, dynamic>> createRide({
    required String token,
    required int originLocationId,
    required int destinationLocationId,
    required String departureDate,
    required String departureTime,
    required String rideType,
    required String serviceType,
    required double price,
    int? kendaraanMitraId,
    int? bagasiCapacity,
    int? jumlahBagasi,
    String? vehicleName,
    String? vehiclePlate,
    String? vehicleBrand,
    String? vehicleType,
    String? vehicleColor,
    int? availableSeats,
    String? photoFilePath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rides');

    // If photoFilePath provided, send multipart request
    if (photoFilePath != null) {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['origin_location_id'] = originLocationId.toString();
      request.fields['destination_location_id'] =
          destinationLocationId.toString();
      request.fields['departure_date'] = departureDate;
      request.fields['departure_time'] = departureTime;
      request.fields['ride_type'] = rideType;
      request.fields['service_type'] = serviceType;
      request.fields['price'] = price.toString();
      if (kendaraanMitraId != null)
        request.fields['kendaraan_mitra_id'] = kendaraanMitraId.toString();
      if (availableSeats != null)
        request.fields['available_seats'] = availableSeats.toString();
      if (bagasiCapacity != null) {
        request.fields['bagasi_capacity'] = bagasiCapacity.toString();
      }
      if (jumlahBagasi != null) {
        request.fields['jumlah_bagasi'] = jumlahBagasi.toString();
      } else if (bagasiCapacity != null) {
        request.fields['jumlah_bagasi'] = bagasiCapacity.toString();
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
            'Failed to create ride: ${resp.statusCode}. Preview: $preview');
      }
    }

    // fallback: JSON request
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'origin_location_id': originLocationId,
        'destination_location_id': destinationLocationId,
        'departure_date': departureDate,
        'departure_time': departureTime,
        'ride_type': rideType,
        'service_type': serviceType,
        'price': price,
        'kendaraan_mitra_id': kendaraanMitraId,
        'vehicle_name': vehicleName,
        'vehicle_plate': vehiclePlate,
        'vehicle_brand': vehicleBrand,
        'vehicle_type': vehicleType,
        'vehicle_color': vehicleColor,
        'available_seats': availableSeats,
        'bagasi_capacity': bagasiCapacity,
        'jumlah_bagasi': jumlahBagasi ?? bagasiCapacity,
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
          'Failed to create ride: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Get all passengers for a specific ride (for mobil only)
  static Future<List<Map<String, dynamic>>> getRidePassengers(
      int rideId, String rideType) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/rides/$rideId/passengers?ride_type=$rideType');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
    }
    return [];
  }

  /// Fetch available rides for reschedule
  static Future<List<Map<String, dynamic>>> fetchAvailableRides(
      int bookingId, String bookingType,
      {String? date}) async {
    final uri = Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/bookings/$bookingId/available-rides')
        .replace(queryParameters: {
      'booking_type': bookingType,
      if (date != null) 'date': date,
    });

    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode == 200) {
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      } catch (e) {
        // ignore and return empty
      }
    }
    return [];
  }

  /// Start trip (driver marks trip as started)
  static Future<Map<String, dynamic>> startTrip({
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
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/$endpoint/$bookingId/start-trip');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? 'Failed to start trip');
    }
    throw Exception('Failed to start trip: ${resp.statusCode}');
  }

  /// Complete trip (driver marks trip as completed)
  static Future<Map<String, dynamic>> completeTrip({
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
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/$endpoint/$bookingId/complete-trip');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? 'Failed to complete trip');
    }
    throw Exception('Failed to complete trip: ${resp.statusCode}');
  }
}
