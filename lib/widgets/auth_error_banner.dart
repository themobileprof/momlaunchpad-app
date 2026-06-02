import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Visible auth failure message — shown inline on login/register forms.
class AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AuthErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: AppSpacing.spaceSM),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyTextMedium.copyWith(
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppSpacing.spaceXS),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Icon(Icons.close_rounded, color: AppColors.error, size: 20),
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
