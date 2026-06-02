import 'package:flutter/material.dart';
import '../models/journey_stage.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Selects a journey stage during onboarding or profile updates.
class JourneyStagePicker extends StatelessWidget {
  final JourneyStage? selected;
  final ValueChanged<JourneyStage> onSelected;
  final List<JourneyStage>? options;

  const JourneyStagePicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final stages = options ?? JourneyStage.values;

    return Column(
      children: [
        for (final stage in stages) ...[
          _StageOption(
            stage: stage,
            selected: selected == stage,
            onTap: () => onSelected(stage),
          ),
          if (stage != stages.last) const SizedBox(height: AppSpacing.spaceSM),
        ],
      ],
    );
  }
}

class _StageOption extends StatelessWidget {
  final JourneyStage stage;
  final bool selected;
  final VoidCallback onTap;

  const _StageOption({
    required this.stage,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          color: selected ? context.appPrimary : context.appSurface,
          border: Border.all(
            color: selected
                ? Colors.transparent
                : context.appPrimary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stage.label,
              style: AppTypography.bodyTextMedium.copyWith(
                color: selected ? context.appOnPrimary : context.appInk,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stage.description,
              style: AppTypography.caption.copyWith(
                color: selected
                    ? context.appOnPrimary.withValues(alpha: 0.85)
                    : context.appInkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
