import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Authentication Service - handles login, logout, PIN management
class AuthService {
  /// Login with email and password
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login');
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/logout');
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

  /// Check if user has PIN
  static Future<bool> checkPin({required String token}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/pin/check');
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/pin/create');
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/pin/verify');
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
}
