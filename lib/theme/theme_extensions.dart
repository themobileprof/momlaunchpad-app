import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Theme extensions for easier access to app theme properties
/// Usage: context.colors.primaryPink, context.spacing.md, etc.

extension ThemeExtensions on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
  AppSpacingExtension get spacing => Theme.of(this).extension<AppSpacingExtension>()!;
  AppTypographyExtension get typography => Theme.of(this).extension<AppTypographyExtension>()!;
}

/// Colors extension for ThemeData
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primaryPink;
  final Color primaryPurple;
  final Color backgroundLight;
  final Color textDark;
  final Color textLight;
  final Color white;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const AppColorsExtension({
    required this.primaryPink,
    required this.primaryPurple,
    required this.backgroundLight,
    required this.textDark,
    required this.textLight,
    required this.white,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  static const light = AppColorsExtension(
    primaryPink: AppColors.primaryPink,
    primaryPurple: AppColors.primaryPurple,
    backgroundLight: AppColors.backgroundLight,
    textDark: AppColors.textDark,
    textLight: AppColors.textLight,
    white: AppColors.white,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
  );

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primaryPink,
    Color? primaryPurple,
    Color? backgroundLight,
    Color? textDark,
    Color? textLight,
    Color? white,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
  }) {
    return AppColorsExtension(
      primaryPink: primaryPink ?? this.primaryPink,
      primaryPurple: primaryPurple ?? this.primaryPurple,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      textDark: textDark ?? this.textDark,
      textLight: textLight ?? this.textLight,
      white: white ?? this.white,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      primaryPink: Color.lerp(primaryPink, other.primaryPink, t)!,
      primaryPurple: Color.lerp(primaryPurple, other.primaryPurple, t)!,
      backgroundLight: Color.lerp(backgroundLight, other.backgroundLight, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      white: Color.lerp(white, other.white, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Spacing extension for ThemeData
class AppSpacingExtension extends ThemeExtension<AppSpacingExtension> {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  
  final double radiusSmall;
  final double radiusMedium;
  final double radiusLarge;

  const AppSpacingExtension({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.radiusSmall,
    required this.radiusMedium,
    required this.radiusLarge,
  });

  static const standard = AppSpacingExtension(
    xs: AppSpacing.spaceXS,
    sm: AppSpacing.spaceSM,
    md: AppSpacing.spaceMD,
    lg: AppSpacing.spaceLG,
    xl: AppSpacing.spaceXL,
    xxl: AppSpacing.spaceXXL,
    radiusSmall: AppRadius.radiusSmall,
    radiusMedium: AppRadius.radiusMedium,
    radiusLarge: AppRadius.radiusLarge,
  );

  @override
  ThemeExtension<AppSpacingExtension> copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
  }) {
    return AppSpacingExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
    );
  }

  @override
  ThemeExtension<AppSpacingExtension> lerp(
    covariant ThemeExtension<AppSpacingExtension>? other,
    double t,
  ) {
    if (other is! AppSpacingExtension) return this;
    return AppSpacingExtension(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
      xxl: lerpDouble(xxl, other.xxl, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      radiusMedium: lerpDouble(radiusMedium, other.radiusMedium, t)!,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t)!,
    );
  }
}

double? lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}

/// Typography extension for ThemeData
class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  final TextStyle headingLarge;
  final TextStyle headingMedium;
  final TextStyle bodyText;
  final TextStyle caption;
  final TextStyle button;

  const AppTypographyExtension({
    required this.headingLarge,
    required this.headingMedium,
    required this.bodyText,
    required this.caption,
    required this.button,
  });

  static AppTypographyExtension get standard => AppTypographyExtension(
        headingLarge: AppTypography.headingLarge,
        headingMedium: AppTypography.headingMedium,
        bodyText: AppTypography.bodyText,
        caption: AppTypography.caption,
        button: AppTypography.button,
      );

  @override
  ThemeExtension<AppTypographyExtension> copyWith({
    TextStyle? headingLarge,
    TextStyle? headingMedium,
    TextStyle? bodyText,
    TextStyle? caption,
    TextStyle? button,
  }) {
    return AppTypographyExtension(
      headingLarge: headingLarge ?? this.headingLarge,
      headingMedium: headingMedium ?? this.headingMedium,
      bodyText: bodyText ?? this.bodyText,
      caption: caption ?? this.caption,
      button: button ?? this.button,
    );
  }

  @override
  ThemeExtension<AppTypographyExtension> lerp(
    covariant ThemeExtension<AppTypographyExtension>? other,
    double t,
  ) {
    if (other is! AppTypographyExtension) return this;
    return AppTypographyExtension(
      headingLarge: TextStyle.lerp(headingLarge, other.headingLarge, t)!,
      headingMedium: TextStyle.lerp(headingMedium, other.headingMedium, t)!,
      bodyText: TextStyle.lerp(bodyText, other.bodyText, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
    );
  }
}
