import 'dart:convert';
import 'dart:io';
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

  /// Submit rating for a customer (by mitra)
  static Future<Map<String, dynamic>> submitCustomerRating({
    required int bookingId,
    required int customerId,
    required int mitraId,
    required int rating,
    required String token,
    String? feedback,
    dynamic proofImage,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/customer-ratings');

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    request.fields['booking_id'] = bookingId.toString();
    request.fields['customer_id'] = customerId.toString();
    request.fields['mitra_id'] = mitraId.toString();
    request.fields['rating'] = rating.toString();
    if (feedback != null && feedback.isNotEmpty) {
      request.fields['feedback'] = feedback;
    }

    // Add proof image if provided
    if (proofImage != null && proofImage is File) {
      request.files.add(
        await http.MultipartFile.fromPath('proof_image', proofImage.path),
      );
    }

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);
    final body = json.decode(resp.body);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
    }

    throw Exception(body['message'] ?? 'Failed to submit customer rating');
  }

  /// Get customer rating for a specific booking
  static Future<Map<String, dynamic>?> getCustomerRatingByBooking({
    required int bookingId,
    required String token,
  }) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/customer-ratings/booking/$bookingId');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
    }

    // Rating not found is ok, return null
    if (resp.statusCode == 404) {
      return null;
    }

    return null;
  }

  /// Get customer rating for a specific booking by booking number
  static Future<Map<String, dynamic>?> getCustomerRatingByBookingNumber({
    required String bookingNumber,
    required String token,
  }) async {
    final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/customer-ratings/booking-number/$bookingNumber');

    final resp = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true) {
        return Map<String, dynamic>.from(body);
      }
    }

    // Rating not found is ok, return null
    if (resp.statusCode == 404) {
      return null;
    }

    return null;
  }
}
