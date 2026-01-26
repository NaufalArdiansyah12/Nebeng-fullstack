import 'package:flutter/material.dart';

/// Widget to display price breakdown
class PriceCard extends StatelessWidget {
  final String pricePerSeat;
  final String seats;
  final String totalPrice;
  final String bookingType;
  final Map<String, dynamic> booking;

  const PriceCard({
    Key? key,
    required this.pricePerSeat,
    required this.seats,
    required this.totalPrice,
    required this.bookingType,
    required this.booking,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBarangOrTitip = bookingType == 'barang' || bookingType == 'titip';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Harga per Kursi', pricePerSeat, false),
          const SizedBox(height: 14),
          _buildPriceRow(
            (bookingType == 'motor' || bookingType == 'mobil')
                ? 'Jumlah Kursi'
                : 'Total Penumpang',
            seats,
            false,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.grey[200]),
          ),
          _buildPriceRow('Total Pembayaran', totalPrice, true),
          if (isBarangOrTitip) ...[
            const SizedBox(height: 20),
            _buildInfoRow(
              'No Pesanan',
              booking['id']?.toString() ?? 'FR-234567899754324',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Waktu Pemesanan',
              _formatDateTime(booking['created_at'] ?? '', '09:00-16:00'),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Pembayaran', 'Transfer'),
            const SizedBox(height: 12),
            _buildInfoRow('Bukti Pengiriman', 'Lihat Foto'),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? const Color(0xFF0F4AA3) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: label == 'Bukti Pengiriman'
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String dateStr, String timeStr) {
    if (dateStr.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    if (timeStr.isNotEmpty) {
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        dt = DateTime(dt.year, dt.month, dt.day, hour, minute);
      }
    }
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    const months = [
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
    return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month]} ${dt.year}';
  }
}
