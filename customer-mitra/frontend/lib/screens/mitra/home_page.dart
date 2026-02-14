import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/shared/notification_api_service.dart';
import '../../services/shared/api_config.dart';
import 'create_tebengan_motor/pages/create_ride_page.dart';
import 'rating_review_page.dart';
import 'riwayat_page.dart';
import 'create_tebengan_mobil/pages/create_ride_page.dart' as mobil_create;
import 'create_tebengan_barang/pages/create_ride_page.dart' as barang_create;
import 'titip_barang/pages/create_titip_barang_page.dart';
import 'vehicles/vehicle_type_page.dart';
import 'withdrawal/tarik_saldo_page.dart';
import 'withdrawal/withdrawal_history_page.dart';
import 'notification_page.dart';

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

  double _balance = 0.0;
  bool _isBalanceVisible = true;

  // Verification status
  String?
      _verificationStatus; // 'not_submitted', 'pending', 'approved', 'rejected'
  bool _isVerificationLoading = true;

  // Notification unread count
  int _unreadNotificationCount = 0;

  // User profile data
  String _userName = 'Mitra';
  String? _userProfileImage;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkVerificationStatus();
    _loadUnreadNotificationCount();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null) {
        final result = await ApiService.getMitraVerificationStatus(token);
        if (mounted) {
          setState(() {
            _verificationStatus = result['status'];
            _isVerificationLoading = false;
          });
          print('Verification status loaded: $_verificationStatus'); // Debug
        }
      } else {
        if (mounted) {
          setState(() {
            _verificationStatus = 'not_submitted';
            _isVerificationLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error checking verification status: $e'); // Debug
      if (mounted) {
        setState(() {
          _verificationStatus = 'not_submitted';
          _isVerificationLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null) {
        final count = await NotificationApiService.getUnreadCount(token: token);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      final userId = prefs.getInt('user_id');

      if (token != null && token.isNotEmpty) {
        final profile = await ApiService.getProfile(token: token);
        print('Profile response: $profile'); // Debug

        Map<String, dynamic> user = {};
        if (profile['success'] == true && profile['data'] != null) {
          user = profile['data']['user'] ?? profile['data'];
        } else if (profile['data'] != null) {
          user = profile['data'];
        } else {
          user = profile;
        }

        print('User data extracted: $user'); // Debug
        print('User name: ${user['name']}'); // Debug

        // Save user profile data
        if (mounted) {
          setState(() {
            _userName = user['name'] ?? user['full_name'] ?? 'Mitra';
            _userProfileImage = user['profile_photo'] ??
                user['profile_image'] ??
                user['profile_picture'] ??
                user['photo'];

            // Normalize profile_photo to absolute URL if needed
            if (_userProfileImage != null && _userProfileImage!.isNotEmpty) {
              if (!_userProfileImage!.startsWith('http')) {
                final base = ApiConfig.baseUrl;
                _userProfileImage = _userProfileImage!.startsWith('/')
                    ? '$base$_userProfileImage'
                    : '$base/$_userProfileImage';
              }
            }

            print('Set _userName to: $_userName'); // Debug
            print('Set _userProfileImage to: $_userProfileImage'); // Debug
          });
        }

        // Fetch balance
        try {
          final balanceResp = await ApiService.getBalance(token: token);
          if (balanceResp['success'] == true && balanceResp['data'] != null) {
            final balance = balanceResp['data']['balance'];
            if (balance != null) {
              double newBalance = 0.0;
              if (balance is num) {
                newBalance = (balance as num).toDouble();
              } else if (balance is String) {
                newBalance = double.tryParse(balance) ?? 0.0;
              }
              if (mounted) {
                setState(() {
                  _balance = newBalance;
                });
              }
            }
          }
        } catch (e) {
          // ignore error, keep default balance
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
                      child: _userProfileImage != null
                          ? Image.network(
                              _userProfileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Color(0xFF10367d),
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 30,
                              color: Color(0xFF10367d),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Halo,',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          _userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // Notification icon
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MitraNotificationPage(),
                        ),
                      );
                      // Reload unread count after returning from notification page
                      _loadUnreadNotificationCount();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
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
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Center(
                                child: Text(
                                  _unreadNotificationCount > 99
                                      ? '99+'
                                      : _unreadNotificationCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
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
                                  'Saldo Anda Saat Ini',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TarikSaldoPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  _isBalanceVisible
                                      ? 'Rp ${_balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')},00'
                                      : 'Rp ••••••',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isBalanceVisible = !_isBalanceVisible;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const WithdrawalHistoryPage(),
                                  ),
                                );
                              },
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
                                if (!_canAccessFeatures) {
                                  _showVerificationRequiredDialog();
                                  return;
                                }
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
                                if (!_canAccessFeatures) {
                                  _showVerificationRequiredDialog();
                                  return;
                                }
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
                                if (!_canAccessFeatures) {
                                  _showVerificationRequiredDialog();
                                  return;
                                }
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
                                if (!_canAccessFeatures) {
                                  _showVerificationRequiredDialog();
                                  return;
                                }
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

                    // Booking Cards (dynamic upcoming rides)
                    _isLoading
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFE8E8E8), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF10367d),
                                ),
                              ),
                            ),
                          )
                        : _upcomingRides.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: const Color(0xFFE8E8E8),
                                        width: 1),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.event_busy_outlined,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Tidak ada tebengan hari ini',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Column(
                                children:
                                    _upcomingRides.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final ride = entry.value;
                                  final r = ride as Map<String, dynamic>;
                                  final date =
                                      (r['departure_date'] ?? r['date'] ?? '')
                                          .toString();
                                  final time =
                                      (r['departure_time'] ?? r['time'] ?? '')
                                          .toString();
                                  final service = (r['ride_type'] ??
                                          r['service_type'] ??
                                          'Nebeng')
                                      .toString();
                                  final origin = (r['origin_location'] is Map)
                                      ? (r['origin_location']['name'] ?? '')
                                      : (r['origin'] ?? '');
                                  final destination = (r['destination_location']
                                          is Map)
                                      ? (r['destination_location']['name'] ??
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
                                              : available.toString() != '0')) {
                                        statusLabel =
                                            'Aktif · ${available.toString()} tersisa';
                                      }
                                      badgeBg = const Color(0xFFFFF4EA);
                                      badgeText = const Color(0xFFFF8C00);
                                      break;
                                    case 'completed':
                                    case 'selesai':
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
                                    case 'pending':
                                      statusLabel = 'Menunggu';
                                      badgeBg = const Color(0xFFFFF4EA);
                                      badgeText = const Color(0xFFFF8C00);
                                      break;
                                    case 'paid':
                                      statusLabel = 'Terbayar';
                                      badgeBg = const Color(0xFFE3F2FD);
                                      badgeText = const Color(0xFF1976D2);
                                      break;
                                    case 'confirmed':
                                      statusLabel = 'Dikonfirmasi';
                                      badgeBg = const Color(0xFFE3F2FD);
                                      badgeText = const Color(0xFF1976D2);
                                      break;
                                    case 'scheduled':
                                      statusLabel = 'Terjadwal';
                                      badgeBg = const Color(0xFFE3F2FD);
                                      badgeText = const Color(0xFF1976D2);
                                      break;
                                    case 'menuju_penjemputan':
                                      statusLabel = 'Menuju Penjemputan';
                                      badgeBg = const Color(0xFFE1F5FE);
                                      badgeText = const Color(0xFF0277BD);
                                      break;
                                    case 'sudah_di_penjemputan':
                                      statusLabel = 'Sudah di Penjemputan';
                                      badgeBg = const Color(0xFFE8F5E9);
                                      badgeText = const Color(0xFF388E3C);
                                      break;
                                    case 'menuju_tujuan':
                                      statusLabel = 'Menuju Tujuan';
                                      badgeBg = const Color(0xFFE1F5FE);
                                      badgeText = const Color(0xFF0277BD);
                                      break;
                                    case 'sudah_sampai_tujuan':
                                      statusLabel = 'Sudah Sampai Tujuan';
                                      badgeBg = const Color(0xFFE8F5E9);
                                      badgeText = const Color(0xFF388E3C);
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
                                          badgeText = const Color(0xFFFF8C00);
                                        } else {
                                          statusLabel = 'Kosong';
                                          badgeBg = const Color(0xFFFFE6E6);
                                          badgeText = const Color(0xFFD32F2F);
                                        }
                                      } else {
                                        statusLabel =
                                            rawStatus[0].toUpperCase() +
                                                rawStatus.substring(1);
                                        badgeBg = const Color(0xFFF5F5F5);
                                        badgeText = const Color(0xFF757575);
                                      }
                                  }

                                  // Determine service icon and color
                                  IconData serviceIcon;
                                  Color serviceColor;
                                  switch (service.toLowerCase()) {
                                    case 'motor':
                                    case 'nebeng motor':
                                      serviceIcon = Icons.two_wheeler;
                                      serviceColor = const Color(0xFF10367d);
                                      break;
                                    case 'mobil':
                                    case 'nebeng mobil':
                                      serviceIcon = Icons.directions_car;
                                      serviceColor = const Color(0xFF10367d);
                                      break;
                                    case 'barang':
                                    case 'nebeng barang':
                                      serviceIcon = Icons.inventory_2_outlined;
                                      serviceColor = const Color(0xFF10367d);
                                      break;
                                    case 'titip barang':
                                      serviceIcon =
                                          Icons.local_shipping_outlined;
                                      serviceColor = const Color(0xFF10367d);
                                      break;
                                    default:
                                      serviceIcon = Icons.directions;
                                      serviceColor = const Color(0xFF10367d);
                                  }

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      bottom: index < _upcomingRides.length - 1
                                          ? 12
                                          : 0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE8E8E8),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              // Handle card tap - could navigate to ride details
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Header: Date, Time, Service Type, and Status
                                                  Row(
                                                    children: [
                                                      // Service Icon
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: serviceColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Icon(
                                                          serviceIcon,
                                                          size: 20,
                                                          color: serviceColor,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              service.isNotEmpty
                                                                  ? service[0]
                                                                          .toUpperCase() +
                                                                      service
                                                                          .substring(
                                                                              1)
                                                                  : service,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                    0xFF1a1a1a),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 2),
                                                            Text(
                                                              _formatHeaderDate(
                                                                  date, time),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Status Badge
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 6,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: badgeBg,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: Text(
                                                          statusLabel,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: badgeText,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),

                                                  const SizedBox(height: 16),

                                                  // Route: Origin to Destination
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Route indicator
                                                      Column(
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: const Color(
                                                                  0xFF10367d),
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                color: const Color(
                                                                    0xFF10367d),
                                                                width: 2,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            width: 2,
                                                            height: 32,
                                                            color: const Color(
                                                                0xFFE0E0E0),
                                                          ),
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                color: const Color(
                                                                    0xFF10367d),
                                                                width: 2,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 12),
                                                      // Origin and Destination
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              origin.toString(),
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                    0xFF1a1a1a),
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            const SizedBox(
                                                                height: 16),
                                                            Text(
                                                              destination
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .grey[700],
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
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

  Widget _buildVerificationWarningBanner() {
    Color bgColor;
    Color iconColor;
    String title;
    String message;
    IconData icon;

    switch (_verificationStatus) {
      case 'pending':
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.pending_outlined;
        title = 'Dokumen Sedang Diverifikasi';
        message =
            'Mohon tunggu, dokumen Anda sedang direview oleh tim kami (1-3 hari kerja).';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.error_outline;
        title = 'Verifikasi Ditolak';
        message = 'Dokumen Anda ditolak. Silakan lengkapi dokumen kembali.';
        break;
      case 'not_submitted':
      default:
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.warning_amber_outlined;
        title = 'Kamu belum melakukan verifikasi dokumen';
        message = 'Ayo verifikasi sekarang untuk mulai menerima tebengan!';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: iconColor.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: iconColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAccessFeatures {
    print(
        'Can access features check: $_verificationStatus == approved? ${_verificationStatus == 'approved'}'); // Debug
    return _verificationStatus == 'approved';
  }

  void _showVerificationRequiredDialog() {
    print(
        'Showing verification required dialog. Status: $_verificationStatus'); // Debug
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 60,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verifikasi Diperlukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _verificationStatus == 'pending'
                    ? 'Dokumen Anda sedang dalam proses review. Mohon tunggu approval dari tim kami.'
                    : 'Anda harus menyelesaikan verifikasi dokumen terlebih dahulu untuk mengakses fitur ini.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
