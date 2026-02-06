import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification_model.dart' as notif_model;
import '../../services/shared/notification_api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
          // Navigate to booking detail if booking_id exists
          if (notification.bookingId != null) {
            // TODO: Navigate to booking detail page
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) => BookingDetailPage(bookingId: notification.bookingId!),
            //   ),
            // );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: notification.isRead
                ? Border.all(color: Colors.grey[200]!, width: 1)
                : Border.all(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    width: 1.5),
            boxShadow: [
              BoxShadow(
                color: notification.isRead
                    ? Colors.grey.withOpacity(0.08)
                    : const Color(0xFF1E3A8A).withOpacity(0.1),
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
                if (notification.bookingId != null) {
                  // TODO: Navigate to booking detail
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon or emoji with better styling
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: notification.isRead
                              ? [Colors.grey[100]!, Colors.grey[200]!]
                              : [
                                  const Color(0xFF1E3A8A).withOpacity(0.1),
                                  const Color(0xFF3B82F6).withOpacity(0.1),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          notification.icon ?? '🔔',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
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
                              height: 1.4,
                            ),
                          ),
                          if (notification.bookingNumber != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF1E3A8A).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_outlined,
                                    size: 12,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    notification.bookingNumber!,
                                    style: const TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
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
}
