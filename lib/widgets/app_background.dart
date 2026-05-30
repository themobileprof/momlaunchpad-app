import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Atmospheric canvas — solid background, optional soft accent orbs.
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const AppBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    final canvas = context.appCanvas;
    final accent = context.appPrimary.withValues(alpha: 0.06);

    return ColoredBox(
      color: canvas,
      child: Stack(
        children: [
          if (showOrbs) ...[
            Positioned(
              top: -80,
              right: -60,
              child: _Orb(size: 260, color: accent),
            ),
            Positioned(
              top: 120,
              left: -90,
              child: _Orb(size: 220, color: accent),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final Color color;

  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
