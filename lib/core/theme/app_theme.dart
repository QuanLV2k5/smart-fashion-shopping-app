import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static const _label = TextStyle(
    letterSpacing: 0,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w600,
  );

  static final light = ThemeData(
    useMaterial3: true,
    // Web trên desktop cũng giữ nút 48px như thiết kế mobile.
    visualDensity: VisualDensity.standard,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: AppColors.ivory,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.sage,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: AppColors.white,
      surface: AppColors.ivory,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.outline,
      error: AppColors.error,
      onError: AppColors.white,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        letterSpacing: 0,
        fontSize: 32,
        height: 40 / 32,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        letterSpacing: 0,
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        letterSpacing: 0,
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 22 / 14, letterSpacing: 0),
      bodySmall: TextStyle(fontSize: 12, height: 18 / 12, letterSpacing: 0),
      labelLarge: _label,
      labelSmall: TextStyle(
        letterSpacing: 0,
        fontSize: 10,
        height: 14 / 10,
        fontWeight: FontWeight.w500,
      ),
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ivory,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: _label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: _label,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.all(AppSpacing.sm),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 82,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.sage,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline),
  );
}
