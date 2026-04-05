import 'package:flutter/material.dart';

class AppTheme {
  // Background layers
  static const background = Color(0xFF0D0D0D);
  static const panel = Color(0xFF1A1A2E);
  static const panelRaised = Color(0xFF252540);

  // Accent colors
  static const pink = Color(0xFFFF1493);
  static const purple = Color(0xFF9C59B5);
  static const grey = Color(0xFF878787);
  static const white = Color(0xFFFFFFFF);

  // Semantic colors
  static const green = Color(0xFF00FF88);
  static const orange = Color(0xFFFF8C00);
  static const red = Color(0xFFFF4444);

  // Legacy aliases (kept for backward compatibility)
  static const accent = pink;
  static const danger = red;
  static const gold = Color(0xFFD8B26E);
  static const cyan = Color(0xFF52E3E1);
  static const lime = Color(0xFFB7F36B);

  // Radius tokens
  static const double radiusCard = 18;
  static const double radiusButton = 28;
  static const double radiusInput = 12;

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: pink,
      brightness: Brightness.dark,
    ).copyWith(
      primary: pink,
      secondary: purple,
      surface: panel,
      surfaceContainerHighest: panelRaised,
      onSurface: white,
      onPrimary: Colors.black,
      error: red,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: white,
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: pink),
        ),
        hintStyle: const TextStyle(color: grey),
        labelStyle: const TextStyle(color: grey),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
        selectedColor: pink.withValues(alpha: 0.18),
        backgroundColor: panelRaised,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: pink.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: pink);
          }
          return const IconThemeData(color: grey);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontWeight: FontWeight.w700,
              color: pink,
            );
          }
          return const TextStyle(
            fontWeight: FontWeight.w500,
            color: grey,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pink,
          side: const BorderSide(color: pink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: pink,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: white,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: white,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: grey,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: grey,
        ),
      ),
    );
  }
}
