import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Reschedule Service - handles booking reschedule operations
class RescheduleService {
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
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/bookings/$bookingId/reschedule');

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
}
