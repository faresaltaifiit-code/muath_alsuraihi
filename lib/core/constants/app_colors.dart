import 'package:flutter/material.dart';

/// لوحة الألوان الأساسية للتطبيق.
abstract final class AppColors {
  // Shared accents
  static const emerald = Color(0xFF2F8F78);
  static const forestGreen = Color(0xFF14503F);
  static const softGold = Color(0xFFE9D7B1);
  static const goldAccent = Color(0xFFB98A2E);
  static const favoriteRed = Color(0xFFD9607A);

  // Light palette
  static const lightBackground = Color(0xFFF4EFE3);
  static const lightSurface = Colors.white;
  static const lightSecondarySurface = Color(0xFFF0E9D8);
  static const lightBorder = Color(0xFFE0D6BD);
  static const lightText = Color(0xFF10281F);
  static const lightMutedText = Color(0xFF6B7A70);

  // Dark palette
  static const darkBackground = Color(0xFF08150F);
  static const darkSurface = Color(0xFF10261D);
  static const darkSecondarySurface = Color(0xFF173629);
  static const darkBorder = Color(0xFF21473A);
  static const darkText = Color(0xFFF3ECDC);
  static const darkMutedText = Color(0xFF8FA79B);
}
