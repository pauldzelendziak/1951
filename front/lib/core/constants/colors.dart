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
  static const Color homeGradientStart = Color(0xFFFFF176);

  /// Gradient end color for the home screen background.
  static const Color homeGradientEnd = Color(0xFF040404);

  /// Semi-transparent background used for icon containers.
  static const Color iconBackground = Color(0x33FFFFFF);
}
