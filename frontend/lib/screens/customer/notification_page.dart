import 'package:flutter/material.dart';
import '../../models/notification_model.dart' as notif_model;

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<notif_model.Notification> notifications = [
    notif_model.Notification(
      id: 1,
      title: 'Refund Diterima',
      message:
          'Nebeng Bagaimana perjalanan Anda dengan Rudi? Berikan rating dan ulasan Anda untuk membantu kami meningkatkan layanan.',
      type: notif_model.NotificationType.refund,
      createdAt: DateTime(2022, 8, 5, 12, 0),
      isRead: false,
    ),
    notif_model.Notification(
      id: 2,
      title: 'Promo Menarik😍😍',
      message:
          '🎉 Promo Spesial! Dapatkan diskon 20% untuk perjalanan pertama Anda.',
      type: notif_model.NotificationType.promo,
      createdAt: DateTime(2024, 8, 2, 12, 30),
      isRead: true,
    ),
    notif_model.Notification(
      id: 3,
      title: 'Promo Natal🎄🎄',
      message:
          '🎄 Selamat Natal! Dapatkan diskon 25% untuk semua perjalanan selama periode liburan.',
      type: notif_model.NotificationType.promo,
      createdAt: DateTime(2024, 8, 5, 12, 30),
      isRead: true,
    ),
    notif_model.Notification(
      id: 4,
      title: 'Nebeng',
      message:
          'Bagaimana perjalanan Anda dengan Rudi? Berikan rating dan ulasan Anda untuk membantu kami meningkatkan layanan.',
      type: notif_model.NotificationType.announcement,
      createdAt: DateTime(2022, 8, 3, 12, 30),
      isRead: true,
    ),
    notif_model.Notification(
      id: 5,
      title: 'Nebeng Motor',
      message:
          'Anda memiliki perjalanan terjadwal dengan pengemudi Jamal Driver Pada 25 Juli pukul 09:00-09:10WIB Jangan lupa untuk siap tepat waktu!',
      type: notif_model.NotificationType.announcement,
      createdAt: DateTime(2022, 8, 24, 12, 30),
      isRead: true,
    ),
  ];

  String _getTimeAgo(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getNotificationColor(notif_model.NotificationType type) {
    return const Color(
        0xFFE8EAF6); // Light blue-grey color for all notifications
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada notifikasi',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
    );
  }

  Widget _buildNotificationCard(notif_model.Notification notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getNotificationColor(notification.type),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification.title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notification.message,
            style: const TextStyle(
              color: Color(0xFF424242),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                _getTimeAgo(notification.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
