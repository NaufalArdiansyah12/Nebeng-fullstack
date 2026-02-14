import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

class RatingService {
  static Future<bool> checkExistingRating(String? bookingNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      print('DEBUG: Checking rating - token exists: ${token != null}');

      if (token == null || bookingNumber == null || bookingNumber.isEmpty) {
        print('DEBUG: No token or booking number');
        return false;
      }

      print(
          'DEBUG: Calling API to check rating for booking number: $bookingNumber');
      final response = await ApiService.getCustomerRatingByBookingNumber(
        bookingNumber: bookingNumber,
        token: token,
      );

      print('DEBUG: Rating check response: $response');
      final hasRating = response != null && response['success'] == true;
      print('DEBUG: Has rating: $hasRating');
      return hasRating;
    } catch (e) {
      print('ERROR checking rating: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> submitRating({
    required String bookingNumber,
    required int customerId,
    required int rating,
    required Set<String> feedback,
    File? proofImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');
    final mitraId = prefs.getInt('user_id');

    if (token == null || mitraId == null) {
      throw Exception('Token atau user ID tidak ditemukan');
    }

    print('📤 Submitting rating:');
    print('  - Booking: $bookingNumber');
    print('  - Customer ID: $customerId');
    print('  - Mitra ID: $mitraId');
    print('  - Rating: $rating');
    print('  - Feedback: $feedback');

    final response = await ApiService.submitCustomerRating(
      bookingId: int.tryParse(bookingNumber) ?? 0,
      customerId: customerId,
      mitraId: mitraId,
      rating: rating,
      feedback: feedback.join(', '),
      proofImage: proofImage,
      token: token,
    );

    print('✅ Rating submitted successfully: $response');
    return response;
  }
}
