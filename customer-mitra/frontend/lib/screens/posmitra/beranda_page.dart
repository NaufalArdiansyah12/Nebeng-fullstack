import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aktivitas/notifikasi_page.dart';
import 'riwayat/riwayat_pencairan_page.dart';
import 'saldo/tarik_saldo_page.dart';
import 'aktivitas_page.dart';
import '/services/api_service.dart';
import '/services/posmitra/posmitra_service.dart';
import '/services/posmitra/notification_service.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({Key? key}) : super(key: key);

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  DateTime selectedDate = DateTime.now();
  bool isSaldoVisible = true;

  double _saldo = 0;
  bool _isLoadingSaldo = true;

  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  List<Map<String, dynamic>> _upcomingRides = [];
  bool _isLoadingRides = true;

  Map<String, dynamic> _statistics = {
    'nebeng_motor': 0,
    'nebeng_mobil': 0,
    'nebeng_barang': 0,
    'titip_barang': 0,
  };
  bool _isLoadingStatistics = true;

  // 🔔 Badge notifikasi
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSaldo();
    _loadUpcomingRides();
    _loadStatistics();
    _loadUnreadCount(); // ← load badge
    // Daftarkan FCM token ke backend (fallback jika belum terkirim saat login/app start)
    PosMitraService.registerFcmToken();

    // 🔔 MULAI POLLING UNTUK NOTIFIKASI TEBENGAN AKAN DATANG
    NotificationService.startUpcomingRidesPolling(intervalMinutes: 5);
  }

  @override
  void dispose() {
    // ⏹️ HENTIKAN POLLING SAAT KELUAR DARI HALAMAN
    NotificationService.stopUpcomingRidesPolling();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LOAD UNREAD COUNT UNTUK BADGE
  // ─────────────────────────────────────────────

  Future<void> _loadUnreadCount() async {
    try {
      final notifs = await PosMitraService.getWithdrawalNotifications();
      final rides = await PosMitraService.getUpcomingRides();
      if (mounted) {
        setState(() {
          _unreadCount = notifs.length + rides.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await PosMitraService.getStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStatistics = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingStatistics = false;
      });
    }
  }

  Future<void> _loadUpcomingRides() async {
    try {
      final rides = await PosMitraService.getUpcomingRides();
      setState(() {
        _upcomingRides = rides.take(2).toList();
        _isLoadingRides = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingRides = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _userProfile = null;
          _isLoadingProfile = false;
        });
        return;
      }

      final profile = await PosMitraService.getProfile(token);

      setState(() {
        _userProfile = profile['data']?['user'] as Map<String, dynamic>?;
        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() {
        _userProfile = null;
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadSaldo() async {
    try {
      final saldo = await PosMitraService.getBalance();
      setState(() {
        _saldo = saldo;
        _isLoadingSaldo = false;
      });
    } catch (e) {
      print('Error loading saldo: $e');
      setState(() {
        _saldo = 0;
        _isLoadingSaldo = false;
      });
    }
  }

  Future<void> _showCustomCalendar() async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return CustomCalendarDialog(initialDate: selectedDate);
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  String _calculateTotalIncome() {
    double total = 0;
    for (var ride in _upcomingRides) {
      final price = ride['price'] as num? ?? 0;
      total += price.toDouble();
    }

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Blue Background
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    // Top Bar with Profile and Notification
                    Row(
                      children: [
                        // Profile Picture with White Border
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: _isLoadingProfile
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  )
                                : Builder(
                                    builder: (context) {
                                      String photoUrl =
                                          'https://i.pravatar.cc/150?img=12';
                                      final raw =
                                          _userProfile?['profile_photo'];

                                      if (raw != null && raw.isNotEmpty) {
                                        if (raw.startsWith('http')) {
                                          photoUrl = raw;
                                        } else {
                                          final base = ApiService.baseUrl;
                                          photoUrl = raw.startsWith('/')
                                              ? '$base$raw'
                                              : '$base/$raw';
                                        }
                                      }

                                      return Image.network(
                                        photoUrl,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.network(
                                            'https://i.pravatar.cc/150?img=12',
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Halo,',
                                style: TextStyle(
                                  color: Color(0xFFB3C5E8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _userProfile?['name'] ?? 'Pos Mitra',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 🔔 Notification Bell dengan Badge
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotifikasiPage(),
                                    ),
                                  );
                                  // Reset badge setelah kembali dari halaman notifikasi
                                  setState(() => _unreadCount = 0);
                                },
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                            if (_unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF1E3A8A),
                                      width: 1.5,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    _unreadCount > 99
                                        ? '99+'
                                        : '$_unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Balance Card
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2852B8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header dengan Tarik Saldo button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pendapatan',
                                style: TextStyle(
                                  color: Color(0xFFB3C5E8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TarikSaldoPage(
                                          currentBalance: _saldo,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Tarik Saldo',
                                    style: TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Balance Amount
                          Row(
                            children: [
                              _isLoadingSaldo
                                  ? const Text(
                                      'Rp ...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : Text(
                                      isSaldoVisible
                                          ? NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp ',
                                              decimalDigits: 0,
                                            ).format(_saldo)
                                          : 'Rp ...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    isSaldoVisible = !isSaldoVisible;
                                  });
                                },
                                icon: Icon(
                                  isSaldoVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Riwayat Penarikan
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RiwayatPencairanPage(),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                const Text(
                                  'Riwayat Penarikan',
                                  style: TextStyle(
                                    color: Color(0xFFB3C5E8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Statistics Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Statistik Layanan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Statistik Layanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                        InkWell(
                          onTap: _showCustomCalendar,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(selectedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats Grid
                    _buildStatsGrid(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Upcoming Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Header Tebengan akan datang
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tebengan akan datang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF212121),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AktivitasPage(),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Lihat semua',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Color(0xFF1E3A8A),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Service Cards
                    _isLoadingRides
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : _upcomingRides.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Tidak ada tebengan yang akan datang',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              )
                            : _buildServiceCards(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Income Estimate
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estimasi Pendapatan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _calculateTotalIncome(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                _isLoadingStatistics
                    ? '0'
                    : '${_statistics['nebeng_motor'] ?? 0}',
                'Nebeng Motor',
                Icons.two_wheeler,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                _isLoadingStatistics
                    ? '0'
                    : '${_statistics['nebeng_mobil'] ?? 0}',
                'Nebeng Mobil',
                Icons.directions_car,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                _isLoadingStatistics
                    ? '0'
                    : '${_statistics['nebeng_barang'] ?? 0}',
                'Nebeng Barang',
                Icons.shopping_bag_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                _isLoadingStatistics
                    ? '0'
                    : '${_statistics['titip_barang'] ?? 0}',
                'Titip Barang',
                Icons.store_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCards() {
    return Column(
      children: _upcomingRides.asMap().entries.map((entry) {
        final index = entry.key;
        final ride = entry.value;

        final destination = ride['destination'] as Map<String, dynamic>?;
        final rideType = ride['ride_type'] as String? ?? 'motor';
        final serviceType = ride['service_type'] as String? ?? 'tebengan';
        final status = ride['status'] as String? ?? 'active';
        final date = ride['date'] as String? ?? '';
        final time = ride['time'] as String? ?? '';

        final rideTypeLabel = _getRideTypeLabel(rideType, serviceType);
        final formattedDateTime = _formatDateTime(date, time);
        final statusLabel = _getStatusLabel(status);
        final statusColor = _getStatusColor(status);

        return Column(
          children: [
            if (index > 0) const SizedBox(height: 12),
            _buildServiceCard(
              '$formattedDateTime | $rideTypeLabel',
              destination?['name'] ?? 'Unknown',
              destination?['detail'] ?? '',
              statusLabel,
              statusColor,
              status == 'pending',
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDateTime(String date, String time) {
    try {
      final cleanDate = date.split(' ')[0];
      final cleanTime = time.split('.')[0];
      final dateTime = DateTime.parse('$cleanDate $cleanTime');
      final dayName = DateFormat('EEE', 'id_ID').format(dateTime);
      final formattedDate =
          DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime);
      final formattedTime = DateFormat('HH:mm').format(dateTime);
      return '$dayName, $formattedDate | $formattedTime';
    } catch (e) {
      return '$date | $time';
    }
  }

  String _getRideTypeLabel(String rideType, String serviceType) {
    if (serviceType == 'barang') return 'Titip Barang';
    if (rideType == 'motor') return 'Nebeng Motor';
    if (rideType == 'mobil') return 'Nebeng Mobil';
    return 'Tebengan';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF7B68EE);
      case 'full':
        return const Color(0xFFFF9800);
      case 'completed':
        return const Color(0xFF66BB6A);
      case 'cancelled':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF757575);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'akan datang';
      case 'full':
        return 'Konring';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Widget _buildServiceCard(
    String dateTime,
    String city,
    String location,
    String? status,
    Color? statusColor,
    bool isPending,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending
              ? const Color(0xFFEF5350).withOpacity(0.3)
              : Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  dateTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor!.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
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
                  if (isPending) ...[
                    if (status != null) const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF5350),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location with Dot Indicator
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFEF5350)
                      : const Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom Calendar Dialog Widget
// ─────────────────────────────────────────────

class CustomCalendarDialog extends StatefulWidget {
  final DateTime initialDate;

  const CustomCalendarDialog({
    Key? key,
    required this.initialDate,
  }) : super(key: key);

  @override
  State<CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<CustomCalendarDialog> {
  late DateTime currentMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    selectedDate = widget.initialDate;
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(selectedDate);
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    List<DateTime> days = [];

    final firstWeekday = firstDay.weekday;
    for (int i = 0; i < (firstWeekday % 7); i++) {
      days.add(DateTime(0));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    final monthName = DateFormat('MMMM').format(currentMonth);
    final year = currentMonth.year;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left),
                  color: const Color(0xFF424242),
                ),
                Column(
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right),
                  color: const Color(0xFF424242),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Day names
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDayName('Sen'),
                _buildDayName('Sel'),
                _buildDayName('Rab'),
                _buildDayName('Kam'),
                _buildDayName('Jum'),
                _buildDayName('Sab'),
                _buildDayName('Min'),
              ],
            ),
            const SizedBox(height: 16),
            // Calendar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                if (day.year == 0) {
                  return const SizedBox.shrink();
                }

                final isSelected = day.year == selectedDate.year &&
                    day.month == selectedDate.month &&
                    day.day == selectedDate.day;

                return InkWell(
                  onTap: () => _selectDate(day),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF424242),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            // Selected date display
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd / MM / yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pilih Tanggal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayName(String name) {
    return SizedBox(
      width: 40,
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF757575),
        ),
      ),
    );
  }
}