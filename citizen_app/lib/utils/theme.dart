import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2ECC71);
  static const Color primaryDark = Color(0xFF27AE60);
  static const Color secondaryColor = Color(0xFF3498DB);
  static const Color dangerColor = Color(0xFFE74C3C);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color darkColor = Color(0xFF2C3E50);
  static const Color lightColor = Color(0xFFECF0F1);
  static const Color grayColor = Color(0xFF95A5A6);
  static const Color successColor = Color(0xFF2ECC71);
  static const Color infoColor = Color(0xFF3498DB);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF666666)),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: primaryColor,
      selectionColor: Color(0x4D2ECC71),
      selectionHandleColor: primaryColor,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );

  // Status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warningColor;
      case 'assigned':
        return secondaryColor;
      case 'in_progress':
        return const Color(0xFF9B59B6);
      case 'completed':
        return primaryColor;
      case 'rejected':
        return dangerColor;
      default:
        return grayColor;
    }
  }

  // Waste type colors
  static Color getWasteTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'organic':
        return primaryColor;
      case 'recyclable':
        return secondaryColor;
      case 'hazardous':
        return dangerColor;
      case 'electronic':
        return warningColor;
      case 'mixed':
        return grayColor;
      default:
        return grayColor;
    }
  }
}
