import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // ---- Display ----
  static TextStyle displayLarge = GoogleFonts.poppins(
    fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle displayMedium = GoogleFonts.poppins(
    fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // ---- Headlines ----
  static TextStyle headlineLarge = GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle headlineSmall = GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );

  // ---- Titles ----
  static TextStyle titleLarge = GoogleFonts.outfit(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle titleMedium = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
  );

  // ---- Body ----
  static TextStyle bodyLarge = GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.normal, color: AppColors.textPrimary,
  );
  static TextStyle bodyMedium = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textSecondary,
  );
  static TextStyle bodySmall = GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary,
  );

  // ---- Labels ----
  static TextStyle labelLarge = GoogleFonts.outfit(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle labelMedium = GoogleFonts.outfit(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary,
  );

  // ---- Complete TextTheme ----
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      headlineLarge: headlineLarge,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
    );
  }
}