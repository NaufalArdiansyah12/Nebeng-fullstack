import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_page.dart';
import '../../services/api_service.dart';
import 'booking_detail_riwayat_page.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({Key? key}) : super(key: key);

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with WidgetsBindingObserver {
  final tabs = ['Semua', 'Motor', 'Mobil', 'Barang', 'Titip Barang'];
  final typeMap = {
    'Semua': 'semua',
    'Motor': 'motor',
    'Mobil': 'mobil',
    'Barang': 'barang',
    'Titip Barang': 'titip'
  };
  String selected = 'Semua';
  // Top status tabs
  final topTabs = ['Riwayat', 'Dalam Proses', 'Jadwal Pesanan'];
  String selectedTop = 'Riwayat';
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> bookings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndFetch();
    // start polling to update riwayat in near realtime
    _startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground, refresh data immediately
    if (state == AppLifecycleState.resumed) {
      _loadAndFetch();
    }
  }

  Timer? _pollTimer;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (t) {
      _fetchLatest();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _loadAndFetch() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null || token.isEmpty) {
        setState(() {
          error = 'User not authenticated';
          bookings = [];
          loading = false;
        });
        return;
      }

      final type = typeMap[selected];
      final data = await ApiService.fetchBookings(
          token: token, type: type == 'semua' ? null : type);
      setState(() {
        bookings = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        bookings = [];
        loading = false;
      });
    }
  }

  /// Fetch latest bookings without toggling loading UI (used by poller)
  Future<void> _fetchLatest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null || token.isEmpty) return;

      final type = typeMap[selected];
      final data = await ApiService.fetchBookings(
          token: token, type: type == 'semua' ? null : type);
      setState(() {
        bookings = data;
      });
    } catch (_) {
      // ignore polling errors silently
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: tabs.map((c) {
          final isSelected = c == selected;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Color(0xFF0F4AA3),
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: Color(0xFF0F4AA3),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Color(0xFF0F4AA3), width: 1.5)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onSelected: (v) {
                if (v) {
                  setState(() => selected = c);
                  _loadAndFetch();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _applyTopFilter(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    if (selectedTop == 'Jadwal Pesanan') {
      return items.where((b) {
        final ride = b['ride'] ?? {};
        final dateStr =
            (ride['departure_date'] ?? b['created_at'] ?? '').toString();
        final dt = DateTime.tryParse(dateStr);
        return dt != null ? dt.isAfter(now) || dt.isAtSameMomentAs(now) : false;
      }).toList();
    }

    if (selectedTop == 'Riwayat') {
      return items.where((b) {
        final ride = b['ride'] ?? {};
        final dateStr =
            (ride['departure_date'] ?? b['created_at'] ?? '').toString();
        final dt = DateTime.tryParse(dateStr);
        if (dt != null && dt.isBefore(now)) return true;
        final status =
            (b['status'] ?? ride['status'] ?? '').toString().toLowerCase();
        return status.contains('selesai') ||
            status.contains('paid') ||
            status.contains('completed') ||
            status.contains('done');
      }).toList();
    }

    // Dalam Proses => not past and not completed
    return items.where((b) {
      final ride = b['ride'] ?? {};
      final dateStr =
          (ride['departure_date'] ?? b['created_at'] ?? '').toString();
      final dt = DateTime.tryParse(dateStr);
      if (dt != null && dt.isBefore(now)) return false;
      final status =
          (b['status'] ?? ride['status'] ?? '').toString().toLowerCase();
      if (status.contains('selesai') ||
          status.contains('paid') ||
          status.contains('completed') ||
          status.contains('done')) return false;
      return true;
    }).toList();
  }

  Widget _card(Map<String, dynamic> b) {
    final ride = b['ride'] ?? {};
    final bookingType = (b['booking_type'] ?? '').toString().toLowerCase();

    // Generate title based on booking type
    String title = 'Booking';
    if (bookingType == 'motor') {
      title = 'Nebeng Motor';
    } else if (bookingType == 'mobil') {
      title = 'Nebeng Mobil';
    } else if (bookingType == 'barang') {
      title = 'Nebeng Barang';
    } else if (bookingType == 'titip') {
      title = 'Titip Barang';
    }

    final status = (b['status'] ?? 'pending').toString();

    // Date/time from ride
    String rawDate =
        (ride['departure_date'] ?? b['created_at'] ?? '').toString();
    String rawTime = (ride['departure_time'] ?? '').toString();
    final dateTimeStr = _formatDateTime(rawDate, rawTime);

    // Origin/destination from ride relations
    String origin = '';
    String destination = '';

    if (ride['origin_location'] is Map && ride['origin_location'] != null) {
      origin = ride['origin_location']['name'] ?? '';
    }

    if (ride['destination_location'] is Map &&
        ride['destination_location'] != null) {
      destination = ride['destination_location']['name'] ?? '';
    }

    final route = (origin.isNotEmpty && destination.isNotEmpty)
        ? '$origin → $destination'
        : '';

    // Vehicle info from kendaraan_mitra relation
    String vehicle = '';
    String plate = '';

    if (ride['kendaraan_mitra'] is Map && ride['kendaraan_mitra'] != null) {
      final kendaraan = ride['kendaraan_mitra'];
      vehicle = (kendaraan['brand'] ?? '') + ' ' + (kendaraan['model'] ?? '');
      vehicle = vehicle.trim();
      if (vehicle.isEmpty) {
        vehicle = kendaraan['name'] ?? '';
      }
      plate = kendaraan['plate_number'] ?? '';
    }

    final seats = (b['seats'] ?? 1).toString();

    // Price from ride
    final rawPrice = ride['price'] ?? b['price'] ?? b['total_price'] ?? 0;
    // If booking is mobil, ride price is per-seat -> multiply by seats
    double unitPrice = double.tryParse(rawPrice.toString()) ?? 0;
    int seatsCount = int.tryParse(seats) ?? 1;
    double displayAmount;
    if (bookingType == 'mobil') {
      displayAmount = unitPrice * seatsCount;
    } else if (b.containsKey('total_price')) {
      displayAmount =
          double.tryParse(b['total_price']?.toString() ?? '0') ?? unitPrice;
    } else {
      displayAmount = unitPrice;
    }

    final priceStr = _formatPrice(displayAmount);

    // Status color
    Color statusColor;
    if (status.toLowerCase().contains('batalkan') ||
        status.toLowerCase().contains('cancel')) {
      statusColor = Colors.red;
    } else if (status.toLowerCase().contains('selesai') ||
        status.toLowerCase().contains('success')) {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingDetailRiwayatPage(booking: b),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title and status
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF0F4AA3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Text(
                  status.toString(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Route (show origin, clear arrow icon, destination)
            if (route.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      origin,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F4AA3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF0F4AA3),
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      destination,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F4AA3),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
            ],

            // Date and time
            Text(
              dateTimeStr,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),

            // Vehicle info
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${vehicle.isNotEmpty ? vehicle : ''}${vehicle.isNotEmpty && plate.isNotEmpty ? ' • ' : ''}${plate.isNotEmpty ? plate : ''}',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (seats.isNotEmpty) ...[
                  Icon(Icons.person, size: 18, color: Colors.grey[700]),
                  SizedBox(width: 4),
                  Text(
                    '$seats Orang',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16),

            // Total price
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Harga : ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  priceStr,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty && timeStr.isEmpty) return '';
    DateTime? dt;

    // Parse date first
    try {
      if (dateStr.isNotEmpty && dateStr.length > 4) {
        dt = DateTime.tryParse(dateStr);
      }
    } catch (_) {
      dt = null;
    }

    // If we have time separately, parse and apply it
    if (dt != null && timeStr.isNotEmpty) {
      try {
        // Parse time in format HH:mm or HH:mm:ss
        final timeParts = timeStr.split(':');
        if (timeParts.length >= 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          dt = DateTime(dt.year, dt.month, dt.day, hour, minute);
        }
      } catch (_) {
        // Keep original dt if time parsing fails
      }
    }

    // If dt is still null, try combining date and time strings
    if (dt == null && dateStr.isNotEmpty && timeStr.isNotEmpty) {
      final combined = '${dateStr.trim()} ${timeStr.trim()}';
      dt = DateTime.tryParse(combined);
    }

    if (dt != null) {
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu'
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
      final dayName = days[dt.weekday % 7];
      final day = dt.day;
      final month = months[dt.month];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$dayName, $day $month $year • $hour:$minute';
    }

    // Fallback: show raw date and time
    if (dateStr.isNotEmpty && timeStr.isNotEmpty) return '$dateStr • $timeStr';
    if (dateStr.isNotEmpty) return dateStr;
    return timeStr;
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'Rp0';

    double amount = 0;
    if (price is int) {
      amount = price.toDouble();
    } else if (price is double) {
      amount = price;
    } else if (price is String) {
      // Parse as double first to handle decimal values like "2000.00"
      amount = double.tryParse(price) ?? 0;
    }

    // Convert to int (remove decimals for display)
    int intAmount = amount.round();

    // Format with thousands separator using dot
    final formatted = intAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return 'Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // prevent material surface tint / elevation change when content scrolls under
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainPage()),
                    (route) => false);
              }
            }),
        title: Text('Pesanan',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: topTabs.map((t) {
                final active = t == selectedTop;
                return Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTop = t;
                        });
                      },
                      child: _buildTabItem(t, active),
                    ),
                    SizedBox(width: 24),
                  ],
                );
              }).toList(),
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            child: _filterChips(),
          ),

          Divider(height: 1, color: Colors.grey[300]),

          // Content
          Expanded(
            child: Builder(builder: (context) {
              if (loading) return Center(child: CircularProgressIndicator());
              if (error != null) return Center(child: Text(error!));
              if (bookings.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada riwayat',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              final visible = _applyTopFilter(bookings);
              if (visible.isEmpty) {
                return Center(
                  child: Text('Belum ada data untuk filter ini',
                      style: TextStyle(color: Colors.grey[600])),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(top: 16, bottom: 24),
                itemCount: visible.length,
                itemBuilder: (context, i) => _card(visible[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
            color: isActive ? Colors.black87 : Colors.grey[600],
          ),
        ),
        SizedBox(height: 8),
        if (isActive)
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: Color(0xFF0F4AA3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
