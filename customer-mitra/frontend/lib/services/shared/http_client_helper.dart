import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/auth/blocked_user_page.dart';

/// HTTP Client that handles blocked user responses globally
class HttpClientHelper {
  /// Make a GET request with automatic blocked user handling
  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    BuildContext? context,
  }) async {
    final response = await http.get(uri, headers: headers);
    await _handleBlockedResponse(response, context);
    return response;
  }

  /// Make a POST request with automatic blocked user handling
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    BuildContext? context,
  }) async {
    final response = await http.post(uri, headers: headers, body: body);
    await _handleBlockedResponse(response, context);
    return response;
  }

  /// Make a PUT request with automatic blocked user handling
  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    BuildContext? context,
  }) async {
    final response = await http.put(uri, headers: headers, body: body);
    await _handleBlockedResponse(response, context);
    return response;
  }

  /// Make a DELETE request with automatic blocked user handling
  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    BuildContext? context,
  }) async {
    final response = await http.delete(uri, headers: headers);
    await _handleBlockedResponse(response, context);
    return response;
  }

  /// Check if response indicates user is blocked and navigate to blocked page
  static Future<void> _handleBlockedResponse(
    http.Response response,
    BuildContext? context,
  ) async {
    if (response.statusCode == 403) {
      try {
        final body = json.decode(response.body);

        // Check if this is a blocked user response
        if (body['blocked_reason'] != null ||
            body['message']?.toString().contains('diblokir') == true) {
          final reason = body['blocked_reason'] ??
              body['message'] ??
              'Akun Anda telah diblokir';
          final blockedAtStr = body['blocked_at'];
          DateTime? blockedAt;

          if (blockedAtStr != null) {
            try {
              blockedAt = DateTime.parse(blockedAtStr);
            } catch (_) {}
          }

          // Clear local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          // Navigate to blocked page if context is available
          if (context != null && context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => BlockedUserPage(
                  reason: reason,
                  blockedAt: blockedAt,
                ),
              ),
              (route) => false,
            );
          }
        }
      } catch (_) {
        // If JSON parsing fails, ignore
      }
    }
  }
}
