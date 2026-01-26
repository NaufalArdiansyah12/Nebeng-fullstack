/// Utility functions for formatting booking-related data
class BookingFormatters {
  /// Format date and time into readable Indonesian format
  static String formatDateTime(String dateStr, String timeStr) {
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

  /// Format date only into readable Indonesian format
  static String formatDateOnly(String dateStr) {
    if (dateStr.isEmpty) return '';
    DateTime? dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;

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
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month]} ${dt.year}';
  }

  /// Format price to Indonesian Rupiah format
  static String formatPrice(dynamic price) {
    if (price == null) return 'Rp0';
    double amount = 0;
    if (price is int) {
      amount = price.toDouble();
    } else if (price is double) {
      amount = price;
    } else if (price is String) {
      amount = double.tryParse(price) ?? 0;
    }
    int intAmount = amount.round();
    final formatted = intAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return 'Rp$formatted';
  }

  /// Get human-readable status text
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'menuju_penjemputan':
        return 'Menuju Penjemputan';
      case 'sudah_di_penjemputan':
        return 'Di Titik Penjemputan';
      case 'menuju_tujuan':
        return 'Menuju Tujuan';
      case 'sudah_sampai_tujuan':
        return 'Sudah Sampai Tujuan';
      case 'completed':
        return 'Trip Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'scheduled':
        return 'Dijadwalkan';
      case 'paid':
        return 'Sudah Dibayar';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'pending':
        return 'Menunggu Pembayaran';
      default:
        return status; // Return original status if unknown
    }
  }
}
