/// User profile and personalization facts from the backend.
class UserProfile {
  final String name;
  final String language;
  final bool onboardingCompleted;
  final DateTime? expectedDeliveryDate;
  final int? pregnancyWeek;
  final Map<String, String> facts;

  UserProfile({
    required this.name,
    required this.language,
    required this.onboardingCompleted,
    this.expectedDeliveryDate,
    this.pregnancyWeek,
    this.facts = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawFacts = json['facts'];
    final facts = <String, String>{};
    if (rawFacts is Map) {
      rawFacts.forEach((key, value) {
        facts[key.toString()] = value.toString();
      });
    }

    return UserProfile(
      name: json['name']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'].toString())
          : null,
      pregnancyWeek: json['pregnancy_week'] as int?,
      facts: facts,
    );
  }

  String? get primaryConcern => facts['primary_concern'];
  String? get isFirstPregnancy => facts['is_first_pregnancy'];
  String? get diet => facts['diet'];

  String get pregnancySummary {
    if (pregnancyWeek != null) {
      return 'Week $pregnancyWeek';
    }
    if (expectedDeliveryDate != null) {
      final month = expectedDeliveryDate!.month;
      final day = expectedDeliveryDate!.day;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return 'Due ${months[month - 1]} $day';
    }
    return 'Not set';
  }
}
