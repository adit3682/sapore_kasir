import 'package:flutter/material.dart';

/// Palet dari Visual Brief SAPORÉ.
class SaporeColors {
  static const navyDark = Color(0xFF0F2341);
  static const navy = Color(0xFF1A365D);
  static const terracotta = Color(0xFFC26944);
  static const sage = Color(0xFF78907E);
  static const warmCream = Color(0xFFFAF7F2);
  static const cardCream = Color(0xFFFFFDFA);
  static const textDark = Color(0xFF232D37);
  static const textMuted = Color(0xFF64707D);
}

ThemeData saporeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SaporeColors.navy,
    primary: SaporeColors.navy,
    secondary: SaporeColors.terracotta,
    surface: SaporeColors.cardCream,
    error: const Color(0xFFB84A4A),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SaporeColors.warmCream,
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: SaporeColors.textDark,
          displayColor: SaporeColors.textDark,
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SaporeColors.navyDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: SaporeColors.cardCream,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SaporeColors.terracotta,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SaporeColors.cardCream,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
