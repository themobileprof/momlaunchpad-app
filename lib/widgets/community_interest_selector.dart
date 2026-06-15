import 'package:flutter/material.dart';

import '../models/community.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'solid_filter_chip.dart';

/// Chip picker for up to [maxSelections] community feed topics.
class CommunityInterestSelector extends StatelessWidget {
  const CommunityInterestSelector({
    super.key,
    required this.groups,
    required this.selected,
    required this.onToggle,
    this.maxSelections = 5,
    this.onSelectionLimitReached,
  });

  final List<CommunityInterestGroup> groups;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final int maxSelections;
  final VoidCallback? onSelectionLimitReached;

  void _handleToggle(String key) {
    if (selected.contains(key)) {
      onToggle(key);
      return;
    }
    if (selected.length >= maxSelections) {
      onSelectionLimitReached?.call();
      return;
    }
    onToggle(key);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Feed topics',
              style: AppTypography.bodyTextMedium.copyWith(color: context.appInk),
            ),
            const Spacer(),
            Text(
              '${selected.length}/$maxSelections',
              style: AppTypography.caption.copyWith(color: context.appInkMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spaceSM),
        for (final group in groups) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.spaceMD,
              bottom: AppSpacing.spaceSM,
            ),
            child: Text(
              group.label,
              style: AppTypography.caption.copyWith(
                color: context.appPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Wrap(
            spacing: AppSpacing.spaceSM,
            runSpacing: AppSpacing.spaceSM,
            children: group.items.map((item) {
              final isSelected = selected.contains(item.key);
              return SolidFilterChip(
                label: Text(item.label),
                selected: isSelected,
                onSelected: (_) => _handleToggle(item.key),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
