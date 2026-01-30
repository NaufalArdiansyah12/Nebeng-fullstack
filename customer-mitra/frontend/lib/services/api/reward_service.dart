import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Reward Service - handles rewards and redemptions
class RewardService {
  /// Fetch available rewards (merchandise)
  static Future<List<Map<String, dynamic>>> fetchRewards() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rewards');
    final resp = await http.get(uri, headers: {'Accept': 'application/json'});
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to fetch rewards: ${resp.statusCode}');
  }

  /// Redeem reward (requires Bearer token)
  static Future<Map<String, dynamic>> redeemReward({
    required String token,
    required int rewardId,
    Map<String, dynamic>? metadata,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/rewards/$rewardId/redeem');
    final resp = await http.post(uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(metadata ?? {}));

    final body = json.decode(resp.body);
    if ((resp.statusCode == 200 || resp.statusCode == 201) &&
        body is Map &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['data']);
    }
    throw Exception(body['message'] ?? 'Failed to redeem reward');
  }

  /// Fetch current user's redemptions
  static Future<List<Map<String, dynamic>>> fetchMyRedemptions({
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/rewards/my');
    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (resp.statusCode == 200) {
      final body = json.decode(resp.body);
      if (body is Map && body['success'] == true && body['data'] is List) {
        return List<Map<String, dynamic>>.from(body['data']);
      }
      throw Exception('Unexpected response format');
    }
    throw Exception('Failed to fetch redemptions: ${resp.statusCode}');
  }
}
