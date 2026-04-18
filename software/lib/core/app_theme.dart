// lib/core/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Shared
  static const accent  = Color(0xFF00BCD4);
  static const yes     = Color(0xFF00C853);
  static const no      = Color(0xFFFF1744);
  static const silent  = Color(0xFF78909C);

  // Dark
  static const darkBg      = Color(0xFF080D18);
  static const darkSurface = Color(0xFF0F1623);
  static const darkCard    = Color(0xFF161F30);
  static const darkText    = Color(0xFFE2E8F4);
  static const darkTextDim = Color(0xFF7A8899);
  static const darkBorder  = Color(0xFF1E2D42);

  // Light
  static const lightBg      = Color(0xFFF0F4F8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard    = Color(0xFFFFFFFF);
  static const lightText    = Color(0xFF1A2235);
  static const lightTextDim = Color(0xFF6B7A8D);
  static const lightBorder  = Color(0xFFDDE3EC);
}

class AppTheme {
  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.accent,
      surface:   AppColors.darkSurface,
      onPrimary: AppColors.darkBg,
      onSurface: AppColors.darkText,
    ),
    dividerColor: AppColors.darkBorder,
    useMaterial3: true,
  );

  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.accent,
      surface:   AppColors.lightSurface,
      onPrimary: Colors.white,
      onSurface: AppColors.lightText,
    ),
    dividerColor: AppColors.lightBorder,
    useMaterial3: true,
  );
}

/// Helper để lấy màu theo theme hiện tại
extension AppColorsContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cBg      => isDark ? AppColors.darkBg      : AppColors.lightBg;
  Color get cSurface => isDark ? AppColors.darkSurface  : AppColors.lightSurface;
  Color get cCard    => isDark ? AppColors.darkCard      : AppColors.lightCard;
  Color get cText    => isDark ? AppColors.darkText      : AppColors.lightText;
  Color get cTextDim => isDark ? AppColors.darkTextDim   : AppColors.lightTextDim;
  Color get cBorder  => isDark ? AppColors.darkBorder    : AppColors.lightBorder;
  Color get cAccent  => AppColors.accent;
  Color get cYes     => AppColors.yes;
  Color get cNo      => AppColors.no;
  Color get cSilent  => AppColors.silent;
}