import 'dart:convert';
import 'package:http/http.dart' as http;
import '../shared/api_config.dart';

/// Saved Passenger Service - handles saved passengers management
class SavedPassengerService {
  /// Get all saved passengers for authenticated user
  static Future<List<Map<String, dynamic>>> getSavedPassengers({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/saved-passengers');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body['success'] == true && body['data'] != null) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get saved passengers: ${resp.statusCode}');
    }
  }

  /// Save a new passenger
  static Future<Map<String, dynamic>> savePassenger({
    required String token,
    required String name,
    required String phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/saved-passengers');
    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'phone': phone,
      }),
    );

    final body = json.decode(resp.body);

    if (resp.statusCode == 201) {
      return body;
    } else if (resp.statusCode == 409) {
      // Duplicate - return success anyway
      return {
        'success': true,
        'message': 'Penumpang sudah tersimpan',
      };
    } else {
      throw Exception(body['message'] ?? 'Failed to save passenger');
    }
  }

  /// Delete a saved passenger
  static Future<bool> deletePassenger({
    required String token,
    required int passengerId,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/saved-passengers/$passengerId');
    final resp = await http.delete(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete passenger: ${resp.statusCode}');
    }
  }
}
