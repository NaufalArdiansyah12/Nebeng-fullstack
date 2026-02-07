import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart' as notif_model;
import '../../services/shared/notification_api_service.dart';

class MitraNotificationPage extends StatefulWidget {
  const MitraNotificationPage({Key? key}) : super(key: key);

  @override
  State<MitraNotificationPage> createState() => _MitraNotificationPageState();
}

class _MitraNotificationPageState extends State<MitraNotificationPage> {
  List<notif_model.Notification> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  String? token;
  int currentPage = 1;
  bool hasMorePages = true;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('api_token');

      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Token tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      // Fetch notifications from API
      final response = await NotificationApiService.fetchNotifications(
        token: token!,
        page: currentPage,
        perPage: 20,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> notifList = data['data'];

        setState(() {
          notifications = notifList
              .map((json) => notif_model.Notification.fromJson(json))
              .toList();
          hasMorePages = data['next_page_url'] != null;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat notifikasi';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoadingMore || !hasMorePages) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      currentPage++;
      final response = await NotificationApiService.fetchNotifications(
        token: token!,
        page: currentPage,
        perPage: 20,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final List<dynamic> notifList = data['data'];

        setState(() {
          notifications.addAll(
            notifList
                .map((json) => notif_model.Notification.fromJson(json))
                .toList(),
          );
          hasMorePages = data['next_page_url'] != null;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingMore = false;
        currentPage--;
      });
    }
  }

  Future<void> _markAsRead(notif_model.Notification notification) async {
    if (notification.isRead || token == null) return;

    final success = await NotificationApiService.markAsRead(
      token: token!,
      notificationId: notification.id,
    );

    if (success) {
      setState(() {
        final index = notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          notifications[index] = notif_model.Notification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            createdAt: notification.createdAt,
            isRead: true,
            icon: notification.icon,
            bookingId: notification.bookingId,
            bookingNumber: notification.bookingNumber,
            status: notification.status,
            data: notification.data,
            readAt: DateTime.now(),
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (token == null) return;

    final success = await NotificationApiService.markAllAsRead(token: token!);

    if (success) {
      setState(() {
        notifications = notifications.map((n) {
          return notif_model.Notification(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            createdAt: n.createdAt,
            isRead: true,
            icon: n.icon,
            bookingId: n.bookingId,
            bookingNumber: n.bookingNumber,
            status: n.status,
            data: n.data,
            readAt: DateTime.now(),
          );
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Semua notifikasi ditandai sebagai dibaca')),
      );
    }
  }

  Future<void> _deleteNotification(
      notif_model.Notification notification) async {
    if (token == null) return;

    final success = await NotificationApiService.deleteNotification(
      token: token!,
      notificationId: notification.id,
    );

    if (success) {
      setState(() {
        notifications.removeWhere((n) => n.id == notification.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifikasi dihapus')),
      );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Function to get appropriate icon for mitra notifications
  String _getMitraIcon(String type) {
    switch (type) {
      case 'vehicle_approved':
        return '✅';
      case 'vehicle_rejected':
        return '❌';
      case 'withdrawal_success':
        return '💰';
      case 'withdrawal_failed':
        return '⚠️';
      case 'new_booking':
        return '🎫';
      case 'booking_cancelled':
        return '🚫';
      case 'booking_completed':
        return '🎉';
      case 'rating_received':
        return '⭐';
      case 'payment_received':
        return '💵';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'vehicle_approved':
      case 'withdrawal_success':
      case 'booking_completed':
      case 'payment_received':
        return Colors.green;
      case 'vehicle_rejected':
      case 'withdrawal_failed':
      case 'booking_cancelled':
        return Colors.red;
      case 'new_booking':
      case 'rating_received':
        return const Color(0xFF1E3A8A);
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  _markAllAsRead();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Text('Tandai Semua Dibaca'),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : notifications.isEmpty
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
                          const SizedBox(height: 8),
                          Text(
                            'Notifikasi akan muncul di sini',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        currentPage = 1;
                        await _loadNotifications();
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!isLoadingMore &&
                              hasMorePages &&
                              scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent) {
                            _loadMoreNotifications();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              notifications.length + (hasMorePages ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == notifications.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final notification = notifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard(notif_model.Notification notification) {
    final iconEmoji = notification.icon ?? _getMitraIcon(notification.type);
    final notifColor = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'Hapus',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: GestureDetector(
        onTap: () {
          _markAsRead(notification);
          // Navigate based on notification type
          _handleNotificationTap(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: notification.isRead
                ? Border.all(color: Colors.grey[200]!, width: 1)
                : Border.all(color: notifColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: notification.isRead
                    ? Colors.grey.withOpacity(0.08)
                    : notifColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _markAsRead(notification);
                _handleNotificationTap(notification);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container with dynamic color
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: notification.isRead
                              ? [Colors.grey[100]!, Colors.grey[200]!]
                              : [
                                  notifColor.withOpacity(0.15),
                                  notifColor.withOpacity(0.05),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          iconEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    color: const Color(0xFF1F2937),
                                    fontWeight: notification.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    fontSize: 15,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: notifColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: notification.isRead
                                  ? Colors.grey[600]
                                  : const Color(0xFF374151),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          // Display booking number if available
                          if (notification.bookingNumber != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: notifColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 14,
                                    color: notifColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    notification.bookingNumber!,
                                    style: TextStyle(
                                      color: notifColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeAgo(notification.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(notif_model.Notification notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'vehicle_approved':
      case 'vehicle_rejected':
        // Navigate to vehicle page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleListPage()));
        break;
      case 'withdrawal_success':
      case 'withdrawal_failed':
        // Navigate to withdrawal history
        // Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawalHistoryPage()));
        break;
      case 'new_booking':
      case 'booking_cancelled':
      case 'booking_completed':
        // Navigate to booking detail if booking_id exists
        if (notification.bookingId != null) {
          // Navigator.push(context, MaterialPageRoute(builder: (context) => BookingDetailPage(bookingId: notification.bookingId!)));
        }
        break;
      case 'rating_received':
        // Navigate to rating page
        // Navigator.push(context, MaterialPageRoute(builder: (context) => RatingPage()));
        break;
      default:
        // Do nothing or show detail in dialog
        break;
    }
  }
}
