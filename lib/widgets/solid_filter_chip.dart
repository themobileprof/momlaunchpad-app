import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Filter/choice chip with a solid teal fill when selected (no pastel button tint).
class SolidFilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const SolidFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: DefaultTextStyle(
        style: AppTypography.caption.copyWith(
          color: selected ? context.appOnPrimary : context.appInk,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
        child: label,
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: selected,
      selectedColor: context.appPrimary,
      backgroundColor: context.appSurface,
      checkmarkColor: context.appOnPrimary,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : context.appPrimary.withValues(alpha: 0.2),
      ),
    );
  }
}
