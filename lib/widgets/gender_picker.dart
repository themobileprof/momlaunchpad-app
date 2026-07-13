import 'package:flutter/material.dart';
import '../models/baby_gender.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../theme/colors.dart';

class GenderPicker extends StatelessWidget {
  final BabyGender? value;
  final ValueChanged<BabyGender> onChanged;

  const GenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: babyGenderOptions.map((opt) {
        final selected = value == opt.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
          child: Material(
            color: selected
                ? context.appPrimary.withValues(alpha: 0.08)
                : context.appSurface,
            borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
            child: InkWell(
              onTap: () => onChanged(opt.value),
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.spaceMD),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
                  border: Border.all(
                    color: selected
                        ? context.appPrimary
                        : context.appInkMuted.withValues(alpha: 0.2),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt.label,
                            style: AppTypography.bodyTextMedium.copyWith(
                              color: context.appInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt.hint,
                            style: AppTypography.caption.copyWith(
                              color: context.appInkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
