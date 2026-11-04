import 'package:flutter/material.dart';
import '../models/symptom.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/condition_class.dart';

/// Small badge for fleeting / common / watch / standing + recurrence.
class ConditionClassChip extends StatelessWidget {
  final Symptom symptom;

  const ConditionClassChip({super.key, required this.symptom});

  @override
  Widget build(BuildContext context) {
    final cls = symptom.conditionClass ?? classifySymptomType(symptom.symptomType);
    final color = _colorFor(context, cls);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        symptom.conditionClassDisplay,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _colorFor(BuildContext context, ConditionClass cls) {
    switch (cls) {
      case ConditionClass.watch:
        return Colors.deepOrange.shade700;
      case ConditionClass.common:
        return context.appPrimary;
      case ConditionClass.standing:
        return Colors.indigo.shade600;
      case ConditionClass.fleeting:
        return Colors.blueGrey.shade600;
    }
  }
}
