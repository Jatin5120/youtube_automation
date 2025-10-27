import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const int _primaryHex = 0xFFE53E3E;

  static const MaterialColor primary = MaterialColor(
    _primaryHex,
    <int, Color>{
      50: Color(0xFFFED7D7),
      100: Color(0xFFFEB2B2),
      200: Color(0xFFFC8181),
      300: Color(0xFFF56565),
      400: Color(0xFFEF4444),
      500: Color(_primaryHex),
      600: Color(0xFFDC2626),
      700: Color(0xFFC53030),
      800: Color(0xFFB91C1C),
      900: Color(0xFF991B1B),
    },
  );

  static const int _accentHex = 0xFF3182CE;

  static const MaterialColor accent = MaterialColor(
    _accentHex,
    <int, Color>{
      50: Color(0xFFEBF8FF),
      100: Color(0xFFBEE3F8),
      200: Color(0xFF90CDF4),
      300: Color(0xFF63B3ED),
      400: Color(0xFF4299E1),
      500: Color(_accentHex),
      600: Color(0xFF2C5AA0),
      700: Color(0xFF2A4365),
      800: Color(0xFF1A365D),
      900: Color(0xFF1A202C),
    },
  );

  static const Color backgroundLight = Color(0xFFEBEBEB);
  static const Color backgroundDark = Color(0xFF121212);

  static const Color cardLight = Color(0xFFF0F0F0);
  static const Color cardDark = Color(0xFF2A2A2A);

  static const Color titleLight = Color(0xFF181818);
  static const Color titleDark = Color(0xFFF8F8F8);

  static const Color bodyLight = Color(0xFF333333);
  static const Color bodyDark = Color(0xFF9A9A9A);

  static const MaterialColor success = MaterialColor(0xFF4DB143, {
    100: Color(0xFFC7E9C4),
    500: Color(0xFF4DB143),
  });

  static const MaterialColor error = MaterialColor(0xFFED4126, {
    100: Color(0xFFF9BDB4),
    500: Color(0xFFED4126),
  });
}
