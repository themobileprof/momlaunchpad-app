import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';
import 'glass_container.dart';

/// Home hero for users trying to conceive — quick actions and supportive copy.
class TtcHomeHero extends StatelessWidget {
  final VoidCallback onTalk;
  final VoidCallback onLogSymptoms;

  const TtcHomeHero({
    super.key,
    required this.onTalk,
    required this.onLogSymptoms,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.92,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_rounded, color: context.appPrimary, size: 24),
              const SizedBox(width: AppSpacing.spaceSM),
              Expanded(
                child: Text(
                  'Trying to conceive',
                  style: AppTypography.headingSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            'MomLaunchpad is built for pregnancy first — and we\'re here while you\'re trying too. '
            'Use chat for questions and worries, and log how you feel day to day.',
            style: AppTypography.caption.copyWith(
              color: context.appInkSubtle,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Talk about this cycle',
                  onTap: onTalk,
                ),
              ),
              const SizedBox(width: AppSpacing.spaceSM),
              Expanded(
                child: _ActionTile(
                  icon: Icons.edit_note_rounded,
                  label: 'Log how you feel',
                  onTap: onLogSymptoms,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceSM,
        vertical: AppSpacing.spaceMD,
      ),
      child: Column(
        children: [
          Icon(icon, color: context.appPrimary),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
