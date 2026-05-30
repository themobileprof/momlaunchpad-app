import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';
import 'theme_extensions.dart';

/// MomLaunchpad theme — vibrant rose & plum, logo-aligned.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.light(
    primary: AppColors.rose,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.roseSoft,
    onPrimaryContainer: AppColors.plum,
    secondary: AppColors.plum,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.orchidSoft,
    onSecondaryContainer: AppColors.plumDark,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.error,
    onError: AppColors.white,
    outline: AppColors.inkLight.withValues(alpha: 0.35),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: TextTheme(
      displayLarge: AppTypography.headingLarge,
      displayMedium: AppTypography.headingMedium,
      displaySmall: AppTypography.headingSmall,
      headlineMedium: AppTypography.headingMedium,
      titleLarge: AppTypography.headingSmall,
      bodyLarge: AppTypography.bodyText,
      bodyMedium: AppTypography.bodyTextMedium,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.button,
      labelSmall: AppTypography.label,
    ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      color: AppColors.surface,
      shadowColor: AppColors.shadowTint,
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.rose,
        foregroundColor: AppColors.white,
        elevation: 0,
        shadowColor: AppColors.rose.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLG,
          vertical: AppSpacing.spaceMD,
        ),
        textStyle: AppTypography.button.copyWith(color: AppColors.white),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.plum,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        textStyle: AppTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.plum,
        textStyle: AppTypography.button.copyWith(
          color: AppColors.plum,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.plum,
        side: const BorderSide(color: AppColors.plum, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        textStyle: AppTypography.button.copyWith(color: AppColors.plum),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: AppTypography.caption.copyWith(color: AppColors.inkMuted),
      hintStyle: AppTypography.caption,
      prefixIconColor: AppColors.plum,
      suffixIconColor: AppColors.inkMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide(
          color: AppColors.plum.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: const BorderSide(color: AppColors.rose, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMD,
        vertical: AppSpacing.spaceMD,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.canvas,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headingSmall,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.rose,
      unselectedItemColor: AppColors.inkLight,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.label.copyWith(color: AppColors.rose),
      unselectedLabelStyle: AppTypography.label,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.rose,
      foregroundColor: AppColors.white,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      elevation: 12,
      titleTextStyle: AppTypography.headingMedium,
      contentTextStyle: AppTypography.bodyText,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusLarge),
        ),
      ),
      elevation: 12,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.orchidSoft,
      labelStyle: AppTypography.label.copyWith(color: AppColors.plum),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMD,
        vertical: AppSpacing.spaceSM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.plum.withValues(alpha: 0.08),
      thickness: 1,
      space: AppSpacing.spaceMD,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.plumDark,
      contentTextStyle: AppTypography.bodyTextMedium.copyWith(
        color: AppColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.rose,
    ),
    iconTheme: const IconThemeData(
      color: AppColors.ink,
      size: 24,
    ),
    extensions: [
      AppColorsExtension.light,
      AppSpacingExtension.standard,
      AppTypographyExtension.standard,
    ],
  );
}

/// Applies Google Fonts as the default font family for the app.
ThemeData applyGoogleFonts(ThemeData theme) {
  return theme.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(theme.textTheme).copyWith(
      displayLarge: AppTypography.headingLarge,
      displayMedium: AppTypography.headingMedium,
      displaySmall: AppTypography.headingSmall,
      headlineMedium: AppTypography.headingMedium,
      titleLarge: AppTypography.headingSmall,
    ),
  );
}
