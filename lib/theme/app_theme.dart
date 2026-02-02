import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color _primaryProphet = Color(0xFF00BCD4); // Cyan/Teal
  static const Color _secondaryProphet = Color(0xFF26C6DA);
  static const Color _tertiaryProphet = Color(0xFF4DD0E1);

  // Dark Scheme Colors
  static const Color _darkBackground = Color(0xFF0F172A); // Slate 900 (Dark Blue-Grey)
  static const Color _darkSurface = Color(0xFF1E293B); // Slate 800 (Lighter Blue-Grey for Cards)
  static const Color _darkSurfaceHighlight = Color(0xFF334155); // Slate 700
  static const Color _darkOnSurface = Color(0xFFE2E8F0); // Slate 200
  static const Color _darkOnSurfaceVariant = Color(0xFF94A3B8); // Slate 400

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryProphet,
        brightness: Brightness.light,
        primary: _primaryProphet,
        surface: Colors.grey[50]!,
        onSurface: Colors.black87,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        color: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryProphet,
        onPrimary: Colors.black,
        secondary: _secondaryProphet,
        onSecondary: Colors.black,
        tertiary: _tertiaryProphet,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceContainerHighest: _darkSurfaceHighlight,
        outline: _darkOnSurfaceVariant,
        outlineVariant: _darkOnSurfaceVariant.withValues(alpha: 0.5),
        error: const Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: _darkOnSurface),
        titleTextStyle: TextStyle(
          color: _darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        color: _darkSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceHighlight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryProphet),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: _darkOnSurface,
        displayColor: _darkOnSurface,
      ),
      iconTheme: const IconThemeData(
        color: _primaryProphet,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primaryProphet,
        foregroundColor: Colors.black,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkBackground,
        indicatorColor: Colors.transparent, // Remove the pill
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64, // Slightly shorter for a sleeker look
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _primaryProphet, size: 26);
          }
          return const IconThemeData(color: _darkOnSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: _primaryProphet, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: _darkOnSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500);
        }),
      ),
    );
  }
}
