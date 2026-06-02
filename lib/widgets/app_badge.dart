import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Badge variants
enum AppBadgeVariant { primary, secondary, success, warning, error, info }

/// Reusable badge/chip widget
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;
  final bool small;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.primary,
    this.icon,
    this.small = false,
  });

  Color _backgroundColor(BuildContext context) {
    switch (variant) {
      case AppBadgeVariant.primary:
        return context.appAccent.withValues(alpha: 0.15);
      case AppBadgeVariant.secondary:
        return context.appPrimary.withValues(alpha: 0.15);
      case AppBadgeVariant.success:
        return AppColors.success.withValues(alpha: 0.15);
      case AppBadgeVariant.warning:
        return AppColors.warning.withValues(alpha: 0.15);
      case AppBadgeVariant.error:
        return AppColors.error.withValues(alpha: 0.15);
      case AppBadgeVariant.info:
        return AppColors.info.withValues(alpha: 0.15);
    }
  }

  Color _textColor(BuildContext context) {
    switch (variant) {
      case AppBadgeVariant.primary:
        return context.appAccent;
      case AppBadgeVariant.secondary:
        return context.appPrimary;
      case AppBadgeVariant.success:
        return AppColors.success;
      case AppBadgeVariant.warning:
        return AppColors.warning;
      case AppBadgeVariant.error:
        return AppColors.error;
      case AppBadgeVariant.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpacing.spaceSM : AppSpacing.spaceMD,
        vertical: small ? AppSpacing.spaceXS : AppSpacing.spaceSM,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(AppRadius.radiusCircle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: small ? 12 : 14,
              color: _textColor(context),
            ),
            const SizedBox(width: AppSpacing.spaceXS),
          ],
          Text(
            label,
            style: (small ? AppTypography.caption : AppTypography.bodyText).copyWith(
              color: _textColor(context),
              fontWeight: FontWeight.w600,
              fontSize: small ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status indicator dot
class StatusDot extends StatelessWidget {
  final bool isActive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool pulse;

  const StatusDot({
    super.key,
    required this.isActive,
    this.size = 8,
    this.activeColor,
    this.inactiveColor,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? AppColors.success)
        : (inactiveColor ?? context.appInkSubtle);

    if (pulse && isActive) {
      return _PulsingDot(size: size, color: color);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final double size;
  final Color color;

  const _PulsingDot({required this.size, required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 4 * _animation.value,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
