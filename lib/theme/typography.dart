import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography system - Serene, clean, sans-serif
class AppTypography {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32, // Larger header
    fontWeight: FontWeight.w300, // Light weight
    color: AppColors.textDark,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400, // Regular weight
    color: AppColors.textDark,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w300, // Light weight for airy feel
    color: AppColors.textDark,
    height: 1.6, // Generous line height
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: AppColors.textMedium,
    height: 1.5,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Helper methods for color variants
  static TextStyle headingLargeLight() => headingLarge.copyWith(color: AppColors.white);
  static TextStyle bodyTextLight() => bodyText.copyWith(color: AppColors.white);
  static TextStyle captionDark() => caption.copyWith(color: AppColors.textDark);
}
