import 'package:flutter/material.dart';
import '../../../services/posmitra/posmitra_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({Key? key}) : super(key: key);

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Withdrawal Notifications ---
  List<Map<String, dynamic>> notifications = [];
  bool isLoadingNotif = true;
  String? errorNotif;

  // --- Upcoming Rides ---
  List<Map<String, dynamic>> upcomingRides = [];
  bool isLoadingRides = true;
  String? errorRides;

  // 🔔 Status sudah dibaca per tab
  bool _notifRead = false;
  bool _ridesRead = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    _loadUpcomingRides();

    // Saat tab pertama (index 0) langsung dianggap dilihat
    _notifRead = true;

    // Listener saat user pindah tab
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        if (_tabController.index == 0) {
          _notifRead = true;
        } else if (_tabController.index == 1) {
          _ridesRead = true;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LOAD DATA
  // ─────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    setState(() {
      isLoadingNotif = true;
      errorNotif = null;
    });
    try {
      final result = await PosMitraService.getWithdrawalNotifications();
      if (mounted) {
        setState(() {
          notifications = result;
          isLoadingNotif = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorNotif = e.toString().replaceAll('Exception: ', '');
          isLoadingNotif = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingRides() async {
    setState(() {
      isLoadingRides = true;
      errorRides = null;
    });
    try {
      final result = await PosMitraService.getUpcomingRides();
      if (mounted) {
        setState(() {
          upcomingRides = result;
          isLoadingRides = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorRides = e.toString().replaceAll('Exception: ', '');
          isLoadingRides = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 16),
                  const SizedBox(width: 6),
                  const Text('Pencairan'),
                  // Badge hanya tampil jika belum dibaca DAN ada data
                  if (!_notifRead && notifications.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge(notifications.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car, size: 16),
                  const SizedBox(width: 6),
                  const Text('Tebengan'),
                  // Badge hanya tampil jika belum dibaca DAN ada data
                  if (!_ridesRead && upcomingRides.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildBadge(upcomingRides.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotifTab(),
          _buildRidesTab(),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB: PENCAIRAN
  // ─────────────────────────────────────────────

  Widget _buildNotifTab() {
    if (isLoadingNotif) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
    }
    if (errorNotif != null) {
      return _buildErrorState(errorNotif!, _loadNotifications);
    }
    if (notifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        title: 'Tidak ada notifikasi',
        subtitle: 'Riwayat pencairan dana akan muncul di sini',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF1E3A8A),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildNotificationCard(notifications[i]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TAB: TEBENGAN
  // ─────────────────────────────────────────────

  Widget _buildRidesTab() {
    if (isLoadingRides) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E3A8A)));
    }
    if (errorRides != null) {
      return _buildErrorState(errorRides!, _loadUpcomingRides);
    }
    if (upcomingRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.directions_car_outlined,
        title: 'Tidak ada tebengan',
        subtitle: 'Tebengan yang akan datang akan muncul di sini',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadUpcomingRides,
      color: const Color(0xFF1E3A8A),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: upcomingRides.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildRideCard(upcomingRides[i]),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CARD: WITHDRAWAL NOTIFICATION
  // ─────────────────────────────────────────────

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final status = notification['status']?.toString() ?? '';
    final type = notification['type']?.toString() ?? 'withdrawal';

    Color cardColor = const Color(0xFFE3F2FD);
    Color statusColor = const Color(0xFF1E3A8A);

    if (status == 'Berhasil') {
      cardColor = const Color(0xFFE8F5E9);
      statusColor = const Color(0xFF66BB6A);
    } else if (status == 'Diproses') {
      cardColor = const Color(0xFFFFF3E0);
      statusColor = const Color(0xFFFF9800);
    } else if (status == 'Ditolak') {
      cardColor = const Color(0xFFFFEBEE);
      statusColor = const Color(0xFFEF5350);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  type == 'withdrawal'
                      ? Icons.account_balance_wallet
                      : Icons.notifications,
                  size: 20,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'] ?? 'Notifikasi',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notification['message'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF424242),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Color(0xFF757575)),
              const SizedBox(width: 6),
              Text(
                notification['time'] ?? '',
                style:
                    const TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CARD: UPCOMING RIDE
  // ─────────────────────────────────────────────

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final origin = ride['origin']?.toString() ?? '-';
    final destination = ride['destination']?.toString() ?? '-';
    final departureTime = ride['departure_time']?.toString() ?? '';
    final driverName = ride['driver_name']?.toString() ?? 'Driver';
    final seats = ride['available_seats']?.toString() ?? '0';
    final price = ride['price']?.toString() ?? '';
    final status = ride['status']?.toString() ?? 'Tersedia';

    Color statusColor = const Color(0xFF66BB6A);
    if (status == 'Penuh') statusColor = const Color(0xFFEF5350);
    if (status == 'Segera') statusColor = const Color(0xFFFF9800);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header biru: rute
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.trip_origin, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    origin,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child:
                      Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
                ),
                Expanded(
                  child: Text(
                    destination,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Body: detail info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _rideDetailRow(Icons.person_outline, 'Driver', driverName),
                const SizedBox(height: 8),
                _rideDetailRow(
                  Icons.access_time,
                  'Waktu',
                  departureTime.isNotEmpty ? departureTime : '-',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _rideDetailRow(
                          Icons.event_seat_outlined, 'Kursi', '$seats tersedia'),
                    ),
                    if (price.isNotEmpty)
                      Expanded(
                        child: _rideDetailRow(
                            Icons.monetization_on_outlined, 'Harga', price),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Footer: status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // COMMON STATES
  // ─────────────────────────────────────────────

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}