import 'package:intl/intl.dart';

class FormattingHelper {
  static String formatPrice(dynamic value) {
    if (value == null) return 'Rp 0';
    final numValue = (value is String) ? int.tryParse(value) ?? 0 : value;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(numValue);
  }

  static String formatDateTime(String date, String time) {
    try {
      if (date.isEmpty || time.isEmpty) return '-';

      // Handle ISO 8601 format (e.g., 2026-02-07T00:00:00.000000Z)
      DateTime dateTime;

      if (date.contains('T')) {
        // Parse ISO format date and extract only the date part
        final isoDate = DateTime.parse(date);

        // Parse time
        final timeParts = time.split(':');
        if (timeParts.length < 2) return '-';

        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second =
            timeParts.length >= 3 ? int.parse(timeParts[2].split('.')[0]) : 0;

        // Combine date from ISO with time from separate field
        dateTime = DateTime(
          isoDate.year,
          isoDate.month,
          isoDate.day,
          hour,
          minute,
          second,
        );
      } else {
        // Parse date parts (format: YYYY-MM-DD)
        final dateParts = date.split('-');
        final timeParts = time.split(':');

        if (dateParts.length < 3 || timeParts.length < 2) {
          return '-';
        }

        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second =
            timeParts.length >= 3 ? int.parse(timeParts[2].split('.')[0]) : 0;

        dateTime = DateTime(year, month, day, hour, minute, second);
      }

      // Format with Indonesian locale
      final formatter = DateFormat('EEEE, d MMM yyyy, HH:mm', 'id_ID');
      return formatter.format(dateTime);
    } catch (e) {
      print('Error formatting date: $e, date: $date, time: $time');
      return '-';
    }
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours jam ${minutes.toString().padLeft(2, '0')} menit';
    } else if (minutes > 0) {
      return '$minutes menit ${seconds.toString().padLeft(2, '0')} detik';
    } else {
      return '$seconds detik';
    }
  }

  static String formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }
}
