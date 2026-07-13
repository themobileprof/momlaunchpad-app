import 'package:flutter/material.dart';
import '../models/baby_gender.dart';
import '../theme/colors.dart';

/// Accent palette driven by baby gender (matches web `data-baby-theme`).
class BabyThemePalette {
  final Color accent;
  final Color accentDeep;
  final Color accentLight;
  final Color accentSoft;
  final Color canvas;
  final Color surfaceMuted;

  const BabyThemePalette({
    required this.accent,
    required this.accentDeep,
    required this.accentLight,
    required this.accentSoft,
    required this.canvas,
    required this.surfaceMuted,
  });
}

BabyThemePalette? babyThemePaletteFor(BabyGender? gender) {
  switch (gender) {
    case BabyGender.girl:
      return const BabyThemePalette(
        accent: Color(0xFFDB2777),
        accentDeep: Color(0xFF9D174D),
        accentLight: Color(0xFFF9A8D4),
        accentSoft: Color(0xFFFCE7F3),
        canvas: Color(0xFFFFF5F9),
        surfaceMuted: Color(0xFFFFF0F6),
      );
    case BabyGender.boy:
      return const BabyThemePalette(
        accent: Color(0xFF4F6FD8),
        accentDeep: Color(0xFF2C4A9E),
        accentLight: Color(0xFF93C5FD),
        accentSoft: Color(0xFFE0F2FE),
        canvas: Color(0xFFF4F8FF),
        surfaceMuted: Color(0xFFEEF4FF),
      );
    case BabyGender.unknown:
      return const BabyThemePalette(
        accent: Color(0xFF9333EA),
        accentDeep: Color(0xFF6B21A8),
        accentLight: Color(0xFFFBBF24),
        accentSoft: Color(0xFFF3E8FF),
        canvas: Color(0xFFFAF7FF),
        surfaceMuted: Color(0xFFF5F0FF),
      );
    case null:
      return null;
  }
}

String babyThemeLabel(BabyGender? gender) {
  switch (gender) {
    case BabyGender.girl:
      return 'Girl';
    case BabyGender.boy:
      return 'Boy';
    case BabyGender.unknown:
      return 'Surprise';
    case null:
      return 'Your journey';
  }
}

/// Default brand palette when no baby gender is set.
BabyThemePalette get defaultBrandPalette => const BabyThemePalette(
      accent: AppColors.tealLight,
      accentDeep: AppColors.teal,
      accentLight: AppColors.mintLight,
      accentSoft: AppColors.tealSoft,
      canvas: AppColors.canvasLight,
      surfaceMuted: AppColors.surfaceMutedLight,
    );
