/// Buckets user chat text for GA4 — never send raw message content to analytics.
class AnalyticsTopicClassifier {
  static String topicBucket(String message) {
    final m = message.toLowerCase();
    if (_hasAny(m, ['nausea', 'sick', 'vomit', 'morning sickness'])) {
      return 'nausea_morning_sickness';
    }
    if (_hasAny(m, ['kick', 'movement', 'moving', 'baby move'])) {
      return 'baby_movement';
    }
    if (_hasAny(m, ['cramp', 'pain', 'hurt', 'ache'])) {
      return 'pain_cramps';
    }
    if (_hasAny(m, ['diet', 'eat', 'food', 'nutrition', 'vitamin'])) {
      return 'diet_nutrition';
    }
    if (_hasAny(m, ['sleep', 'tired', 'fatigue', 'insomnia'])) {
      return 'sleep_fatigue';
    }
    if (_hasAny(m, ['doctor', 'appointment', 'checkup', 'hospital'])) {
      return 'medical_appointments';
    }
    if (_hasAny(m, ['week', 'trimester', 'month pregnant', 'due date'])) {
      return 'pregnancy_timeline';
    }
    if (_hasAny(m, ['exercise', 'workout', 'yoga', 'walk'])) {
      return 'exercise_fitness';
    }
    if (_hasAny(m, ['anxiety', 'stress', 'worried', 'depress', 'mental'])) {
      return 'mental_health';
    }
    if (_hasAny(m, ['ovulation', 'ttc', 'trying to conceive', 'fertility'])) {
      return 'ttc_fertility';
    }
    if (_hasAny(m, ['breastfeed', 'lactation', 'milk'])) {
      return 'breastfeeding';
    }
    return 'general_questions';
  }

  static String intentCategory(String message) {
    final m = message.toLowerCase();
    if (_hasAny(m, ['hi', 'hello', 'hey', 'thanks', 'thank you', 'bye'])) {
      return 'small_talk';
    }
    if (_hasAny(m, [
      'hurt',
      'pain',
      'nausea',
      'bleed',
      'fever',
      'symptom',
      'cramp',
    ])) {
      return 'symptom_report';
    }
    if (_hasAny(m, ['remind', 'appointment', 'schedule', 'calendar'])) {
      return 'scheduling_related';
    }
    return 'pregnancy_question';
  }

  static String messageLengthBucket(int length) {
    if (length < 40) return 'short';
    if (length < 160) return 'medium';
    return 'long';
  }

  static bool _hasAny(String haystack, List<String> needles) {
    for (final n in needles) {
      if (haystack.contains(n)) return true;
    }
    return false;
  }
}
