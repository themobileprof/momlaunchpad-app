import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Card variants for different use cases
enum AppCardVariant { elevated, flat, outlined }

/// Reusable card with consistent styling
class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.radiusLarge;
    
    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: variant == AppCardVariant.outlined
            ? Border.all(color: AppColors.textLight.withOpacity(0.2))
            : null,
        boxShadow: variant == AppCardVariant.elevated
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      );
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

/// List tile card - for settings, menus, etc.
class AppListTileCard extends StatelessWidget {
  final IconData? leadingIcon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final EdgeInsetsGeometry? margin;

  const AppListTileCard({
    super.key,
    this.leadingIcon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.spaceSM),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: leading ?? (leadingIcon != null
            ? Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryPurple).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
                ),
                child: Icon(
                  leadingIcon,
                  color: iconColor ?? AppColors.primaryPurple,
                  size: 20,
                ),
              )
            : null),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: trailing ?? (onTap != null
            ? const Icon(Icons.chevron_right, color: AppColors.textLight)
            : null),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceMD,
          vertical: AppSpacing.spaceSM,
        ),
      ),
    );
  }
}
