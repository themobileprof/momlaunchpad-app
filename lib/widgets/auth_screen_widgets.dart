import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class AuthLogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double logoSize;

  const AuthLogoHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.logoSize = 88,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.appPrimary,
            boxShadow: [
              BoxShadow(
                color: context.appPrimary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: context.appSurface,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceMD),
        Text(title, style: AppTypography.headingMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.spaceXS),
        Text(subtitle, style: AppTypography.caption, textAlign: TextAlign.center),
      ],
    );
  }
}

class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.plum.withValues(alpha: 0.12))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
          child: Text(
            'OR',
            style: AppTypography.label.copyWith(color: AppColors.inkLight),
          ),
        ),
        Expanded(child: Divider(color: AppColors.plum.withValues(alpha: 0.12))),
      ],
    );
  }
}
