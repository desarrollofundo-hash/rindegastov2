import 'package:flutter/material.dart';

class AppTheme {
  // Colores para modo claro
  static const Color primaryLight = Color(0xFF0066FF);
  static const Color backgroundLight = Color(0xFFF2F6FC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Colores para modo oscuro
  static const Color primaryDark = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Titillium',
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: primaryLight,
      secondary: primaryLight,
      surface: surfaceLight,
      background: backgroundLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryLight,
      onBackground: textPrimaryLight,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Titillium',
      bodyColor: textPrimaryLight,
      displayColor: textPrimaryLight,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Titillium',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primaryDark,
      secondary: primaryDark,
      surface: surfaceDark,
      background: backgroundDark,
      onPrimary: Colors.black87,
      onSecondary: Colors.black87,
      onSurface: textPrimaryDark,
      onBackground: textPrimaryDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Titillium',
      bodyColor: textPrimaryDark,
      displayColor: textPrimaryDark,
    ),
  );
}
