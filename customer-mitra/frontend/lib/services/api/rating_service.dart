import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Rating Service - handles rating and reviews
class RatingService {
  /// Submit rating for a driver
  static Future<Map<String, dynamic>> submitRating({
    required String token,
    required int bookingId,
    required String bookingType,
    required int driverId,
    required int rating,
    String? review,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ratings');

    final resp = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'booking_id': bookingId,
        'booking_type': bookingType,
        'driver_id': driverId,
        'rating': rating,
        'review': review,
      }),
    );

    final body = json.decode(resp.body);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
    }

    throw Exception(body['message'] ?? 'Failed to submit rating');
  }

  /// Get rating for a specific booking
  static Future<Map<String, dynamic>?> getRating({
    required int bookingId,
    required String bookingType,
  }) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/ratings/booking/$bookingId?booking_type=$bookingType');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
    }

    // Rating not found is ok, return null
    if (resp.statusCode == 404) {
      return null;
    }

    throw Exception('Failed to get rating: ${resp.statusCode}');
  }

  /// Get all ratings for a driver
  static Future<Map<String, dynamic>> getDriverRatings({
    required int driverId,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/ratings/driver/$driverId');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body['data'] ?? {});
      }
      throw Exception(body['message'] ?? 'Failed to get driver ratings');
    }

    throw Exception('Failed to get driver ratings: ${resp.statusCode}');
  }
}
