import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class CreditService {
  /// Fetch mitra credit score
  /// Expected response: { success: true, data: { score: 4.5, history: [...] } }
  static Future<Map<String, dynamic>> getCreditScore(
      {required String token}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/mitra/credit-score');
    final resp = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    try {
      final body = json.decode(resp.body);
      if (body is Map<String, dynamic>) return body;
      return {'success': false, 'message': 'Invalid response'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
