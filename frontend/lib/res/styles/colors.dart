import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const MaterialColor primary = Colors.blue;

  static const Color backgroundLight = Color(0xFFEBEBEB);
  static const Color backgroundDark = Color(0xFF333333);

  static const Color cardLight = Color(0xFFF0F0F0);
  static const Color cardDark = Color(0xFF444444);

  static const Color titleLight = Color(0xFF181818);
  static const Color titleDark = Color(0xFFF8F8F8);

  static const Color bodyLight = Color(0xFF333333);
  static const Color bodyDark = Color(0xFFDEDEDE);

  static const Color success = MaterialColor(0xFF4DB143, {
    100: Color(0xFFC7E9C4),
    500: Color(0xFF4DB143),
  });

  static const Color error = MaterialColor(0xFFED4126, {
    100: Color(0xFFF9BDB4),
    500: Color(0xFFED4126),
  });

  static const Color github = Color(0xFF181717);
  static const Color instagram = Color(0xFFE4405F);
  static const Color linkedin = Color(0xFF0077B5);
  static const Color twitter = Color(0xFF000000);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color medium = Color(0xFF000000);
}
