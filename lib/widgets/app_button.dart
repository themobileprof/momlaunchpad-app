import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Button variants for consistent styling
enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// Button sizes
enum AppButtonSize { small, medium, large }

/// Reusable app button with consistent styling
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _height,
      child: _buildButton(),
    );
  }

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 40;
      case AppButtonSize.medium:
        return 52;
      case AppButtonSize.large:
        return 60;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD, vertical: AppSpacing.spaceSM);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLG, vertical: AppSpacing.spaceMD);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.spaceXL, vertical: AppSpacing.spaceMD);
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }

  Widget _buildButton() {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _fontSize + 4),
                const SizedBox(width: AppSpacing.spaceSM),
              ],
              Text(
                label,
                style: AppTypography.button.copyWith(fontSize: _fontSize),
              ),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: AppColors.white,
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            elevation: 0,
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: AppColors.white,
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            elevation: 0,
          ),
          child: child,
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryPurple,
            padding: _padding,
            side: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryPurple,
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            padding: _padding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            elevation: 0,
          ),
          child: child,
        );
    }
  }

  Color get _foregroundColor {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
        return AppColors.white;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return AppColors.primaryPurple;
    }
  }
}

/// Icon button with consistent styling
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? AppColors.textDark),
        onPressed: onPressed,
        iconSize: size * 0.5,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
