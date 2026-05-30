import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';
import 'theme_extensions.dart';

ThemeData buildAppLightTheme() => _buildTheme(Brightness.light);

ThemeData buildAppDarkTheme() => _buildTheme(Brightness.dark);

/// MomLaunchpad theme — solid plum primary, light and dark variants.
ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final canvas = isDark ? AppColors.canvasDark : AppColors.canvasLight;
  final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
  final onSurface = isDark ? AppColors.inkDarkMode : AppColors.inkLightMode;
  final onSurfaceMuted =
      isDark ? AppColors.inkMutedDark : AppColors.inkMutedLight;
  final primary = isDark ? AppColors.plumLight : AppColors.plum;
  final primaryContainer =
      isDark ? AppColors.plumDark : AppColors.orchidSoft;
  final secondaryContainer =
      isDark ? AppColors.surfaceMutedDark : AppColors.roseSoft;

  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: primary,
          onPrimary: AppColors.surfaceLight,
          primaryContainer: primaryContainer,
          onPrimaryContainer: AppColors.inkDarkMode,
          secondary: AppColors.plumLight,
          onSecondary: AppColors.surfaceLight,
          secondaryContainer: secondaryContainer,
          onSecondaryContainer: AppColors.inkDarkMode,
          surface: surface,
          onSurface: onSurface,
          error: AppColors.error,
          onError: AppColors.surfaceLight,
          outline: onSurfaceMuted.withValues(alpha: 0.35),
        )
      : ColorScheme.light(
          primary: primary,
          onPrimary: AppColors.surfaceLight,
          primaryContainer: primaryContainer,
          onPrimaryContainer: AppColors.plumDark,
          secondary: AppColors.plum,
          onSecondary: AppColors.surfaceLight,
          secondaryContainer: secondaryContainer,
          onSecondaryContainer: AppColors.plumDark,
          surface: surface,
          onSurface: onSurface,
          error: AppColors.error,
          onError: AppColors.surfaceLight,
          outline: onSurfaceMuted.withValues(alpha: 0.35),
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: canvas,
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
    ).apply(bodyColor: onSurface, displayColor: onSurface),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      color: surface,
      shadowColor: AppColors.shadowTintFor(brightness),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.surfaceLight,
        elevation: 0,
        shadowColor: primary.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLG,
          vertical: AppSpacing.spaceMD,
        ),
        textStyle: AppTypography.button.copyWith(color: AppColors.surfaceLight),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        textStyle: AppTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: AppTypography.button.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        textStyle: AppTypography.button.copyWith(color: primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceLight,
      labelStyle: AppTypography.caption.copyWith(color: onSurfaceMuted),
      hintStyle: AppTypography.caption.copyWith(color: onSurfaceMuted),
      prefixIconColor: primary,
      suffixIconColor: onSurfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide(
          color: primary.withValues(alpha: isDark ? 0.25 : 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide(color: primary, width: 2),
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
      backgroundColor: canvas,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.headingSmall.copyWith(color: onSurface),
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: onSurfaceMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: AppColors.surfaceLight,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      elevation: 12,
      titleTextStyle: AppTypography.headingMedium.copyWith(color: onSurface),
      contentTextStyle: AppTypography.bodyText.copyWith(color: onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusLarge),
        ),
      ),
      elevation: 12,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? AppColors.surfaceMutedDark : AppColors.orchidSoft,
      labelStyle: AppTypography.label.copyWith(color: onSurface),
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
      color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
      thickness: 1,
      space: AppSpacing.spaceMD,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? AppColors.surfaceMutedDark : AppColors.plumDark,
      contentTextStyle: AppTypography.bodyTextMedium.copyWith(
        color: AppColors.surfaceLight,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    iconTheme: IconThemeData(color: onSurface, size: 24),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primary;
        return onSurfaceMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withValues(alpha: 0.35);
        }
        return onSurfaceMuted.withValues(alpha: 0.25);
      }),
    ),
    extensions: [
      isDark ? AppColorsExtension.dark : AppColorsExtension.light,
      AppSpacingExtension.standard,
      AppTypographyExtension.standard,
    ],
  );
}

/// Applies Google Fonts while keeping Fraunces headings.
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

/// Backwards-compatible alias.
ThemeData buildAppTheme() => buildAppLightTheme();
