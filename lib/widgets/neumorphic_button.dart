import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class NeumorphicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final Color? foregroundColor;
  /// Solid brand fill (teal/mint) with high-contrast label — no soft neumorphic glow.
  final bool filled;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.foregroundColor,
    this.filled = false,
    this.padding,
    this.borderRadius = 16,
    this.width,
    this.height,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.filled;
    final background =
        widget.color ?? (isFilled ? context.appPrimary : context.appSurface);
    final foreground = widget.foregroundColor ??
        (isFilled ? context.appOnPrimary : context.appInk);
    final borderColor = isFilled
        ? Colors.transparent
        : context.appPrimary.withValues(alpha: 0.2);

    final shadows = isFilled
        ? [
            BoxShadow(
              color: background.withValues(alpha: _isPressed ? 0.15 : 0.35),
              blurRadius: _isPressed ? 8 : 16,
              offset: Offset(0, _isPressed ? 2 : 6),
            ),
          ]
        : _isPressed
            ? [
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.1),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
                BoxShadow(
                  color: context.isDarkMode
                      ? Colors.black.withValues(alpha: 0.2)
                      : AppColors.shadowLight,
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadowDark.withValues(alpha: 0.3),
                  offset: const Offset(4, 4),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color: context.isDarkMode
                      ? Colors.black.withValues(alpha: 0.15)
                      : AppColors.shadowLight,
                  offset: const Offset(-4, -4),
                  blurRadius: 10,
                ),
              ];

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: borderColor),
          boxShadow: shadows,
        ),
        child: DefaultTextStyle(
          style: AppTypography.button.copyWith(color: foreground),
          child: IconTheme(
            data: IconThemeData(color: foreground),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
