import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'create_tebengan_motor/pages/create_ride_page.dart';
import 'rating_review_page.dart';
import 'riwayat_page.dart';
import 'create_tebengan_mobil/pages/create_ride_page.dart' as mobil_create;
import 'create_tebengan_barang/pages/create_ride_page.dart' as barang_create;
import 'titip_barang/pages/create_titip_barang_page.dart';
import 'vehicles/vehicle_type_page.dart';

class MitraHomePage extends StatefulWidget {
  final VoidCallback? onOpenHistory;
  const MitraHomePage({Key? key, this.onOpenHistory}) : super(key: key);

  @override
  State<MitraHomePage> createState() => _MitraHomePageState();
}

class _MitraHomePageState extends State<MitraHomePage> {
  double? _rating;
  List<Map<String, dynamic>> _upcomingRides = [];
  bool _isLoading = true;
  int _totalRatings = 0;
  Map<int, int> _ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  int? _mitraId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      final userId = prefs.getInt('user_id');

      if (token != null && token.isNotEmpty) {
        final profile = await ApiService.getProfile(token: token);
        Map<String, dynamic> user = {};
        if (profile['success'] == true && profile['data'] != null) {
          user = profile['data']['user'] ?? profile['data'];
        } else if (profile['data'] != null) {
          user = profile['data'];
        } else {
          user = profile;
        }

        // Try to fetch driver rating stats via ratings API (preferred)
        final id = user['id'] ?? user['user_id'] ?? user['mitra_id'] ?? userId;
        if (id != null) {
          if (mounted) setState(() => _mitraId = id);
          try {
            final ratingsResp = await ApiService.getDriverRatings(driverId: id);
            if (ratingsResp != null) {
              final avg = ratingsResp['average_rating'];
              if (avg != null) {
                if (avg is num) {
                  _rating = (avg as num).toDouble();
                } else if (avg is String) {
                  _rating = double.tryParse(avg) ?? 0.0;
                }
              }

              final total = ratingsResp['total_ratings'] ?? 0;
              _totalRatings = (total is num)
                  ? total.toInt()
                  : int.tryParse(total.toString()) ?? 0;

              // compute counts from ratings array if provided
              final ratingsList = ratingsResp['ratings'];
              if (ratingsList is List) {
                _ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
                for (final item in ratingsList) {
                  final r = (item['rating'] ?? item['rate'] ?? item['score'])
                      as dynamic;
                  int val = 0;
                  if (r is num)
                    val = (r as num).toInt();
                  else if (r is String) val = int.tryParse(r) ?? 0;
                  if (val >= 1 && val <= 5) {
                    _ratingCounts[val] = (_ratingCounts[val] ?? 0) + 1;
                  }
                }
              }
            }
          } catch (e) {
            // ignore and fallback to profile fields
          }

          // fetch mitra's own rides for today using mitra history endpoint
          final today = DateTime.now().toIso8601String().split('T')[0];
          if (token != null && token.isNotEmpty) {
            try {
              final history = await ApiService.fetchMitraHistory(token: token);
              // history returns items with shape { id, type, ride, income }
              final todays = <Map<String, dynamic>>[];
              for (final item in history) {
                final rideObj = item['ride'] is Map<String, dynamic>
                    ? Map<String, dynamic>.from(item['ride'])
                    : Map<String, dynamic>.from(item['ride'] ?? {});
                // normalize and add type
                rideObj['ride_type'] = item['type'] ?? rideObj['ride_type'];
                if ((rideObj['departure_date'] ?? '')
                    .toString()
                    .startsWith(today)) {
                  todays.add(rideObj);
                }
              }
              setState(() {
                _upcomingRides = todays;
              });
            } catch (e) {
              // fallback: leave _upcomingRides empty
            }
          }
        }
      }
    } catch (e) {
      // ignore and keep defaults
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatHeaderDate(String dateStr, String timeStr) {
    if ((dateStr ?? '').isEmpty && (timeStr ?? '').isEmpty) return '';
    DateTime? dt = DateTime.tryParse(dateStr ?? '');
    if (dt == null)
      return '${dateStr ?? ''}${timeStr != null && timeStr.isNotEmpty ? ' | $timeStr' : ''}';
    if (timeStr.isNotEmpty) {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        dt = DateTime(dt.year, dt.month, dt.day, h, m);
      }
    }
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, $day $month $year | $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFF10367d),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // Profile picture
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/profile.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 30,
                            color: Color(0xFF10367d),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo,',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          'Kamado Tanjiro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Earnings Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10367d),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pendapatan Hari Ini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Tarik Saldo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF10367d),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  'Rp 200.000,00',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.visibility_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  const Text(
                                    'Riwayat Penarikan',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Layanan Mitra Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Layanan Mitra',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const VehicleTypePage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10367d),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Tambah Kendaraan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Service Icons - ALL BLUE NOW
                    // Service Icons - ALL BLUE NOW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildServiceIcon(
                              icon: Icons.motorcycle,
                              label: 'Nebeng Motor',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateRidePage()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildServiceIcon(
                              icon: Icons.directions_car,
                              label: 'Nebeng Mobil',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const mobil_create
                                          .CreateCarRidePage()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildServiceIcon(
                              icon: Icons.inventory_2_outlined,
                              label: 'Nebeng Barang',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const barang_create
                                          .CreateBarangRidePage()),
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildServiceIcon(
                              icon: Icons.local_shipping_outlined,
                              label: 'Titip\nBarang',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateTitipBarangPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Rating Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rating Costumer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_mitraId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RatingReviewPage(driverId: _mitraId!),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Lihat lebih',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF10367d),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Rating Display with Chart
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Color(0xFFF0F0F0), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating Number with Stars
                            Column(
                              children: [
                                Text(
                                  (_rating ?? 0.0).toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10367d),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (index) {
                                    final filled = (_rating != null)
                                        ? _rating!.floor().clamp(0, 5)
                                        : 0;
                                    return Icon(
                                      index < filled
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: const Color(0xFF10367d),
                                      size: 18,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            // Rating Bars
                            Expanded(
                              child: Column(
                                children: [
                                  Builder(builder: (_) {
                                    final total =
                                        _totalRatings > 0 ? _totalRatings : 0;
                                    double p5 = total > 0
                                        ? (_ratingCounts[5] ?? 0) / total
                                        : 0.0;
                                    double p4 = total > 0
                                        ? (_ratingCounts[4] ?? 0) / total
                                        : 0.0;
                                    double p3 = total > 0
                                        ? (_ratingCounts[3] ?? 0) / total
                                        : 0.0;
                                    double p2 = total > 0
                                        ? (_ratingCounts[2] ?? 0) / total
                                        : 0.0;
                                    double p1 = total > 0
                                        ? (_ratingCounts[1] ?? 0) / total
                                        : 0.0;
                                    return Column(
                                      children: [
                                        _buildRatingBar(
                                            5, p5, _ratingCounts[5] ?? 0),
                                        const SizedBox(height: 6),
                                        _buildRatingBar(
                                            4, p4, _ratingCounts[4] ?? 0),
                                        const SizedBox(height: 6),
                                        _buildRatingBar(
                                            3, p3, _ratingCounts[3] ?? 0),
                                        const SizedBox(height: 6),
                                        _buildRatingBar(
                                            2, p2, _ratingCounts[2] ?? 0),
                                        const SizedBox(height: 6),
                                        _buildRatingBar(
                                            1, p1, _ratingCounts[1] ?? 0),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tebengan Akan Datang
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tebengan Akan Datang',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a1a),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (widget.onOpenHistory != null) {
                                widget.onOpenHistory!();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MitraRiwayatPage(),
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Lihat lebih',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF10367d),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Booking Card (dynamic upcoming rides)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: Color(0xFFF0F0F0), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 80,
                                child: Center(
                                    child: CircularProgressIndicator(
                                  color: const Color(0xFF10367d),
                                )),
                              )
                            : _upcomingRides.isEmpty
                                ? SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Text(
                                        'Tidak ada tebengan hari ini',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _upcomingRides.map((ride) {
                                      final r = ride as Map<String, dynamic>;
                                      final date = (r['departure_date'] ??
                                              r['date'] ??
                                              '')
                                          .toString();
                                      final time = (r['departure_time'] ??
                                              r['time'] ??
                                              '')
                                          .toString();
                                      final service = (r['ride_type'] ??
                                              r['service_type'] ??
                                              'Nebeng')
                                          .toString();
                                      final origin = (r['origin_location']
                                              is Map)
                                          ? (r['origin_location']['name'] ?? '')
                                          : (r['origin'] ?? '');
                                      final destination =
                                          (r['destination_location'] is Map)
                                              ? (r['destination_location']
                                                      ['name'] ??
                                                  '')
                                              : (r['destination'] ?? '');
                                      final available = r['available_seats'] ??
                                          r['seats'] ??
                                          null;
                                      // derive status from multiple possible shapes returned by API
                                      dynamic rawStatusVal = r['status'] ??
                                          ((r['ride'] is Map)
                                              ? r['ride']['status']
                                              : null) ??
                                          r['ride_status'] ??
                                          r['rideStatus'];
                                      final rawStatus = (rawStatusVal ?? '')
                                          .toString()
                                          .toLowerCase();
                                      String statusLabel;
                                      Color badgeBg;
                                      Color badgeText;

                                      switch (rawStatus) {
                                        case 'active':
                                          // Show DB status as 'Aktif'. If seats available, append count.
                                          statusLabel = 'Aktif';
                                          if (available != null &&
                                              (available is num
                                                  ? available > 0
                                                  : available.toString() !=
                                                      '0')) {
                                            statusLabel =
                                                'Aktif · ${available.toString()} tersisa';
                                          }
                                          badgeBg = const Color(0xFFFFF4EA);
                                          badgeText = const Color(0xFFFF8C00);
                                          break;
                                        case 'completed':
                                          statusLabel = 'Selesai';
                                          badgeBg = const Color(0xFFE8F5E9);
                                          badgeText = const Color(0xFF2E7D32);
                                          break;
                                        case 'cancelled':
                                          statusLabel = 'Dibatalkan';
                                          badgeBg = const Color(0xFFF5F5F5);
                                          badgeText = const Color(0xFF757575);
                                          break;
                                        case 'full':
                                          statusLabel = 'Penuh';
                                          badgeBg = const Color(0xFFFFE6E6);
                                          badgeText = const Color(0xFFD32F2F);
                                          break;
                                        default:
                                          // Fallback: if status empty, show availability; otherwise capitalize raw status
                                          if (rawStatus.isEmpty) {
                                            if (available != null &&
                                                (available is num
                                                    ? available > 0
                                                    : available.toString() !=
                                                        '0')) {
                                              statusLabel =
                                                  '${available.toString()} tersisa';
                                              badgeBg = const Color(0xFFFFF4EA);
                                              badgeText =
                                                  const Color(0xFFFF8C00);
                                            } else {
                                              statusLabel = 'Kosong';
                                              badgeBg = const Color(0xFFFFE6E6);
                                              badgeText =
                                                  const Color(0xFFD32F2F);
                                            }
                                          } else {
                                            statusLabel =
                                                rawStatus[0].toUpperCase() +
                                                    rawStatus.substring(1);
                                            badgeBg = const Color(0xFFF5F5F5);
                                            badgeText = const Color(0xFF757575);
                                          }
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${_formatHeaderDate(date, time)} | $service',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF666666),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFFFE4CC),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFFF8C00),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF10367d),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                origin.toString(),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1a1a1a),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 4),
                                            child: Container(
                                              width: 2,
                                              height: 20,
                                              color: const Color(0xFFE0E0E0),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Text(
                                                destination.toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF666666),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10367d),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10367d).withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 75,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1a1a1a),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage, [int? count]) {
    return Row(
      children: [
        Text(
          '$stars',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Filled bar
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10367d),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count != null ? count.toString() : '',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}
