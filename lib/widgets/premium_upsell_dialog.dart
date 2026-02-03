import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

class PremiumUpsellDialog extends StatelessWidget {
  final String featureName;

  const PremiumUpsellDialog({
    super.key,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
      ),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppColors.primaryPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Text(
            'Premium Feature',
            style: AppTypography.headingMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTypography.bodyText,
          children: [
            const TextSpan(text: 'The '),
            TextSpan(
              text: featureName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
              text: ' feature is available only for Premium members. Upgrade now to unlock full access!',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Navigate to subscription screen
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subscription flow coming soon!')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceLG,
              vertical: AppSpacing.spaceSM,
            ),
          ),
          child: const Text('Upgrade to Premium'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
    );
  }
}
