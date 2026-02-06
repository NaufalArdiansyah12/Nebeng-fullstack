import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/notification_model.dart' as notif_model;
import 'api_config.dart';

class NotificationApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Fetch all notifications for the authenticated user
  static Future<Map<String, dynamic>> fetchNotifications({
    required String token,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/notifications?page=$page&per_page=$perPage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['unread_count'] as int;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  static Future<bool> markAsRead({
    required String token,
    required int notificationId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  static Future<bool> markAllAsRead({required String token}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification({
    required String token,
    required int notificationId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  /// Clear all read notifications
  static Future<bool> clearReadNotifications({required String token}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/notifications/clear-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing read notifications: $e');
      return false;
    }
  }
}
