import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Atmospheric canvas with soft rose/plum orbs — used on auth and splash screens.
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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.softGlow),
      child: Stack(
        children: [
          if (showOrbs) ...[
            Positioned(
              top: -80,
              right: -60,
              child: _Orb(size: 260, gradient: AppColors.heroOrbPink),
            ),
            Positioned(
              top: 120,
              left: -90,
              child: _Orb(size: 220, gradient: AppColors.heroOrbPurple),
            ),
            Positioned(
              bottom: -40,
              right: 40,
              child: _Orb(size: 180, gradient: AppColors.heroOrbPurple),
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
  final Gradient gradient;

  const _Orb({required this.size, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
    );
  }
}
