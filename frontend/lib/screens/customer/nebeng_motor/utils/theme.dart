import 'package:flutter/material.dart';

class NebengMotorTheme {
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color greenIcon = Color(0xFF22C55E);
  static const Color orangeIcon = Color(0xFFF97316);
  static const Color historyIconBg = Color(0xFFE0E7FF);

  static ThemeData get datePickerTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        onPrimary: Colors.white,
        onSurface: Colors.black,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
        ),
      ),
    );
  }
}
