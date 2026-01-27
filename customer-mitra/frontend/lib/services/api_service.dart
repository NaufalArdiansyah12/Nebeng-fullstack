import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Auto-detect platform and use appropriate URL
  // Android emulator uses 10.0.2.2 to access host machine
  // Web and other platforms use localhost
  static String get baseUrl {
    // Allow overriding at build/runtime via --dart-define=API_BASE_URL
    const _envBase = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (_envBase.isNotEmpty) return _envBase;

    // Web builds run in browser — use localhost
    if (kIsWeb) return 'http://localhost:8000';

    // Native platforms: if Android emulator, use 10.0.2.2 to reach host
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    // Fallback: localhost
    return 'http://localhost:8000';
  }

  /// Fetch available rewards (merchandise)
  static Future<List<Map<String, dynamic>>> fetchRewards() async {
    final uri = Uri.parse('$baseUrl/api/v1/rewards');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to fetch rewards: ${resp.statusCode}');
  }

  /// Redeem reward (requires Bearer token)
  static Future<Map<String, dynamic>> redeemReward({
    required String token,
    required int rewardId,
    Map<String, dynamic>? metadata,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/rewards/$rewardId/redeem');
    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(metadata ?? {}));

    final body = json.decode(resp.body);
    if ((resp.statusCode == 200 || resp.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to redeem reward');
  }

  /// Fetch current user's redemptions
  static Future<List<Map<String, dynamic>>> fetchMyRedemptions({
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/rewards/my');
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
    throw Exception('Failed to fetch redemptions: ${resp.statusCode}');
  }

  /// Fetch locations from backend
  /// returns List<Map<String, dynamic>> where each map contains location fields
  static Future<List<Map<String, dynamic>>> fetchLocations() async {
    final uri = Uri.parse('$baseUrl/api/v1/locations');
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

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/login');
    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: json.encode({'email': email, 'password': password}));

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] != null) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception('Unexpected login response');
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception('Login failed: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Logout: call backend logout endpoint with bearer token (if present)
  static Future<bool> logout(String? token) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/logout');
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final resp = await http.post(uri, headers: headers);
    if (resp.statusCode == 200) {
      return true;
    }
    return false;
  }

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

    final uri = Uri.parse('$baseUrl/api/v1/rides')
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
    String?
        status, // expected values: 'selesai','proses','dibatalkan','kosong' or null
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/api/v1/mitra/riwayat')
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
    final uri = Uri.parse('$baseUrl/api/v1/rides');

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
    final uri = Uri.parse('$baseUrl/api/v1/bookings');

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

  /// Fetch vehicles for authenticated user
  static Future<List<Map<String, dynamic>>> fetchVehicles({
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/vehicles');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      try {
        final body = json.decode(resp.body);
        if (body is Map && body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
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
          'Failed to fetch vehicles: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Fetch bookings for authenticated user.
  /// Optional `type` query param: semua|motor|mobil|barang|titip
  static Future<List<Map<String, dynamic>>> fetchBookings({
    required String token,
    String? type,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bookings/my')
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
    final uri = Uri.parse('$baseUrl/api/v1/bookings/$bookingId');

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

  /// Fetch latest location for a booking (used by tracking page)
  /// Expected response: { lat, lng, timestamp, status, tracking_active }
  static Future<Map<String, dynamic>> fetchBookingLocation({
    required int bookingId,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bookings/$bookingId/location');
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

  /// Create vehicle
  static Future<Map<String, dynamic>> createVehicle({
    required String token,
    required String vehicleType,
    required String name,
    required String plateNumber,
    required String brand,
    required String model,
    required String color,
    int? year,
    required int seats,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/vehicles');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'vehicle_type': vehicleType,
        'name': name,
        'plate_number': plateNumber,
        'brand': brand,
        'model': model,
        'color': color,
        'year': year,
        'seats': seats,
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
          'Failed to create vehicle: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Report mitra last location. Returns true when backend accepted the update.
  static Future<bool> reportMitraLocation({
    required String token,
    required double lat,
    required double lng,
    DateTime? at,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/mitra/location');
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

  /// Delete vehicle
  static Future<bool> deleteVehicle({
    required String token,
    required int vehicleId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/vehicles/$vehicleId');
    final resp = await http.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      return true;
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to delete vehicle: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/change-password');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      }),
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return {
        'success': true,
        'message': body['message'] ?? 'Password berhasil diubah',
      };
    } else {
      try {
        final body = json.decode(resp.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengubah password',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Gagal mengubah password: ${resp.statusCode}',
        };
      }
    }
  }

  /// Update profile with optional photo (multipart)
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? name,
    String? email,
    String? address,
    String? phone,
    String? gender,
    String? photoFilePath, // local file path
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/update-profile');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (name != null) request.fields['name'] = name;
    if (email != null) request.fields['email'] = email;
    if (address != null) request.fields['address'] = address;
    if (phone != null) request.fields['phone'] = phone;
    if (gender != null) request.fields['gender'] = gender;

    if (photoFilePath != null) {
      final file =
          await http.MultipartFile.fromPath('profile_photo', photoFilePath);
      request.files.add(file);
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return Map<String, dynamic>.from(body);
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to update profile: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Get current authenticated user's profile
  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/auth/me');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return Map<String, dynamic>.from(body);
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to get profile: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Check if user has PIN
  static Future<bool> checkPin({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/v1/pin/check');
    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return body['has_pin'] ?? false;
    }
    return false;
  }

  /// Create PIN
  static Future<Map<String, dynamic>> createPin({
    required String token,
    required String hashedPin,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/pin/create');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'pin': hashedPin,
      }),
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return {
        'success': true,
        'message': body['message'] ?? 'PIN berhasil dibuat',
      };
    } else {
      try {
        final body = json.decode(resp.body);
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal membuat PIN',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Gagal membuat PIN: ${resp.statusCode}',
        };
      }
    }
  }

  /// Verify PIN
  static Future<bool> verifyPin({
    required String token,
    required String hashedPin,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/pin/verify');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'pin': hashedPin,
      }),
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return body['success'] ?? false;
    }
    return false;
  }

  /// Get all passengers for a specific ride (for mobil only)
  static Future<List<Map<String, dynamic>>> getRidePassengers(
      int rideId, String rideType) async {
    final uri = Uri.parse(
        '$baseUrl/api/v1/rides/$rideId/passengers?ride_type=$rideType');
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
    final uri = Uri.parse('$baseUrl/api/v1/bookings/$bookingId/available-rides')
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

  /// Create a reschedule request (requires auth token)
  static Future<Map<String, dynamic>> createReschedule({
    required String token,
    required int bookingId,
    required String bookingType,
    required String requestedTargetType,
    required int requestedTargetId,
    String? reason,
    String? barangImagePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bookings/$bookingId/reschedule');

    if (barangImagePath != null && barangImagePath.isNotEmpty) {
      // Upload as multipart request with optional image
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      request.fields['booking_type'] = bookingType;
      request.fields['requested_target_type'] = requestedTargetType;
      request.fields['requested_target_id'] = requestedTargetId.toString();
      if (reason != null) request.fields['reason'] = reason;

      final file = File(barangImagePath);
      if (await file.exists()) {
        request.files
            .add(await http.MultipartFile.fromPath('photo', barangImagePath));
      }

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final body = json.decode(resp.body);
      if ((resp.statusCode == 200 || resp.statusCode == 201) &&
          body is Map &&
          body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      }
      throw Exception(body['message'] ?? 'Failed to create reschedule');
    }

    // Fallback to JSON POST when no image
    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'booking_type': bookingType,
          'requested_target_type': requestedTargetType,
          'requested_target_id': requestedTargetId,
          if (reason != null) 'reason': reason,
        }));

    final body = json.decode(resp.body);
    if (resp.statusCode == 201 && body is Map && body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create reschedule');
  }

  /// Create payment for a reschedule (or booking)
  static Future<Map<String, dynamic>> createPayment({
    required int rideId,
    required int userId,
    String? bookingNumber,
    int? bookingId,
    required String paymentMethod,
    required double amount,
    int? adminFee,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/payments');
    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'ride_id': rideId,
          'user_id': userId,
          if (bookingNumber != null) 'booking_number': bookingNumber,
          if (bookingId != null) 'booking_id': bookingId,
          'payment_method': paymentMethod,
          'amount': amount,
          if (adminFee != null) 'admin_fee': adminFee,
        }));

    final body = json.decode(resp.body);
    if ((resp.statusCode == 200 || resp.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to create payment');
  }

  /// Confirm reschedule payment (apply reschedule)
  static Future<Map<String, dynamic>> confirmReschedulePayment({
    required int requestId,
    required String paymentTxnId,
    List<Map<String, dynamic>>? passengers,
  }) async {
    final uri =
        Uri.parse('$baseUrl/api/v1/reschedule/$requestId/confirm-payment');

    final body = <String, dynamic>{
      'payment_txn_id': paymentTxnId,
    };

    if (passengers != null && passengers.isNotEmpty) {
      body['passengers'] = passengers;
    }

    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: json.encode(body));

    final decoded = (resp.body.isNotEmpty) ? json.decode(resp.body) : {};
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return Map<String, dynamic>.from(decoded as Map);
    }
    throw Exception(decoded['message'] ?? 'Failed to confirm reschedule');
  }

  /// Update booking status
  static Future<Map<String, dynamic>> updateBookingStatus({
    required int bookingId,
    required String status,
    required String token,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/bookings/$bookingId/status');
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

  /// Send driver location update for booking
  static Future<bool> updateBookingLocation({
    required int bookingId,
    required String token,
    required double lat,
    required double lng,
    DateTime? timestamp,
    double? accuracy,
    double? speed,
    String bookingType = 'motor', // 'motor', 'mobil', 'barang', or 'titip'
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

      final uri = Uri.parse('$baseUrl/api/v1/$endpoint/$bookingId/location');
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

  /// Get comprehensive tracking info for a booking
  static Future<Map<String, dynamic>> getBookingTracking({
    required int bookingId,
    required String token,
    String bookingType = 'motor', // 'motor', 'mobil', 'barang', or 'titip'
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
    final uri = Uri.parse('$baseUrl/api/v1/$endpoint/$bookingId/tracking');
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
    final uri = Uri.parse('$baseUrl/api/v1/$endpoint/$bookingId/start-trip');
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
    final uri = Uri.parse('$baseUrl/api/v1/$endpoint/$bookingId/complete-trip');
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

  /// Fetch transaction history for customer
  static Future<List<Map<String, dynamic>>> fetchTransactionHistory({
    required String token,
    String? status, // 'all', 'completed', 'cancelled'
  }) async {
    final queryParams = status != null ? '?status=$status' : '';
    final uri = Uri.parse('$baseUrl/api/v1/transactions/history$queryParams');

    print('🌐 API Request: GET $uri');
    print('🔑 Token (first 20 chars): ${token.substring(0, 20)}...');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('📥 Response Status: ${resp.statusCode}');
    print('📥 Response Body: ${resp.body}');

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to fetch transaction history: ${resp.statusCode}');
  }
}
