import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';
import 'theme_extensions.dart';

/// Main app theme using Material 3
/// Follows design guide principles: soft colors, rounded corners, generous spacing
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    
    // Color scheme from logo
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryPink,
      primary: AppColors.primaryPink,
      secondary: AppColors.primaryPurple,
      surface: AppColors.white,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.textDark,
      error: AppColors.error,
    ),
    
    // Background color
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    // Card theme - elevated with shadows, not borders
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      color: AppColors.white,
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPink,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLG,
          vertical: AppSpacing.spaceMD,
        ),
        textStyle: AppTypography.button,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceMD,
          vertical: AppSpacing.spaceSM,
        ),
        textStyle: AppTypography.button,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryPurple,
        side: BorderSide(color: AppColors.primaryPurple, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLG,
          vertical: AppSpacing.spaceMD,
        ),
        textStyle: AppTypography.button,
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide(color: AppColors.textLight.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide(color: AppColors.primaryPink, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.all(AppSpacing.spaceMD),
      hintStyle: AppTypography.caption,
    ),
    
    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.headingMedium,
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primaryPink,
      unselectedItemColor: AppColors.textLight,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTypography.caption,
    ),
    
    // Floating action button theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryPink,
      foregroundColor: AppColors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    
    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      elevation: 8,
      titleTextStyle: AppTypography.headingMedium,
      contentTextStyle: AppTypography.bodyText,
    ),
    
    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusLarge),
        ),
      ),
      elevation: 8,
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
      labelStyle: AppTypography.caption.copyWith(color: AppColors.primaryPurple),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMD,
        vertical: AppSpacing.spaceSM,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
    ),
    
    // Divider theme (use sparingly - prefer spacing)
    dividerTheme: DividerThemeData(
      color: AppColors.textLight.withOpacity(0.1),
      thickness: 1,
      space: AppSpacing.spaceMD,
    ),
    
    // Typography
    textTheme: TextTheme(
      displayLarge: AppTypography.headingLarge,
      displayMedium: AppTypography.headingMedium,
      bodyLarge: AppTypography.bodyText,
      bodyMedium: AppTypography.bodyText,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.button,
    ),
    
    // Icon theme
    iconTheme: IconThemeData(
      color: AppColors.textDark,
      size: 24,
    ),
    
    // Theme extensions for easy access
    extensions: const [
      AppColorsExtension.light,
      AppSpacingExtension.standard,
      AppTypographyExtension.standard,
    ],
  );
}
