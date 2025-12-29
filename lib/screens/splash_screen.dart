import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Splash screen shown while checking auth status
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.pinkGradient,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.rocket_launch,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'MomLaunchpad',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primaryPink),
            ),
          ],
        ),
      ),
    );
  }
}
