import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_page.dart';
import '../../../services/api_service.dart';
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 12),
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

    // Dalam Proses => only show rides scheduled for today and not completed/cancelled
    return items.where((b) {
      final ride = b['ride'] ?? {};
      final dateStr =
          (ride['departure_date'] ?? b['created_at'] ?? '').toString();
      final dt = DateTime.tryParse(dateStr);

      // If we don't have a valid departure date, skip it for "Dalam Proses"
      if (dt == null) return false;

      // Compare only the date part (year, month, day) with today
      if (!(dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day)) {
        return false;
      }

      final status =
          (b['status'] ?? ride['status'] ?? '').toString().toLowerCase();
      // Include in-progress statuses (removed in_progress as it's been deleted)
      if (status == 'menuju_penjemputan' ||
          status == 'sudah_di_penjemputan' ||
          status == 'menuju_tujuan' ||
          status == 'sudah_sampai_tujuan' ||
          status == 'confirmed' ||
          status == 'scheduled') {
        return true;
      }

      // Exclude completed/cancelled statuses
      if (status.contains('selesai') ||
          status.contains('paid') ||
          status.contains('completed') ||
          status.contains('done') ||
          status.contains('cancel') ||
          status.contains('batalkan')) return false;

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

    // statusColor removed — badge rendering handled by _buildStatusBadge

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingDetailRiwayatPage(booking: b),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and type
                Row(
                  children: [
                    _buildBookingTypeIcon(bookingType),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (vehicle.isNotEmpty || plate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [vehicle, plate]
                                    .where((s) => s.isNotEmpty)
                                    .join(' • '),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Dashed divider
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: DashedLinePainter(
                    color: Colors.grey[400]!,
                  ),
                ),

                const SizedBox(height: 16),

                // Route information
                if (route.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              origin,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateOnly(rawDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.blue[700],
                          size: 24,
                        ),
                      ),

                      // Destination
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              destination,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateOnly(rawDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Passenger info
                if (seats.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.grey[700]),
                      const SizedBox(width: 4),
                      Text(
                        '$seats Orang',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],

                // Status and amount section
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          priceStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F4AA3),
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateOnly(String dateStr) {
    if (dateStr.isEmpty) return '';
    DateTime? dt;

    try {
      if (dateStr.length > 4) {
        dt = DateTime.tryParse(dateStr);
      }
    } catch (_) {
      dt = null;
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
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month];
      final year = dt.year;
      return '$dayName    $day $month $year';
    }

    return dateStr;
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

  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase();
    String label;
    Color bg;
    Color textColor;

    if (s.contains('cancel') || s.contains('batalkan')) {
      label = 'Dibatalkan';
      bg = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFEF4444);
    } else if (s.contains('completed') ||
        s.contains('selesai') ||
        s.contains('done') ||
        s.contains('success')) {
      label = 'Selesai';
      bg = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF4CAF50);
    } else if (s == 'menuju_penjemputan') {
      label = 'Menuju Penjemputan';
      bg = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1E3A8A);
    } else if (s == 'sudah_di_penjemputan') {
      label = 'Di Penjemputan';
      bg = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1E3A8A);
    } else if (s == 'menuju_tujuan') {
      label = 'Menuju Tujuan';
      bg = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1E3A8A);
    } else if (s == 'sudah_sampai_tujuan') {
      label = 'Sampai Tujuan';
      bg = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1E3A8A);
    } else if (s == 'scheduled') {
      label = 'Dijadwalkan';
      bg = const Color(0xFFF3E5F5);
      textColor = Colors.purple;
    } else if (s.contains('paid') || s.contains('confirmed')) {
      label = 'Menunggu';
      bg = const Color(0xFFFFF4E5);
      textColor = const Color(0xFFFF9800);
    } else if (s == 'pending') {
      label = 'Pending';
      bg = Colors.grey[200]!;
      textColor = Colors.grey[700]!;
    } else {
      label = status;
      bg = Colors.grey[200]!;
      textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildBookingTypeIcon(String type) {
    IconData icon;
    Color color = const Color(0xFF0F4AA3);

    switch (type) {
      case 'motor':
        icon = Icons.two_wheeler;
        break;
      case 'mobil':
        icon = Icons.directions_car;
        break;
      case 'barang':
        icon = Icons.local_shipping;
        break;
      case 'titip':
        icon = Icons.inventory_2;
        break;
      default:
        icon = Icons.directions_car;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
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
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
            child: Row(
              children: topTabs.map((t) {
                final active = t == selectedTop;
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTop = t;
                      });
                    },
                    child: _buildTabItem(t, active),
                  ),
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

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
