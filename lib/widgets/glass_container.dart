import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.5,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = context.appBrightness;
    final fill = color ?? AppColors.glassFill(brightness);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: fill.withValues(alpha: opacity.clamp(0.0, 1.0)),
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              border: border ??
                  Border.all(
                    color: AppColors.glassBorderColor(brightness)
                        .withValues(alpha: 0.35),
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
