import 'package:flutter/material.dart';

/// Centralizes the color palette for consistent styling across the app.
abstract class AppColors {
  /// Primary accent color used for buttons and highlights.
  static const Color primary = Color(0xFFFFC400);

  /// Secondary accent color for UI accents.
  static const Color accent = Color(0xFFFF7043);

  /// Dark color used for text/icons on light backgrounds.
  static const Color dark = Color(0xFF080808);

  /// Surface background color for cards and surfaces.
  static const Color surface = Color(0xFF1F1F1F);

  /// Primary text color used across the UI.
  static const Color textPrimary = Colors.white;

  /// Gradient start color for the home screen background.
  static const Color homeGradientStart = Color.fromARGB(255, 80, 59, 13);

  /// Gradient end color for the home screen background.
  static const Color homeGradientEnd = Color.fromARGB(255, 236, 95, 0);

  /// Semi-transparent background used for icon containers.
  static const Color iconBackground = Color(0x33FFFFFF);

  /// Gradient start color for boss encounters.
  static const Color bossGradientStart = Color(0xFF8B0000);

  /// Gradient end color for boss encounters.
  static const Color bossGradientEnd = Color(0xFF000000);

  /// Background color for dialog surfaces.
  static const Color dialogBackground = Color(0xFF1A1C24);
}
