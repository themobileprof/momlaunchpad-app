import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

class NeumorphicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
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
    final color = widget.color ?? AppColors.creamBackground;
    
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? [
                  // Pressed state: Inner shadows or flat
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.shadowLight,
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  // Unpressed state: Outer soft shadows
                  BoxShadow(
                    color: AppColors.shadowDark.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: AppColors.shadowLight,
                    offset: const Offset(-4, -4),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: DefaultTextStyle(
          style: AppTypography.button.copyWith(color: AppColors.textDark),
          child: widget.child,
        ),
      ),
    );
  }
}
