import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _theme(
        brightness: Brightness.light,
        scaffoldBackground: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        text: AppColors.lightText,
        mutedText: AppColors.lightMutedText,
        accent: AppColors.forestGreen,
        border: AppColors.lightBorder,
      );

  static ThemeData get dark => _theme(
        brightness: Brightness.dark,
        scaffoldBackground: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        text: AppColors.darkText,
        mutedText: AppColors.darkMutedText,
        accent: AppColors.softGold,
        border: AppColors.darkSecondarySurface,
      );

  static ThemeData _theme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color surface,
    required Color text,
    required Color mutedText,
    required Color accent,
    required Color border,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: brightness,
      primary: AppColors.forestGreen,
      secondary: accent,
      surface: surface,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final textTheme = baseTextTheme.copyWith(
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        color: text,
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        color: text,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: text,
        fontSize: 17,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: text,
        fontSize: 14,
        height: 1.6,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: mutedText,
        fontSize: 13,
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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: brightness == Brightness.dark ? .5 : 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: accent,
          foregroundColor: brightness == Brightness.dark ? AppColors.darkBackground : Colors.white,
          textStyle: textTheme.titleMedium,
          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: scaffoldBackground,
        indicatorColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? accent
                  : mutedText,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => textTheme.bodySmall?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? accent
                  : mutedText,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        space: 1,
      ),
      iconTheme: IconThemeData(color: accent, size: 22),
    );
  }
}

