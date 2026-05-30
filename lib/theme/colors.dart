import 'package:flutter/material.dart';

/// Brand palette — plum primary with rose accent (solid, no gradients).
class AppColors {
  // Brand
  static const Color rose = Color(0xFFE91E8C);
  static const Color roseSoft = Color(0xFFFFE4F2);
  static const Color plum = Color(0xFF5B2D8B);
  static const Color plumDark = Color(0xFF3D1F5C);
  static const Color plumLight = Color(0xFF7B4BA8);
  static const Color orchid = Color(0xFF9333EA);
  static const Color orchidSoft = Color(0xFFF3E8FF);

  /// Primary action / selected state — solid plum.
  static const Color brandPrimary = plum;

  // Light surfaces
  static const Color canvasLight = Color(0xFFFDF8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF8F0FA);

  // Dark surfaces
  static const Color canvasDark = Color(0xFF121018);
  static const Color surfaceDark = Color(0xFF1E1628);
  static const Color surfaceMutedDark = Color(0xFF2A2235);

  // Light text
  static const Color inkLightMode = Color(0xFF2A1538);
  static const Color inkMutedLight = Color(0xFF6E5A7A);
  static const Color inkSubtleLight = Color(0xFF9B8AA8);

  // Dark text
  static const Color inkDarkMode = Color(0xFFF5F0F8);
  static const Color inkMutedDark = Color(0xFFB8A8C4);
  static const Color inkSubtleDark = Color(0xFF8A7A96);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFDBEAFE);

  // Priority
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityMedium = Color(0xFF9333EA);
  static const Color priorityLow = Color(0xFFE5E7EB);

  // Legacy aliases (static light values — prefer context helpers in widgets)
  static const Color canvas = canvasLight;
  static const Color surface = surfaceLight;
  static const Color surfaceMuted = surfaceMutedLight;
  static const Color ink = inkLightMode;
  static const Color inkMuted = inkMutedLight;
  static const Color inkLight = inkSubtleLight;
  static const Color creamBackground = canvasLight;
  static const Color blushPrimary = roseSoft;
  static const Color peachAccent = Color(0xFFFFB088);
  static const Color mintSuccess = successSoft;
  static const Color lavenderSecondary = orchidSoft;
  static const Color textDark = inkLightMode;
  static const Color textMedium = inkMutedLight;
  static const Color textLight = inkSubtleLight;
  static const Color primaryPink = rose;
  static const Color primaryPurple = plum;
  static const Color backgroundLight = canvasLight;
  static const Color white = surfaceLight;
  static const Color roseLight = Color(0xFFFF4DA6);

  static Color glassFill(Brightness brightness) =>
      brightness == Brightness.dark
          ? surfaceDark.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.82);

  static Color glassBorderColor(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.white.withValues(alpha: 0.65);

  static Color shadowTintFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.35)
          : plum.withValues(alpha: 0.12);

  static final Color shadowTint = plum.withValues(alpha: 0.12);
  static final Color shadowDark = plum.withValues(alpha: 0.18);
  static const Color shadowLight = Colors.white;
  static Color glassWhite = Colors.white.withValues(alpha: 0.82);
  static Color glassBorder = Colors.white.withValues(alpha: 0.65);
}

/// Theme-aware color access for widgets.
extension AppColorContext on BuildContext {
  Brightness get appBrightness => Theme.of(this).brightness;

  bool get isDarkMode => appBrightness == Brightness.dark;

  Color get appCanvas => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurface => Theme.of(this).colorScheme.surface;

  Color get appSurfaceMuted =>
      isDarkMode ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight;

  Color get appInk => Theme.of(this).colorScheme.onSurface;

  Color get appInkMuted => isDarkMode
      ? AppColors.inkMutedDark
      : AppColors.inkMutedLight;

  Color get appInkSubtle => isDarkMode
      ? AppColors.inkSubtleDark
      : AppColors.inkSubtleLight;

  Color get appPrimary => Theme.of(this).colorScheme.primary;

  Color get appOnPrimary => Theme.of(this).colorScheme.onPrimary;

  Color get appSecondary => Theme.of(this).colorScheme.secondary;
}
