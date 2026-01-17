import 'package:flutter/material.dart';

class BarangHelpers {
  static String getTransportationLabel(String value) {
    switch (value) {
      case 'kereta':
        return 'Kereta';
      case 'pesawat':
        return 'Pesawat';
      case 'bus':
        return 'Bus';
      default:
        return '';
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
