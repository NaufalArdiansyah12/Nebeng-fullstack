import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/verifikasi_service.dart';
import 'notification_page.dart';
import 'nebeng_motor_page.dart';
import 'nebeng_mobil_page.dart';
import 'nebeng_barang/pages/nebeng_barang_page.dart';
import 'barang_umum/pages/barang_umum_page.dart';
import 'profile/profile_page.dart';
import 'profile/verifikasi_intro_page.dart';
import 'riwayat/riwayat_page.dart';
import 'riwayat/booking_detail_riwayat_page.dart';

class BerandaPage extends StatefulWidget {
  final bool showBottomNav;

  const BerandaPage({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> with WidgetsBindingObserver {
  late User currentUser;
  int _currentCarouselIndex = 0;
  bool _showKTPWarning = true;
  String _verificationStatus = 'not_verified';
  Timer? _statusCheckTimer;
  String _previousStatus = '';
  List<Map<String, dynamic>> _upcomingTebengan = [];
  bool _loadingUpcoming = true;

  final List<Service> services = [
    Service(
      id: 1,
      name: 'Nebeng Motor',
      icon: FontAwesomeIcons.motorcycle,
      description: 'Layanan motor',
    ),
    Service(
      id: 2,
      name: 'Nebeng Mobil',
      icon: FontAwesomeIcons.car,
      description: 'Layanan mobil',
    ),
    Service(
      id: 3,
      name: 'Nebeng Barang',
      icon: FontAwesomeIcons.box,
      description: 'Layanan barang',
    ),
    Service(
      id: 4,
      name: 'Barang (Umum)',
      icon: FontAwesomeIcons.truck,
      description: 'Layanan transportasi',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentUser = User(
      id: 1,
      name: 'Ailsa',
      email: 'ailsa@example.com',
      isKTPVerified: false,
      rewardPoints: 1000,
      profileImage: '👋',
    );
    _loadVerificationStatus();
    _startStatusPolling();
    _loadUpcomingTebengan();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUpcomingTebengan() async {
    setState(() {
      _loadingUpcoming = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) {
        setState(() {
          _upcomingTebengan = [];
          _loadingUpcoming = false;
        });
        return;
      }

      final bookings = await ApiService.fetchBookings(token: token);

      // Filter untuk menampilkan booking yang sedang aktif
      final upcoming = bookings.where((b) {
        try {
          final ride = b['ride'] ?? {};

          // Filter berdasarkan booking_type - termasuk motor dan mobil
          final bookingType = (b['booking_type'] ?? b['service_type'] ?? '')
              .toString()
              .toLowerCase();

          // Cek apakah booking type adalah motor atau mobil
          final isTebengan = bookingType.contains('motor') ||
              bookingType.contains('mobil') ||
              bookingType == 'both';

          if (!isTebengan) {
            return false;
          }

          // Filter berdasarkan status - tampilkan yang belum selesai
          final status =
              (b['status'] ?? ride['status'] ?? '').toString().toLowerCase();

          // Exclude completed/cancelled statuses
          final isNotCompleted = !status.contains('selesai') &&
              !status.contains('paid') &&
              !status.contains('completed') &&
              !status.contains('done') &&
              !status.contains('cancel') &&
              !status.contains('batalkan');

          if (!isNotCompleted) {
            return false;
          }
          return true;
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort berdasarkan tanggal (paling dekat duluan)
      upcoming.sort((a, b) {
        final da = DateTime.tryParse((a['departure_date'] ?? a['date'] ?? '')
                .toString()
                .split('T')[0]) ??
            DateTime.now();
        final db = DateTime.tryParse((b['departure_date'] ?? b['date'] ?? '')
                .toString()
                .split('T')[0]) ??
            DateTime.now();
        return da.compareTo(db);
      });

      final finalList = upcoming.take(3).toList();

      setState(() {
        _upcomingTebengan = finalList;
        _loadingUpcoming = false;
      });
    } catch (e) {
      setState(() {
        _upcomingTebengan = [];
        _loadingUpcoming = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadVerificationStatus();
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadVerificationStatus();
    });
  }

  Future<void> _loadVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null) {
        final data = await VerifikasiService.getVerification(token);

        String newStatus;
        bool showWarning;

        if (data.status == 'approved') {
          newStatus = 'verified';
          showWarning = false;
        } else if (data.status == 'pending') {
          newStatus = 'pending';
          showWarning = true;
        } else if (data.status == 'rejected') {
          newStatus = 'rejected';
          showWarning = true;
        } else {
          newStatus = 'not_verified';
          showWarning = true;
        }

        if (_previousStatus.isNotEmpty && _previousStatus != newStatus) {
          _showStatusChangeNotification(newStatus);
        }

        setState(() {
          _verificationStatus = newStatus;
          _showKTPWarning = showWarning;
          _previousStatus = newStatus;
        });
      } else {
        setState(() {
          _verificationStatus = 'not_verified';
          _previousStatus = 'not_verified';
        });
      }
    } catch (e) {
      setState(() {
        _verificationStatus = 'not_verified';
      });
    }
  }

  void _showStatusChangeNotification(String status) {
    if (!mounted) return;

    String message;
    Color bgColor;
    IconData icon;

    switch (status) {
      case 'verified':
        message = '🎉 Verifikasi Anda telah disetujui!';
        bgColor = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        message = '❌ Verifikasi Anda ditolak. Silakan coba lagi.';
        bgColor = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadVerificationStatus();
            await _loadUpcomingTebengan();
          },
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildRewardSection(),
                        const SizedBox(height: 24),
                        _buildServicesSection(),
                        const SizedBox(height: 24),
                        _buildPromoSection(),
                        const SizedBox(height: 24),
                        _buildUpcomingTebenganSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hallo Ailsa👋',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reward Point',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '1.000',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.grey,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Layanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start, // Tambahkan ini
            children: [
              _buildServiceItem(
                icon: FontAwesomeIcons.motorcycle,
                label: 'Nebeng\nMotor',
                color: const Color(0xFF1E40AF),
                onTap: () {
                  if (_verificationStatus == 'verified') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NebengMotorPage(),
                      ),
                    );
                  } else {
                    _showVerificationRequired();
                  }
                },
              ),
              _buildServiceItem(
                icon: FontAwesomeIcons.car,
                label: 'Nebeng\nMobil',
                color: const Color(0xFF1E40AF),
                onTap: () {
                  if (_verificationStatus == 'verified') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NebengMobilPage(),
                      ),
                    );
                  } else {
                    _showVerificationRequired();
                  }
                },
              ),
              _buildServiceItem(
                icon: FontAwesomeIcons.box,
                label: 'Nebeng\nBarang',
                color: const Color(0xFF1E40AF),
                onTap: () {
                  if (_verificationStatus == 'verified') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NebengBarangPage(),
                      ),
                    );
                  } else {
                    _showVerificationRequired();
                  }
                },
              ),
              _buildServiceItem(
                icon: FontAwesomeIcons.truck,
                label: 'Barang\n(Transportasi\nUmum)',
                color: const Color(0xFF1E40AF),
                onTap: () {
                  if (_verificationStatus == 'verified') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BarangUmumPage(),
                      ),
                    );
                  } else {
                    _showVerificationRequired();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42, // Fixed height untuk text
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verifikasi KTP diperlukan'),
        backgroundColor: const Color(0xFF1E3A8A),
        action: SnackBarAction(
          label: 'VERIFIKASI',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const VerifikasiIntroPage(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nebeng Disini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PageView.builder(
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildPromoCard(index);
              },
              itemCount: 3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                height: 8,
                width: _currentCarouselIndex == index ? 24 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentCarouselIndex == index
                      ? const Color(0xFF1E40AF)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF60A5FA),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: GridPatternPainter(),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Nebeng Motor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jaminan pasti? Nebeng Motor\nmenjamin keamanan perjalanan Anda\ndan aman. Tingkatkan materi,\nnikmati perjalanan yang lancar!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Illustration
          Positioned(
            bottom: 20,
            left: 20,
            child: Image.asset(
              'assets/motor_illustration.png', // Add your illustration asset
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.motorcycle,
                    color: Colors.white,
                    size: 40,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTebenganSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tebengan Mendatang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_upcomingTebengan.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiwayatPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _loadingUpcoming
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                )
              : _upcomingTebengan.isEmpty
                  ? _buildEmptyUpcomingCard()
                  : Column(
                      children: _upcomingTebengan
                          .map((booking) => _buildUpcomingCard(booking))
                          .toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyUpcomingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada tebengan mendatang',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pesan tebengan sekarang!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(Map<String, dynamic> booking) {
    final ride = booking['ride'] ?? {};
    final status =
        (booking['status'] ?? ride['status'] ?? '').toString().toLowerCase();
    final bookingType =
        (booking['booking_type'] ?? booking['service_type'] ?? 'motor')
            .toString()
            .toLowerCase();

    // Get origin and destination from location relations
    String pickupLocation = 'Lokasi pickup';
    String destination = 'Tujuan';

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      pickupLocation = ride['origin_location']['name'] ?? 'Lokasi pickup';
    }

    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? 'Tujuan';
    }

    final departureDate = (ride['departure_date'] ??
            booking['departure_date'] ??
            booking['date'] ??
            '')
        .toString();
    final departureTime =
        (ride['departure_time'] ?? booking['departure_time'] ?? '').toString();

    // Format date
    String formattedDate = '';
    if (departureDate.isNotEmpty) {
      try {
        final date = DateTime.parse(departureDate.split('T')[0]);
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des'
        ];
        formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (e) {
        formattedDate = departureDate;
      }
    }

    // Status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Menunggu';
        statusIcon = Icons.access_time;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Dikonfirmasi';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'proses':
        statusColor = Colors.blue;
        statusText = 'Proses';
        statusIcon = Icons.autorenew;
        break;
      case 'in_progress':
        statusColor = Colors.green;
        statusText = 'Dalam Perjalanan';
        statusIcon = Icons.directions;
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailRiwayatPage(
                  booking: booking,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            bookingType.contains('mobil')
                                ? FontAwesomeIcons.car
                                : FontAwesomeIcons.motorcycle,
                            size: 20,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bookingType.contains('mobil')
                                  ? 'Nebeng Mobil'
                                  : 'Nebeng Motor',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: 14,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1E40AF),
                              width: 2,
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.red[600],
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickupLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            destination,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (departureTime.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          departureTime,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return widget.showBottomNav
        ? Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Pesan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profil',
                ),
              ],
              currentIndex: 0,
              selectedItemColor: const Color(0xFF1E40AF),
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              onTap: (index) {
                if (index == 3) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                }
              },
            ),
          )
        : const SizedBox.shrink();
  }
}

// Custom painter for grid pattern background
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const spacing = 20.0;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
