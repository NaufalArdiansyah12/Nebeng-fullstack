import 'dart:convert';

enum NotificationType {
  refund,
  promo,
  announcement,
  other,
}

class Notification {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final String? icon;
  final int? bookingId;
  final String? bookingNumber;
  final String? status;
  final Map<String, dynamic>? data;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.icon,
    this.bookingId,
    this.bookingNumber,
    this.status,
    this.data,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    // Parse data field - it might be a string or already a map
    Map<String, dynamic>? parsedData;
    if (json['data'] != null) {
      if (json['data'] is String) {
        try {
          parsedData = jsonDecode(json['data']) as Map<String, dynamic>;
        } catch (e) {
          parsedData = null;
        }
      } else if (json['data'] is Map) {
        parsedData = Map<String, dynamic>.from(json['data']);
      }
    }

    return Notification(
      id: json['id'],
      title: json['title'],
      message: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'other',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      icon: json['icon'],
      bookingId: json['booking_id'],
      bookingNumber: json['booking_number'],
      status: json['status'],
      data: parsedData,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'icon': icon,
      'booking_id': bookingId,
      'booking_number': bookingNumber,
      'status': status,
      'data': data,
      'read_at': readAt?.toIso8601String(),
    };
  }

  // For backward compatibility with old NotificationType enum
  NotificationType get notificationType {
    switch (type) {
      case 'refund':
        return NotificationType.refund;
      case 'promo':
        return NotificationType.promo;
      case 'booking_status_update':
      case 'announcement':
        return NotificationType.announcement;
      default:
        return NotificationType.other;
    }
  }
}
