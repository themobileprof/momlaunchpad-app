import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/symptom_provider.dart';

/// Marks a symptom resolved and refreshes symptom providers.
Future<bool> markSymptomResolved(
  BuildContext context,
  WidgetRef ref,
  String symptomId,
) async {
  try {
    final service = ref.read(symptomServiceProvider);
    await service.resolveSymptom(symptomId);
    ref.invalidate(symptomHistoryProvider);
    ref.invalidate(recentSymptomsProvider);
    ref.invalidate(symptomStatsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptom marked as resolved'),
          backgroundColor: Colors.green,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is Exception ? e.toString().replaceFirst('Exception: ', '') : 'Failed to mark symptom as resolved',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
}
