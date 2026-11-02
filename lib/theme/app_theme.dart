import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Chart-paper palette and typography for Godspeed Ginny.
abstract final class AppColors {
  static const chart = Color(0xFFDCDCCB);
  static const chartDeep = Color(0xFFC9C9B4);
  static const ink = Color(0xFF141C18);
  static const inkSoft = Color(0xFF4A5450);
  static const water = Color(0xFF2C5F5C);
  static const stamp = Color(0xFF8E2A2A);
  static const brass = Color(0xFFA8791E);
  static const pencil = Color(0xFF3B4A55);
  static const surface = Color(0x47FFFFFF);
}

abstract final class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.chart,
      colorScheme: const ColorScheme.light(
        primary: AppColors.water,
        onPrimary: AppColors.chart,
        secondary: AppColors.brass,
        onSecondary: AppColors.chart,
        error: AppColors.stamp,
        onError: AppColors.chart,
        surface: AppColors.chart,
        onSurface: AppColors.ink,
      ),
      dividerColor: AppColors.chartDeep,
      splashFactory: InkRipple.splashFactory,
    );

    final body = GoogleFonts.newsreaderTextTheme(base.textTheme);
    final display = GoogleFonts.zillaSlabTextTheme(base.textTheme);
    final mono = GoogleFonts.courierPrimeTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: body.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          height: 0.95,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: display.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: body.bodyLarge?.copyWith(
          color: AppColors.ink,
          fontSize: 17,
          height: 1.55,
        ),
        bodyMedium: body.bodyMedium?.copyWith(
          color: AppColors.inkSoft,
          fontSize: 15,
          height: 1.5,
          fontStyle: FontStyle.italic,
        ),
        labelLarge: mono.labelLarge?.copyWith(
          color: AppColors.inkSoft,
          letterSpacing: 2.2,
          fontSize: 13,
        ),
        labelMedium: mono.labelMedium?.copyWith(
          color: AppColors.inkSoft,
          letterSpacing: 1.6,
          fontSize: 12,
        ),
        labelSmall: mono.labelSmall?.copyWith(
          color: AppColors.inkSoft,
          letterSpacing: 1.4,
          fontSize: 12,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.chart,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: display.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static TextStyle get mono => GoogleFonts.courierPrime(
        color: AppColors.inkSoft,
        letterSpacing: 0.4,
      );

  static TextStyle get display => GoogleFonts.zillaSlab(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get handwriting => GoogleFonts.caveat(
        color: AppColors.pencil,
        fontSize: 21,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get stamp => GoogleFonts.courierPrime(
        color: AppColors.stamp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );
}
