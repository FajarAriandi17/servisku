import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF5B6CFF);
  static const primaryLight = Color(0xFF8EA2FF);
  static const primaryDark = Color(0xFF3A3FB8);
  static const violet = Color(0xFF6A4DFF);
  static const accent = Color(0xFFFFB020);
  static const accentDark = Color(0xFFD98A00);
  static const bg = Color(0xFFEEF0FF);
  static const surface = Colors.white;
  static const ink = Color(0xFF1C2238);
  static const muted = Color(0xFF6E7591);
  static const success = Color(0xFF22C38E);
  static const successDark = Color(0xFF138A63);
  static const warning = Color(0xFFFFA726);
  static const warningDark = Color(0xFFC77700);
  static const danger = Color(0xFFFF5470);
  static const dangerDark = Color(0xFFC22746);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary, violet],
  );
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
