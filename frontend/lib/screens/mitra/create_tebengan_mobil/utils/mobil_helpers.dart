import 'package:flutter/material.dart';

class MobilHelpers {
  static String getServiceTypeLabel(String value) {
    switch (value) {
      case 'tebengan':
        return 'Hanya Tebengan';
      case 'barang':
        return 'Hanya Titip Barang';
      case 'both':
        return 'Barang dan Tebengan';
      default:
        return 'Pilih Jenis Layanan';
    }
  }

  static String getBagasiLabel(int? capacity) {
    if (capacity == null) return '';

    switch (capacity) {
      case 5:
        return 'Kecil - Maksimal 5 kg';
      case 10:
        return 'Sedang - Maksimal 10 kg';
      case 20:
        return 'Besar - Maksimal 20 kg';
      default:
        return '';
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
