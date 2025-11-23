import 'package:flutter/material.dart';

class AppTheme {
  // Color palette
  static const Color backgroundColor = Color(0xFFF6EFEA);
  static const Color primaryColor = Color(0xFFE68A6D);
  static const Color inactiveColor = Color(0xFF96A2B5);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF6B6B6B);
  
  // Cycle phase colors (from images)
  static const Color rootColor = Color(0xFFE68A6D); // Terracotta/rust
  static const Color bloomColor = Color(0xFF9DB5A0); // Sage green
  static const Color shineColor = Color(0xFFE68A6D); // Orange
  static const Color harvestColor = Color(0xFFE6B8A6); // Light pink

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        surface: backgroundColor,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
      ),
    );
  }
}

