import 'package:flutter/material.dart';

class AppColors {
  // ---- Brand (Clean Light Pink-Orange Gradient) ----
  static const Color primary = Color(0xFFFF2A6D);       // Vibrant Coral Pink
  static const Color primaryLight = Color(0xFFFF5E36);  // Vibrant Sunset Orange
  static const Color accent = Color(0xFFFF2A6D);        // Active Line / Focus

  // ---- Signature Gradient ----
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF2A6D), Color(0xFFFF5E36)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ---- Neutrals (Clean Light Mode) ----
  static const Color background = Color(0xFFFFFFFF);    // Clean Pure White
  static const Color surface = Color(0xFFF9FAFB);       // Soft Light Surface
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Soft Grey Input / Card Fill
  static const Color textPrimary = Color(0xFF111827);   // Deep Charcoal Black
  static const Color textSecondary = Color(0xFF6B7280); // Muted Grey
  static const Color textTertiary = Color(0xFF9CA3AF);  // Darker Muted Grey
  static const Color border = Color(0xFFE5E7EB);        // Subtle Light Border
  static const Color activeLine = Color(0xFFFF2A6D);    // Underline Highlight
  static const Color divider = Color(0xFFF3F4F6);       // Light Divider

  // ---- Semantic ----
  static const Color onPrimary = Color(0xFFFFFFFF);     // White text on primary button
  static const Color success = Color(0xFF22C55E);       // Fresh Green
  static const Color error = Color(0xFFEF4444);         // Vibrant Red

  // ---- Icons ----
  static const Color iconPrimary = Color(0xFF111827);
  static const Color iconSecondary = Color(0xFF6B7280);

  // ---- Claymorphism shadows ----
  static const Color shadow = Color(0x1A000000);

  // ---- Material 3 ColorScheme ----
  static ColorScheme get lightScheme {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primaryLight,
      onSecondary: Colors.white,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: textSecondary,
      outline: border,
      shadow: shadow,
    );
  }
}