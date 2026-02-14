import 'package:flutter/material.dart';

/// Utility class untuk formatting status booking/ride
class StatusFormatter {
  /// Convert status string menjadi label yang user-friendly
  static String formatStatusLabel(String rawStatus) {
    final status = rawStatus.toLowerCase();

    switch (status) {
      case 'active':
        return 'Aktif';
      case 'completed':
      case 'selesai':
        return 'Selesai';
      case 'cancelled':
      case 'dibatalkan':
        return 'Dibatalkan';
      case 'full':
        return 'Penuh';
      case 'pending':
        return 'Menunggu';
      case 'paid':
        return 'Terbayar';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'scheduled':
        return 'Terjadwal';
      case 'menuju_penjemputan':
        return 'Menuju Penjemputan';
      case 'sudah_di_penjemputan':
        return 'Sudah di Penjemputan';
      case 'menuju_tujuan':
        return 'Menuju Tujuan';
      case 'sudah_sampai_tujuan':
        return 'Sudah Sampai Tujuan';
      case 'in_progress':
        return 'Dalam Proses';
      default:
        if (status.isEmpty) return 'Tidak Diketahui';
        // Capitalize first letter
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  /// Get warna background untuk status badge
  static Color getStatusBackgroundColor(String rawStatus) {
    final status = rawStatus.toLowerCase();

    switch (status) {
      case 'active':
      case 'pending':
        return const Color(0xFFFFF4EA);
      case 'completed':
      case 'selesai':
      case 'sudah_di_penjemputan':
      case 'sudah_sampai_tujuan':
        return const Color(0xFFE8F5E9);
      case 'paid':
      case 'confirmed':
      case 'scheduled':
        return const Color(0xFFE3F2FD);
      case 'menuju_penjemputan':
      case 'menuju_tujuan':
      case 'in_progress':
        return const Color(0xFFE1F5FE);
      case 'cancelled':
      case 'dibatalkan':
        return const Color(0xFFF5F5F5);
      case 'full':
        return const Color(0xFFFFE6E6);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  /// Get warna text untuk status badge
  static Color getStatusTextColor(String rawStatus) {
    final status = rawStatus.toLowerCase();

    switch (status) {
      case 'active':
      case 'pending':
        return const Color(0xFFFF8C00);
      case 'completed':
      case 'selesai':
      case 'sudah_di_penjemputan':
      case 'sudah_sampai_tujuan':
        return const Color(0xFF2E7D32);
      case 'paid':
      case 'confirmed':
      case 'scheduled':
        return const Color(0xFF1976D2);
      case 'menuju_penjemputan':
      case 'menuju_tujuan':
      case 'in_progress':
        return const Color(0xFF0277BD);
      case 'cancelled':
      case 'dibatalkan':
        return const Color(0xFF757575);
      case 'full':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF757575);
    }
  }

  /// Membuat widget status badge
  static Widget buildStatusBadge(
    String rawStatus, {
    EdgeInsetsGeometry? padding,
    double? fontSize,
  }) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
      decoration: BoxDecoration(
        color: getStatusBackgroundColor(rawStatus),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatStatusLabel(rawStatus),
        style: TextStyle(
          fontSize: fontSize ?? 11,
          color: getStatusTextColor(rawStatus),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
