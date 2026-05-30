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
    await ref.read(resolveSymptomProvider(symptomId).future);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptom marked as resolved'),
          backgroundColor: Colors.green,
        ),
      );
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark symptom as resolved'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
}
