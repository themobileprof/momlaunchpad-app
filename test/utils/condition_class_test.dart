import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/models/symptom.dart';
import 'package:momlaunchpad_mobile/utils/condition_class.dart';

Symptom _symptom({
  required String type,
  required DateTime reportedAt,
  bool resolved = false,
}) {
  return Symptom(
    id: type + reportedAt.toIso8601String(),
    symptomType: type,
    description: type,
    severity: 'mild',
    frequency: 'once',
    associatedSymptoms: const [],
    isResolved: resolved,
    reportedAt: reportedAt,
  );
}

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);

  test('classifies malaria as watch and cold as fleeting', () {
    expect(classifySymptomType('malaria'), ConditionClass.watch);
    expect(classifySymptomType('cold'), ConditionClass.fleeting);
    expect(classifySymptomType('nausea'), ConditionClass.common);
  });

  test('drops stale fleeting cold from relevant list', () {
    final raw = [
      _symptom(type: 'cold', reportedAt: now.subtract(const Duration(days: 21)), resolved: true),
      _symptom(type: 'nausea', reportedAt: now.subtract(const Duration(hours: 2))),
    ];
    final got = selectRelevantSymptoms(raw, now: now, max: 5);
    expect(got.length, 1);
    expect(got.first.symptomType, 'nausea');
  });

  test('keeps recurrent cold and watch malaria', () {
    final raw = [
      _symptom(type: 'cold', reportedAt: now.subtract(const Duration(days: 20)), resolved: true),
      _symptom(type: 'cold', reportedAt: now.subtract(const Duration(days: 3))),
      _symptom(type: 'malaria', reportedAt: now.subtract(const Duration(days: 45)), resolved: true),
    ];
    final got = selectRelevantSymptoms(raw, now: now, max: 5);
    expect(got.any((s) => s.symptomType == 'cold' && s.isRecurrent), isTrue);
    expect(got.any((s) => s.symptomType == 'malaria'), isTrue);
  });
}
