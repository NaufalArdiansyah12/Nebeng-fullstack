import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';
import 'refund_detail_page.dart';

class RefundListPage extends StatefulWidget {
  final bool isEmbedded;

  const RefundListPage({
    Key? key,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<RefundListPage> createState() => _RefundListPageState();
}

class _RefundListPageState extends State<RefundListPage> {
  List<Map<String, dynamic>> refunds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRefunds();
  }

  Future<void> _loadRefunds() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        final data = await ApiService.getRefundHistory(userId);
        setState(() {
          refunds = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading refunds: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = isLoading
        ? const Center(child: CircularProgressIndicator())
        : refunds.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadRefunds,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: refunds.length,
                  itemBuilder: (context, index) {
                    return _buildRefundCard(refunds[index]);
                  },
                ),
              );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Refund',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: body,
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
            'Belum ada pengajuan refund',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundCard(Map<String, dynamic> refund) {
    final status = refund['status'] ?? 'pending';
    final bookingData = refund['booking_data'];
    final ride = bookingData?['ride'];
    final kendaraan = ride?['kendaraan_mitra'] ?? {};

    final originLocation = ride?['origin_location'] ?? {};
    final destinationLocation = ride?['destination_location'] ?? {};

    final originName = originLocation['name'] ?? 'Unknown';
    final destinationName = destinationLocation['name'] ?? 'Unknown';
    final departureDate = ride?['departure_date'] ?? '';
    final bookingType = refund['booking_type'] ?? 'motor';

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
                builder: (_) => RefundDetailPage(refundId: refund['id']),
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

                // Status and amount section
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimasi Refund',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rp${_formatPrice(refund['refund_amount'])}',
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

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFFF4E5);
        textColor = const Color(0xFFFF9800);
        label = 'Pending';
        break;
      case 'approved':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF2196F3);
        label = 'Disetujui';
        break;
      case 'processing':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        label = 'Diproses';
        break;
      case 'completed':
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF4CAF50);
        label = 'Selesai';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFEF4444);
        label = 'Ditolak';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
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

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date);
      return '${dt.day} ${_getMonthName(dt.month)} ${dt.year}';
    } catch (e) {
      return '';
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
