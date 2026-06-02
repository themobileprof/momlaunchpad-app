import 'package:flutter/material.dart';

/// Brand palette — soft teals with mint green accents.
class AppColors {
  // Teal (primary actions, navigation, links)
  static const Color teal = Color(0xFF0F766E);
  static const Color tealDark = Color(0xFF115E59);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealSoft = Color(0xFFCCFBF1);

  // Mint (accent highlights, secondary emphasis)
  static const Color mint = Color(0xFF34D399);
  static const Color mintDark = Color(0xFF059669);
  static const Color mintLight = Color(0xFF6EE7B7);
  static const Color mintSoft = Color(0xFFD1FAE5);

  /// Primary action / selected state — solid teal.
  static const Color brandPrimary = teal;

  // Light surfaces
  static const Color canvasLight = Color(0xFFF0FDFA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFECFDF5);

  // Dark surfaces
  static const Color canvasDark = Color(0xFF0A1211);
  static const Color surfaceDark = Color(0xFF12201E);
  static const Color surfaceMutedDark = Color(0xFF1A2E2B);

  // Light text
  static const Color inkLightMode = Color(0xFF134E4A);
  static const Color inkMutedLight = Color(0xFF52706B);
  static const Color inkSubtleLight = Color(0xFF6B8A85);

  // Dark text
  static const Color inkDarkMode = Color(0xFFECFDF5);
  static const Color inkMutedDark = Color(0xFF99C9BF);
  static const Color inkSubtleDark = Color(0xFF6B9A90);

  // Semantic
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0891B2);
  static const Color infoSoft = Color(0xFFCFFAFE);

  // Priority
  static const Color priorityUrgent = Color(0xFFEF4444);
  static const Color priorityHigh = Color(0xFFF97316);
  static const Color priorityMedium = Color(0xFF14B8A6);
  static const Color priorityLow = Color(0xFFE5E7EB);

  // Legacy aliases (map old plum/rose names to teal/mint for gradual migration)
  static const Color plum = teal;
  static const Color plumDark = tealDark;
  static const Color plumLight = tealLight;
  static const Color rose = mint;
  static const Color roseSoft = mintSoft;
  static const Color orchid = tealLight;
  static const Color orchidSoft = tealSoft;
  static const Color canvas = canvasLight;
  static const Color surface = surfaceLight;
  static const Color surfaceMuted = surfaceMutedLight;
  static const Color ink = inkLightMode;
  static const Color inkMuted = inkMutedLight;
  static const Color inkLight = inkSubtleLight;
  static const Color creamBackground = canvasLight;
  static const Color blushPrimary = mintSoft;
  static const Color peachAccent = Color(0xFF5EEAD4);
  static const Color mintSuccess = successSoft;
  static const Color lavenderSecondary = tealSoft;
  static const Color textDark = inkLightMode;
  static const Color textMedium = inkMutedLight;
  static const Color textLight = inkSubtleLight;
  static const Color primaryPink = mint;
  static const Color primaryPurple = teal;
  static const Color backgroundLight = canvasLight;
  static const Color white = surfaceLight;
  static const Color roseLight = mintLight;

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
          : teal.withValues(alpha: 0.12);

  static final Color shadowTint = teal.withValues(alpha: 0.12);
  static final Color shadowDark = tealDark.withValues(alpha: 0.18);
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

  /// Mint accent — highlights and secondary emphasis.
  Color get appAccent => AppColors.mint;
}
