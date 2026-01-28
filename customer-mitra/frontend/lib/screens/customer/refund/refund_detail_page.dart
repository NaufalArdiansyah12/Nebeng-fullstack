import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class RefundDetailPage extends StatefulWidget {
  final int refundId;

  const RefundDetailPage({Key? key, required this.refundId}) : super(key: key);

  @override
  State<RefundDetailPage> createState() => _RefundDetailPageState();
}

class _RefundDetailPageState extends State<RefundDetailPage> {
  Map<String, dynamic>? refund;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRefundDetail();
  }

  Future<void> _loadRefundDetail() async {
    try {
      final data = await ApiService.getRefundDetail(widget.refundId);
      setState(() {
        refund = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading refund detail: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4AA3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : refund == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressSection(),
                      const SizedBox(height: 16),
                      _buildDetailRefundSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProgressSection() {
    final status = refund!['status'] ?? 'pending';
    final steps = _getProgressSteps(status);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Refund',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;

            return _buildProgressStep(
              step['title']!,
              step['subtitle']!,
              step['date']!,
              step['status']!,
              isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  List<Map<String, String>> _getProgressSteps(String status) {
    final submittedDate = _formatDateTime(refund!['submitted_at']);
    final approvedDate = _formatDateTime(refund!['approved_at']);
    final processedDate = _formatDateTime(refund!['processed_at']);
    final completedDate = _formatDateTime(refund!['completed_at']);

    final steps = <Map<String, String>>[];

    // Step 1: Submitted
    steps.add({
      'title': 'Refund Telah Diajukan - $submittedDate',
      'subtitle':
          'Proses pengembalian dana sedang berlangsung dan akan diproses dalam 3-5 hari kerja',
      'date': submittedDate,
      'status': 'completed',
    });

    // Step 2: Approved/Verified
    if (status == 'approved' ||
        status == 'processing' ||
        status == 'completed') {
      steps.add({
        'title': 'Memeriksa Pengajuan Anda - $approvedDate',
        'subtitle':
            'Saat ini, Admin kami sedang memeriksa informasi yang telah Anda kirimkan',
        'date': approvedDate,
        'status': 'completed',
      });
    } else {
      steps.add({
        'title': 'Memeriksa Pengajuan Anda',
        'subtitle':
            'Saat ini, Admin kami sedang memeriksa informasi yang telah Anda kirimkan',
        'date': '',
        'status': 'pending',
      });
    }

    // Step 3: Processing
    if (status == 'processing' || status == 'completed') {
      steps.add({
        'title': 'Refund Disetujui - $processedDate',
        'subtitle':
            'Pemeriksaan pengajuan Anda sudah disetujui! Dana Anda akan segera ditransfer ke rekening Anda yang terdaftar',
        'date': processedDate,
        'status': 'completed',
      });
    } else {
      steps.add({
        'title': 'Refund Disetujui',
        'subtitle':
            'Pemeriksaan pengajuan Anda sudah disetujui! Dana Anda akan segera ditransfer ke rekening Anda yang terdaftar',
        'date': '',
        'status': 'pending',
      });
    }

    // Step 4: In Progress
    if (status == 'completed') {
      steps.add({
        'title': 'Refund Sedang Dikirim - $completedDate',
        'subtitle':
            'Refund Anda sedang diproses. Harap bersabarlah dan akan segera masuk ke rekening Anda',
        'date': completedDate,
        'status': 'completed',
      });
    } else {
      steps.add({
        'title': 'Refund Sedang Dikirim',
        'subtitle':
            'Refund Anda sedang diproses. Harap bersabarlah dan akan segera masuk ke rekening Anda',
        'date': '',
        'status': 'pending',
      });
    }

    // Step 5: Completed
    if (status == 'completed') {
      steps.add({
        'title': 'Refund Telah DiTransfer - $completedDate',
        'subtitle':
            'Refund Anda sebesar Rp${_formatPrice(refund!['refund_amount'])} telah berhasil kami proses dan akan segera masuk ke rekening Anda. Terima kasih!',
        'date': completedDate,
        'status': 'completed',
      });
    } else {
      steps.add({
        'title': 'Refund Telah DiTransfer',
        'subtitle':
            'Refund Anda sebesar Rp${_formatPrice(refund!['refund_amount'])} telah berhasil kami proses dan akan segera masuk ke rekening Anda. Terima kasih!',
        'date': '',
        'status': 'pending',
      });
    }

    return steps;
  }

  Widget _buildProgressStep(
    String title,
    String subtitle,
    String date,
    String status,
    bool isLast,
  ) {
    final isCompleted = status == 'completed';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFF0F4AA3) : Colors.grey[300],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted ? const Color(0xFF0F4AA3) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                    color: isCompleted
                        ? const Color(0xFF0F4AA3)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRefundSection() {
    final bookingData = refund!['booking_data'];
    final ride = bookingData?['ride'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Refund',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Rincian Dana Refund', ''),
          _buildDetailRow(
            'Total Dana Asli',
            'Rp${_formatPrice(refund!['total_amount'])}',
          ),
          _buildDetailRow(
            'Estimasi Refund',
            'Rp${_formatPrice(refund!['refund_amount'])}',
            isHighlight: true,
          ),
          const Divider(height: 32),
          _buildDurationInfo(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isHighlight ? Colors.black87 : Colors.grey[700],
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
              color: isHighlight ? const Color(0xFF0F4AA3) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Color(0xFF0F4AA3),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Durasi Proses Refund',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F4AA3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTime);
      return '${_getDayName(dt.weekday)}, ${dt.day} ${_getMonthName(dt.month)} ${dt.year}';
    } catch (e) {
      return '';
    }
  }

  String _getDayName(int day) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[day - 1];
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
}
