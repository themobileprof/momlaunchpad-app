/// User profile and personalization facts from the backend.
class UserProfile {
  final String name;
  final String language;
  final bool onboardingCompleted;
  final DateTime? expectedDeliveryDate;
  final DateTime? pregnancyStartDate;
  final int? pregnancyWeek;
  final bool? isFirstPregnancy;
  final String? primaryConcern;
  final String? dietPreference;
  final Map<String, String> learnedFacts;
  final Map<String, String> facts;

  UserProfile({
    required this.name,
    required this.language,
    required this.onboardingCompleted,
    this.expectedDeliveryDate,
    this.pregnancyStartDate,
    this.pregnancyWeek,
    this.isFirstPregnancy,
    this.primaryConcern,
    this.dietPreference,
    this.learnedFacts = const {},
    this.facts = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      expectedDeliveryDate: _parseDate(json['expected_delivery_date']),
      pregnancyStartDate: _parseDate(json['pregnancy_start_date']),
      pregnancyWeek: _parseInt(json['pregnancy_week']),
      isFirstPregnancy: json['is_first_pregnancy'] as bool?,
      primaryConcern: json['primary_concern']?.toString(),
      dietPreference: json['diet_preference']?.toString(),
      learnedFacts: _parseFactMap(json['learned_facts']),
      facts: _parseFactMap(json['facts']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value.toString());
  }

  static int? _parseInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static Map<String, String> _parseFactMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }

  String? get diet => dietPreference ?? facts['diet'];

  String get pregnancySummary {
    if (pregnancyWeek != null) {
      return 'Week $pregnancyWeek';
    }
    if (expectedDeliveryDate != null) {
      final date = expectedDeliveryDate!;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return 'Due ${months[date.month - 1]} ${date.day}';
    }
    return 'Not set';
  }
}

/// Payload for saving profile or completing onboarding.
class ProfileSavePayload {
  final String name;
  final String language;
  final int? pregnancyWeek;
  final DateTime? expectedDeliveryDate;
  final bool? isFirstPregnancy;
  final String? primaryConcern;
  final String? dietPreference;

  const ProfileSavePayload({
    required this.name,
    required this.language,
    this.pregnancyWeek,
    this.expectedDeliveryDate,
    this.isFirstPregnancy,
    this.primaryConcern,
    this.dietPreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'language': language,
      if (pregnancyWeek != null) 'pregnancy_week': pregnancyWeek,
      if (expectedDeliveryDate != null)
        'expected_delivery_date':
            expectedDeliveryDate!.toUtc().toIso8601String(),
      if (isFirstPregnancy != null) 'is_first_pregnancy': isFirstPregnancy,
      if (primaryConcern != null) 'primary_concern': primaryConcern,
      if (dietPreference != null) 'diet_preference': dietPreference,
    };
  }
}
