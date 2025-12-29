import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography system - 2-3 font sizes maximum for visual hierarchy
class AppTypography {
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
    height: 1.4,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    height: 1.5,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // Helper methods for color variants
  static TextStyle headingLargeLight() => headingLarge.copyWith(color: AppColors.white);
  static TextStyle bodyTextLight() => bodyText.copyWith(color: AppColors.white);
  static TextStyle captionDark() => caption.copyWith(color: AppColors.textDark);
}
