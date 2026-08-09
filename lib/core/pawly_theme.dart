import 'package:flutter/material.dart';

/// The Pawly palette is deliberately calm and practical: teal signals care and
/// trust, warm apricot is reserved for attention, and surfaces remain light so
/// booking details are easy to scan on a phone.
class PawlyColors {
  const PawlyColors._();

  static const teal = Color(0xFF137C78);
  static const darkTeal = Color(0xFF0B4F4D);
  static const tealSoft = Color(0xFFDFF2EE);
  static const apricot = Color(0xFFE9814E);
  static const apricotSoft = Color(0xFFFFECE3);
  // Compatibility aliases for the lightweight configuration screen and any
  // older, non-active screens kept in the project during the Phase 1 rebuild.
  static const orange = apricot;
  static const cream = apricotSoft;
  static const mist = Color(0xFFF6FAF9);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF163536);
  static const muted = Color(0xFF637477);
  static const line = Color(0xFFD8E5E2);
  static const success = Color(0xFF16794A);
  static const danger = Color(0xFFB42318);
}

class PawlySpacing {
  const PawlySpacing._();
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

ThemeData pawlyTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: PawlyColors.teal,
    brightness: Brightness.light,
    primary: PawlyColors.teal,
    secondary: PawlyColors.apricot,
    surface: PawlyColors.surface,
    error: PawlyColors.danger,
  );

  final rounded16 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PawlyColors.mist,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: PawlyColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: PawlyColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded16,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(color: PawlyColors.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PawlyColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: PawlyColors.muted),
      hintStyle: const TextStyle(color: Color(0xFF8A999A)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PawlyColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PawlyColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PawlyColors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PawlyColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: PawlyColors.danger, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PawlyColors.teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: PawlyColors.teal.withValues(alpha: .42),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: rounded16,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PawlyColors.darkTeal,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: PawlyColors.line),
        shape: rounded16,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PawlyColors.teal,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: PawlyColors.surface,
      selectedColor: PawlyColors.tealSoft,
      side: const BorderSide(color: PawlyColors.line),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: PawlyColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: PawlyColors.surface,
      indicatorColor: PawlyColors.tealSoft,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? PawlyColors.darkTeal
              : PawlyColors.muted,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? PawlyColors.darkTeal
              : PawlyColors.muted,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: PawlyColors.surface,
      selectedIconTheme: IconThemeData(color: PawlyColors.darkTeal),
      unselectedIconTheme: IconThemeData(color: PawlyColors.muted),
      selectedLabelTextStyle: TextStyle(
        color: PawlyColors.darkTeal,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: PawlyColors.muted,
        fontWeight: FontWeight.w600,
      ),
      indicatorColor: PawlyColors.tealSoft,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PawlyColors.surface,
      modalBackgroundColor: PawlyColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineMedium: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -.75,
      ),
      titleLarge: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -.3,
      ),
      titleMedium: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: TextStyle(color: PawlyColors.ink, height: 1.45),
      bodyMedium: TextStyle(color: PawlyColors.muted, height: 1.42),
      labelLarge: TextStyle(
        color: PawlyColors.ink,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
