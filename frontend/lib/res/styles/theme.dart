import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    canvasColor: AppColors.backgroundLight,
    cardTheme: const CardTheme(
      color: AppColors.cardLight,
      elevation: 0,
    ),
    textTheme: _textTheme,
    inputDecorationTheme: _inputTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    canvasColor: AppColors.backgroundDark,
    cardTheme: const CardTheme(
      color: AppColors.cardDark,
      elevation: 0,
    ),
    textTheme: _textTheme,
    inputDecorationTheme: _inputTheme,
  );

  static final TextTheme _textTheme = GoogleFonts.getTextTheme('Roboto');

  static final InputDecorationTheme _inputTheme = InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: AppColors.cardDark,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.primary,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.error,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: AppColors.error,
      ),
    ),
  );
}
