import 'package:flutter/material.dart';

class PawlyColors {
  const PawlyColors._();

  static const teal = Color(0xFF167C80);
  static const darkTeal = Color(0xFF0E555B);
  static const orange = Color(0xFFF28C28);
  static const cream = Color(0xFFFFF8EF);
  static const mist = Color(0xFFF2F8F6);
  static const ink = Color(0xFF1D2939);
}

ThemeData pawlyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: PawlyColors.teal,
    brightness: Brightness.light,
    primary: PawlyColors.teal,
    secondary: PawlyColors.orange,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PawlyColors.mist,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: PawlyColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0x14000000)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0x14000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: PawlyColors.teal, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PawlyColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.1,
      ),
      titleLarge: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -.5,
      ),
      titleMedium: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(color: Color(0xFF667085)),
    ),
  );
}
