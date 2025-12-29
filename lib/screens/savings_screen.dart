import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Savings screen (MVP-lite)
class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Savings', style: AppTypography.headingMedium),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.savings_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppSpacing.spaceMD),
            Text(
              'Savings tracker',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.spaceSM),
            Text(
              'Coming soon',
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
