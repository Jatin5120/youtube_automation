import 'package:davi/davi.dart';
import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    canvasColor: AppColors.backgroundLight,
    cardTheme: const CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
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
    cardTheme: const CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
    ),
    textTheme: _textTheme,
    inputDecorationTheme: _inputTheme,
  );

  static final TextTheme _textTheme = GoogleFonts.interTextTheme();

  static final InputDecorationTheme _inputTheme = InputDecorationTheme(
    isDense: true,
    filled: true,
    fillColor: AppColors.backgroundDark,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.cardDark,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.cardLight,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.error,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: AppColors.error,
      ),
    ),
  );

  static final DaviThemeData daviTheme = DaviThemeData(
    header: const HeaderThemeData(
      color: AppColors.cardDark,
    ),
    headerCell: HeaderCellThemeData(
      alignment: Alignment.center,
      textStyle: _textTheme.titleSmall?.withTitleColor,
    ),
    row: RowThemeData(
      color: (_) => AppColors.backgroundDark,
      hoverForeground: (_) => AppColors.cardDark.withValues(alpha: 0.2),
      fillHeight: true,
    ),
    cell: CellThemeData(
      textStyle: _textTheme.bodyMedium?.withTitleColor,
    ),
  );
}
