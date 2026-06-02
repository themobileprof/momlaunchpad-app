import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/app_background.dart';

/// Splash screen shown while checking auth status
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: context.appPrimary.withValues(alpha: 0.25),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceLG),
              Text(
                'MomLaunchpad',
                style: AppTypography.brandTitle.copyWith(color: context.appPrimary),
              ),
              const SizedBox(height: AppSpacing.spaceSM),
              Text(
                'Launching your journey…',
                style: AppTypography.caption.copyWith(color: context.appInkMuted),
              ),
              const SizedBox(height: AppSpacing.spaceXXL),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(context.appAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
