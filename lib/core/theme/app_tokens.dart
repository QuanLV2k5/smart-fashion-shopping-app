import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ivory = Color(0xFFF7F5EF);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF242A27);
  static const muted = Color(0xFF65716A);
  static const primary = Color(0xFF254D40);
  static const sage = Color(0xFFE2E9DF);
  static const accent = Color(0xFFA54932);
  static const outline = Color(0xFFD8DED7);
  static const error = Color(0xFFAA3434);
  static const success = Color(0xFF2C6849);
  static const disabled = Color(0xFFB6BDB6);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const small = 4.0;
  static const medium = 8.0;
  static const large = 16.0;
}
