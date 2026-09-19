import 'package:flutter/material.dart';

/// لوحة الألوان الأساسية للتطبيق.
abstract final class AppColors {
  // Shared accents
  static const forestGreen = Color(0xFF14532D);
  static const emerald = Color(0xFF1D5B4F);
  static const softGold = Color(0xFFE8D8B5);

  // Light palette
  static const lightBackground = Color(0xFFF7F2E8);
  static const lightSurface = Colors.white;
  static const lightBorder = Color(0xFFE0D5C0);
  static const lightText = Color(0xFF0E1815);
  static const lightMutedText = Color(0xFF5A6B62);

  // Dark palette
  static const darkBackground = Color(0xFF081C15);
  static const darkSurface = Color(0xFF12372A);
  static const darkSecondarySurface = Color(0xFF1D5B4F);
  static const darkText = Color(0xFFEEF2EE);
  static const darkMutedText = Color(0xFF9FB1A9);
}

