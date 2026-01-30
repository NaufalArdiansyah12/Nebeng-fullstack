import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Profile Service - handles profile management
class ProfileService {
  /// Get current authenticated user's profile
  static Future<Map<String, dynamic>> getProfile({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me');
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

  /// Get user by ID
  static Future<Map<String, dynamic>> getUserById(
    int userId,
    String token,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/$userId');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['data'] != null) {
        return Map<String, dynamic>.from(body['data']);
      }
      return Map<String, dynamic>.from(body);
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to get user: ${resp.statusCode}. Preview: $preview');
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/update-profile');
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

  /// Upload profile photo
  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required String photoFilePath,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/update-profile');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    final file =
        await http.MultipartFile.fromPath('profile_photo', photoFilePath);
    request.files.add(file);

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      return Map<String, dynamic>.from(body);
    } else {
      final preview =
          resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body;
      throw Exception(
          'Failed to upload photo: ${resp.statusCode}. Preview: $preview');
    }
  }

  /// Change password
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/change-password');
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
}
