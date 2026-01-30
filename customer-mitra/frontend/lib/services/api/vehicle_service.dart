import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Vehicle Service - handles vehicle management
class VehicleService {
  /// Fetch vehicles for authenticated user
  static Future<List<Map<String, dynamic>>> fetchVehicles({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/vehicles');
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/vehicles');
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

  /// Delete vehicle (Request deletion with reason)
  static Future<bool> deleteVehicle({
    required String token,
    required int vehicleId,
    required String deletionReason,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/vehicles/$vehicleId');
    final resp = await http.delete(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'deletion_reason': deletionReason,
      }),
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
}
