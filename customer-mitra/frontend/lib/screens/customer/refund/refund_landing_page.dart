import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'refund_form_page.dart';
import 'refund_list_page.dart';

class RefundLandingPage extends StatefulWidget {
  final int initialTab;

  const RefundLandingPage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<RefundLandingPage> createState() => _RefundLandingPageState();
}

class _RefundLandingPageState extends State<RefundLandingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> refunds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      final userId = prefs.getInt('user_id');

      print('DEBUG: Token exists: ${token != null}');
      if (token != null) {
        print('DEBUG: Token length: ${token.length}');
      }

      if (token != null && userId != null) {
        // Load bookings and refunds in parallel
        final results = await Future.wait([
          ApiService.fetchBookings(
            token: token,
            type: 'semua',
          ),
          ApiService.getRefundHistory(userId),
        ]);

        final data = results[0] as List<Map<String, dynamic>>;
        final refundData = results[1] as List<Map<String, dynamic>>;

        print('DEBUG: Total bookings from API: ${data.length}');
        print('DEBUG: Total refunds from API: ${refundData.length}');

        // Create a set of booking IDs that already have refund requests
        final refundedBookingIds = <String>{};
        for (var refund in refundData) {
          final bookingId = refund['booking_id']?.toString() ?? '';
          final bookingType = refund['booking_type'] ?? '';
          if (bookingId.isNotEmpty && bookingType.isNotEmpty) {
            refundedBookingIds.add('${bookingType}_$bookingId');
          }
        }

        print('DEBUG: Refunded booking IDs: $refundedBookingIds');

        for (var booking in data) {
          print(
              'DEBUG: Booking ${booking['id']} - Status: ${booking['status']} - Type: ${booking['booking_type']}');
        }

        // Filter only cancelled bookings that don't have refund requests
        final eligibleBookings = data.where((booking) {
          final status = booking['status'] ?? '';
          final bookingId = booking['id']?.toString() ?? '';
          final bookingType = booking['booking_type'] ?? '';
          final key = '${bookingType}_$bookingId';

          final isEligibleStatus = status == 'cancelled';
          final hasNoRefund = !refundedBookingIds.contains(key);

          return isEligibleStatus && hasNoRefund;
        }).toList();

        print(
            'DEBUG: Eligible bookings after filter: ${eligibleBookings.length}');

        setState(() {
          bookings = eligibleBookings;
          refunds = refundData;
          isLoading = false;
        });
      } else {
        print('DEBUG: No auth token found');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('ERROR loading bookings: $e');
      print('ERROR stack trace: ${StackTrace.current}');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Refund',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F4AA3),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF0F4AA3),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Pilih Booking'),
            Tab(text: 'Riwayat Refund'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingListTab(),
          const RefundListPage(isEmbedded: true),
        ],
      ),
    );
  }

  Widget _buildBookingListTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada booking yang dapat di-refund',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hanya booking yang dibatalkan\nyang dapat di-refund',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final ride = booking['ride'] ?? {};
    final bookingType =
        (booking['booking_type'] ?? 'motor').toString().toLowerCase();
    final kendaraan = ride['kendaraan_mitra'] ?? {};

    final originLocation = ride['origin_location'] ?? {};
    final destinationLocation = ride['destination_location'] ?? {};

    final originName = originLocation['name'] ?? 'Unknown';
    final destinationName = destinationLocation['name'] ?? 'Unknown';
    final departureDate = ride['departure_date'] ?? '';
    final departureTime = ride['departure_time'] ?? '';
    final status = booking['status'] ?? '';

    // Vehicle info
    final vehicleName = kendaraan['name'] ?? '';
    final plateNumber = kendaraan['plate_number'] ?? '';

    // Parse date
    String formattedDate = '';
    String dayName = '';
    try {
      final dt = DateTime.parse(departureDate);
      formattedDate =
          '${dt.day.toString().padLeft(2, '0')} ${_getMonthName(dt.month)} ${dt.year}';
      dayName = _getDayName(dt.weekday);
    } catch (e) {
      formattedDate = departureDate;
    }

    // Parse time (format HH:mm:ss to HH:mm)
    String formattedTime = '';
    try {
      if (departureTime.contains(':')) {
        final timeParts = departureTime.split(':');
        if (timeParts.length >= 2) {
          formattedTime = '${timeParts[0]}:${timeParts[1]}';
        }
      }
    } catch (e) {
      formattedTime = departureTime;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black87,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RefundFormPage(booking: booking),
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
                            _getBookingTypeName(bookingType),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (vehicleName.isNotEmpty || plateNumber.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [vehicleName, plateNumber]
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Origin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            originName,
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
                            dayName.isNotEmpty && formattedDate.isNotEmpty
                                ? '$dayName    $formattedDate'
                                : formattedDate,
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
                            destinationName,
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
                            dayName.isNotEmpty && formattedDate.isNotEmpty
                                ? '$dayName    $formattedDate'
                                : formattedDate,
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

                // Status badge
                if (status.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildBookingTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'motor':
        icon = Icons.two_wheeler;
        color = const Color(0xFF0F4AA3);
        break;
      case 'mobil':
        icon = Icons.directions_car;
        color = const Color(0xFF0F4AA3);
        break;
      case 'barang':
        icon = Icons.local_shipping;
        color = const Color(0xFF0F4AA3);
        break;
      case 'titip':
        icon = Icons.inventory_2;
        color = const Color(0xFF0F4AA3);
        break;
      default:
        icon = Icons.directions_car;
        color = const Color(0xFF0F4AA3);
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

  String _getBookingTypeName(String type) {
    switch (type) {
      case 'motor':
        return 'Nebeng Motor';
      case 'mobil':
        return 'Nebeng Mobil';
      case 'barang':
        return 'Nebeng Barang';
      case 'titip':
        return 'Titip Barang';
      default:
        return 'Booking';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Sudah Dibayar';
      case 'confirmed':
        return 'Dikonfirmasi';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'confirmed':
        return const Color(0xFF2196F3);
      default:
        return Colors.grey;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  String _getDayName(int weekday) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    return days[weekday - 1];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
