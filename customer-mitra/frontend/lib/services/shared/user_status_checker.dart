import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import '../../screens/auth/blocked_user_page.dart';

/// Service untuk mengecek status user secara berkala
class UserStatusChecker {
  static DateTime? _lastCheck;
  static const Duration _checkInterval = Duration(minutes: 1);

  /// Check user status dari backend
  static Future<Map<String, dynamic>?> checkUserStatus(String token) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 403) {
        // User is blocked
        try {
          final body = json.decode(response.body);
          return {
            'is_blocked': true,
            'reason': body['blocked_reason'] ?? 'Akun Anda telah diblokir',
            'blocked_at': body['blocked_at'],
          };
        } catch (_) {
          return {
            'is_blocked': true,
            'reason': 'Akun Anda telah diblokir',
            'blocked_at': null,
          };
        }
      } else if (response.statusCode == 200) {
        return {'is_blocked': false};
      }

      return null;
    } catch (e) {
      print('Error checking user status: $e');
      return null;
    }
  }

  /// Check status and navigate to blocked page if necessary
  static Future<void> checkAndHandleBlockedStatus(BuildContext context) async {
    // Don't check too frequently
    if (_lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < _checkInterval) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('api_token');

    if (token == null || token.isEmpty) {
      return;
    }

    _lastCheck = DateTime.now();

    final status = await checkUserStatus(token);
    if (status != null && status['is_blocked'] == true) {
      // Clear local storage
      await prefs.clear();

      // Navigate to blocked page
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => BlockedUserPage(
              reason: status['reason'] ?? 'Akun Anda telah diblokir',
              blockedAt: status['blocked_at'] != null
                  ? DateTime.tryParse(status['blocked_at'])
                  : null,
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  /// Force check immediately (bypass interval)
  static Future<void> forceCheck(BuildContext context) async {
    _lastCheck = null;
    await checkAndHandleBlockedStatus(context);
  }
}
