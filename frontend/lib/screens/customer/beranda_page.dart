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

      final today = DateTime.now();
      final upcoming = bookings.where((b) {
        try {
          final svc = (b['service_type'] ?? '').toString().toLowerCase();
          final dateStr = (b['departure_date'] ?? b['date'] ?? '').toString();
          if (svc != 'tebengan' &&
              svc != 'both' &&
              svc != 'motor' &&
              svc != 'mobil') return false;
          if (dateStr.isEmpty) return false;
          final d = DateTime.tryParse(dateStr.split('T')[0]) ??
              DateTime.tryParse(dateStr);
          if (d == null) return false;
          return !d.isBefore(DateTime(today.year, today.month, today.day));
        } catch (_) {
          return false;
        }
      }).toList();

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

      setState(() {
        _upcomingTebengan = upcoming.take(3).toList();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadVerificationStatus();
            await _loadUpcomingTebengan();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                if (_showKTPWarning) _buildKTPWarning(),
                _buildServicesGrid(),
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
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Ailsa 👋',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mau kemana hari ini?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
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
                      icon: Stack(
                        children: [
                          Icon(Icons.notifications_outlined, 
                            color: Colors.grey[700], 
                            size: 28
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 8,
                                minHeight: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKTPWarning() {
    String title;
    String subtitle;
    Color bgColor;
    Color borderColor;
    IconData iconData;

    switch (_verificationStatus) {
      case 'pending':
        title = 'Verifikasi Sedang Diproses';
        subtitle = 'Menunggu persetujuan admin';
        bgColor = Colors.orange[50]!;
        borderColor = Colors.orange;
        iconData = Icons.info_outline;
        break;
      case 'rejected':
        title = 'Verifikasi Ditolak';
        subtitle = 'Tap untuk verifikasi ulang';
        bgColor = Colors.red[50]!;
        borderColor = Colors.red;
        iconData = Icons.error_outline;
        break;
      case 'verified':
        return const SizedBox.shrink();
      case 'not_verified':
      default:
        title = 'Verifikasi KTP';
        subtitle = 'Verifikasi sekarang untuk akses semua layanan';
        bgColor = const Color(0xFF1E3A8A).withOpacity(0.05);
        borderColor = const Color(0xFF1E3A8A);
        iconData = Icons.verified_user_outlined;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VerifikasiIntroPage(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(iconData, color: borderColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, 
              color: borderColor, 
              size: 16
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
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
            label: 'Barang\nUmum',
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
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isEnabled = _verificationStatus == 'verified';
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? color.withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 28,
                color: isEnabled ? color : Colors.grey[400],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: isEnabled ? Colors.grey[800] : Colors.grey[500],
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo & Info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
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
                height: 6,
                width: _currentCarouselIndex == index ? 20 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color:                   _currentCarouselIndex == index
                      ? const Color(0xFF1E3A8A)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(int index) {
    final promos = [
      {
        'color': const Color(0xFF1E40AF),
        'title': 'Hemat 20%',
        'subtitle': 'Pakai kode FIRST20',
        'icon': FontAwesomeIcons.tag,
      },
      {
        'color': const Color(0xFF0891B2),
        'title': 'Gratis Ongkir',
        'subtitle': 'Min. transaksi 50rb',
        'icon': FontAwesomeIcons.gift,
      },
      {
        'color': const Color(0xFF059669),
        'title': 'Cashback 15%',
        'subtitle': 'Maksimal 25rb',
        'icon': FontAwesomeIcons.wallet,
      },
    ];

    final promo = promos[index % promos.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            promo['color'] as Color,
            (promo['color'] as Color).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    promo['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    promo['subtitle'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Gunakan Sekarang',
                      style: TextStyle(
                        color: promo['color'] as Color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              promo['icon'] as IconData,
              size: 70,
              color: Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTebenganSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Perjalanan Mendatang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (_upcomingTebengan.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingUpcoming)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_upcomingTebengan.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada perjalanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pesan perjalanan pertama Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const NebengMotorPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Pesan Sekarang'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcomingTebengan.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final b = _upcomingTebengan[index];
                final date = (b['departure_date'] ?? b['date'] ?? '')
                    .toString()
                    .split('T')[0];
                final time =
                    (b['departure_time'] ?? b['time'] ?? '').toString();
                final from = (b['origin_location_name'] ??
                        b['departure_location'] ??
                        b['from'] ??
                        '')
                    .toString();
                final to = (b['destination_location_name'] ??
                        b['arrival_location'] ??
                        b['to'] ??
                        '')
                    .toString();
                final price = b['price'] != null 
                    ? 'Rp ${b['price'].toString()}' 
                    : '-';

                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Booking: ${b['booking_number'] ?? b['id'] ?? ''}',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                date,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF059669),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          from,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 3),
                                    child: Container(
                                      width: 2,
                                      height: 20,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E3A8A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          to,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
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
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  activeIcon: Icon(Icons.receipt_long),
                  label: 'Riwayat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Pesan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
              currentIndex: 0,
              selectedItemColor: const Color(0xFF1E3A8A),
              unselectedItemColor: Colors.grey[400],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
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