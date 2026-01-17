import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PaymentService {
  // Use the centralized ApiService.baseUrl which handles platform-specific
  // host routing (10.0.2.2 for Android emulator, localhost for web/ios).
  static String get baseUrl => '${ApiService.baseUrl}/api/v1';

  Future<Map<String, dynamic>> createPayment({
    required int rideId,
    required int userId,
    required String bookingNumber,
    int? bookingId,
    required String paymentMethod,
    required double amount,
    double? adminFee,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'ride_id': rideId,
          'user_id': userId,
          'booking_number': bookingNumber,
          if (bookingId != null) 'booking_id': bookingId,
          'payment_method': paymentMethod,
          'amount': amount,
          'admin_fee': adminFee ?? 15000,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to create payment',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(int paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to check payment status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}
