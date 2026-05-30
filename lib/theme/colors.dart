import 'package:flutter/material.dart';

/// Brand palette aligned with the MomLaunchpad logo — vibrant rose + deep plum.
class AppColors {
  // Brand (logo)
  static const Color rose = Color(0xFFE91E8C);
  static const Color roseLight = Color(0xFFFF4DA6);
  static const Color roseSoft = Color(0xFFFFE4F2);
  static const Color plum = Color(0xFF5B2D8B);
  static const Color plumDark = Color(0xFF3D1F5C);
  static const Color orchid = Color(0xFF9333EA);
  static const Color orchidSoft = Color(0xFFF3E8FF);

  // Surfaces
  static const Color canvas = Color(0xFFFDF8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF8F0FA);

  // Text
  static const Color ink = Color(0xFF2A1538);
  static const Color inkMuted = Color(0xFF6E5A7A);
  static const Color inkLight = Color(0xFF9B8AA8);

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

  // Glass
  static Color glassWhite = Colors.white.withValues(alpha: 0.82);
  static Color glassBorder = Colors.white.withValues(alpha: 0.65);
  static final Color shadowTint = plum.withValues(alpha: 0.12);
  static final Color shadowDark = plum.withValues(alpha: 0.18);
  static final Color shadowLight = Colors.white;

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [roseLight, rose, plum],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradientVertical = LinearGradient(
    colors: [rose, plum],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient softGlow = LinearGradient(
    colors: [Color(0xFFFFF0F7), Color(0xFFF5EEFF), canvas],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient heroOrbPink = RadialGradient(
    colors: [Color(0x40FF4DA6), Color(0x00FF4DA6)],
    radius: 0.85,
  );

  static const RadialGradient heroOrbPurple = RadialGradient(
    colors: [Color(0x359333EA), Color(0x009333EA)],
    radius: 0.85,
  );

  // Legacy aliases (keep screens compiling during migration)
  static const Color creamBackground = canvas;
  static const Color blushPrimary = roseSoft;
  static const Color peachAccent = Color(0xFFFFB088);
  static const Color mintSuccess = successSoft;
  static const Color lavenderSecondary = orchidSoft;
  static const Color textDark = ink;
  static const Color textMedium = inkMuted;
  static const Color textLight = inkLight;
  static const Color primaryPink = rose;
  static const Color primaryPurple = plum;
  static const Color backgroundLight = canvas;
  static const Color white = surface;
  static const LinearGradient blushGradient = brandGradient;
  static const LinearGradient peachGradient = softGlow;
}
