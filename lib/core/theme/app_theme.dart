import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(
        brightness: Brightness.light,
        scaffoldBackground: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        text: AppColors.lightText,
        mutedText: AppColors.lightMutedText,
      );

  static ThemeData get dark => _theme(
        brightness: Brightness.dark,
        scaffoldBackground: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        text: AppColors.darkText,
        mutedText: AppColors.darkMutedText,
      );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surface,
    required Color text,
    required Color mutedText,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
      primary: AppColors.forestGreen,
      secondary: AppColors.gold,
      surface: surface,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: text,
        fontSize: 26,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: text,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: text,
        fontSize: 15,
        height: 1.6,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: mutedText,
        fontSize: 12,
        height: 1.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: text,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.18)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.forestGreen,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.softGold
                  : AppColors.darkMutedText,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => textTheme.bodySmall?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? AppColors.softGold
                  : AppColors.darkMutedText,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
      dividerTheme: DividerThemeData(
        color: mutedText.withValues(alpha: 0.16),
        space: 1,
      ),
    );
  }
}

