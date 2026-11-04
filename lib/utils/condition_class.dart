import '../models/symptom.dart';

/// Mirrors backend condition classes for symptom prompt relevance.
enum ConditionClass {
  fleeting,
  common,
  watch,
  standing,
}

const _fleetingTypes = {
  'cold',
  'cough',
  'fever',
  'sore_throat',
  'fatigue',
  'insomnia',
  'mood_changes',
};

const _commonTypes = {
  'nausea',
  'vomiting',
  'heartburn',
  'constipation',
  'back_pain',
  'cramping',
  'breast_changes',
  'frequent_urination',
  'dizziness',
  'headache',
  'swelling',
};

const _watchTypes = {
  'malaria',
  'bleeding',
  'vision_changes',
  'contractions',
  'shortness_breath',
  'preeclampsia_signs',
};

const recurrenceWindow = Duration(days: 28);
const recurrenceThreshold = 2;
const fleetingRecent = Duration(days: 7);
const commonRecent = Duration(days: 14);
const watchRecent = Duration(days: 90);

ConditionClass classifySymptomType(String type) {
  final key = type.trim().toLowerCase();
  if (_watchTypes.contains(key)) return ConditionClass.watch;
  if (_commonTypes.contains(key)) return ConditionClass.common;
  if (_fleetingTypes.contains(key)) return ConditionClass.fleeting;
  return ConditionClass.fleeting;
}

ConditionClass parseConditionClass(String? raw, {String? symptomType}) {
  switch ((raw ?? '').trim().toLowerCase()) {
    case 'watch':
      return ConditionClass.watch;
    case 'common':
      return ConditionClass.common;
    case 'standing':
      return ConditionClass.standing;
    case 'fleeting':
      return ConditionClass.fleeting;
    default:
      return classifySymptomType(symptomType ?? '');
  }
}

String conditionClassLabel(ConditionClass c) {
  switch (c) {
    case ConditionClass.fleeting:
      return 'Fleeting';
    case ConditionClass.common:
      return 'Common';
    case ConditionClass.watch:
      return 'Watch';
    case ConditionClass.standing:
      return 'Standing';
  }
}

/// Whether a logged symptom should still surface in check-ins / recent lists.
bool isRelevantForCheckIn(Symptom symptom, {DateTime? now, int? recurrenceCount}) {
  final n = now ?? DateTime.now();
  final age = n.difference(symptom.reportedAt);
  final count = recurrenceCount ?? symptom.recurrenceCount ?? 1;
  final recurrent = symptom.isRecurrent || count >= recurrenceThreshold;
  final cls = symptom.conditionClass ?? classifySymptomType(symptom.symptomType);

  switch (cls) {
    case ConditionClass.watch:
      return age <= watchRecent;
    case ConditionClass.common:
      return age <= commonRecent || recurrent;
    case ConditionClass.standing:
      return true;
    case ConditionClass.fleeting:
      return age <= fleetingRecent || recurrent;
  }
}

List<Symptom> selectRelevantSymptoms(
  List<Symptom> raw, {
  DateTime? now,
  int max = 5,
}) {
  final n = now ?? DateTime.now();
  final counts = <String, int>{};
  for (final s in raw) {
    if (n.difference(s.reportedAt) <= recurrenceWindow) {
      counts[s.symptomType] = (counts[s.symptomType] ?? 0) + 1;
    }
  }

  final seen = <String>{};
  final kept = <Symptom>[];
  for (final s in raw) {
    final count = counts[s.symptomType] ?? 1;
    final annotated = s.copyWith(
      conditionClass: s.conditionClass ?? classifySymptomType(s.symptomType),
      recurrenceCount: s.recurrenceCount ?? count,
      isRecurrent: s.isRecurrent || count >= recurrenceThreshold,
    );
    if (!isRelevantForCheckIn(annotated, now: n, recurrenceCount: count)) {
      continue;
    }
    final cls = annotated.conditionClass!;
    if (cls != ConditionClass.watch && seen.contains(annotated.symptomType)) {
      continue;
    }
    seen.add(annotated.symptomType);
    kept.add(annotated);
  }

  kept.sort((a, b) {
    final aWatch = a.conditionClass == ConditionClass.watch;
    final bWatch = b.conditionClass == ConditionClass.watch;
    if (aWatch != bWatch) return aWatch ? -1 : 1;
    return b.reportedAt.compareTo(a.reportedAt);
  });

  if (kept.length > max) return kept.sublist(0, max);
  return kept;
}
