import 'journey_stage.dart';

/// User profile and personalization facts from the backend.
class UserProfile {
  final String name;
  final String language;
  final bool onboardingCompleted;
  final JourneyStage? journeyStage;
  final DateTime? journeyStageSince;
  final DateTime? babyBirthDate;
  final DateTime? lossDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? pregnancyStartDate;
  final int? pregnancyWeek;
  final bool? isFirstPregnancy;
  final String? primaryConcern;
  final String? dietPreference;
  final Map<String, String> learnedFacts;
  final Map<String, String> facts;
  final String? profilePhotoUrl;
  final String? country;
  final String? stateProvince;
  final String? city;
  final bool communityOnboardingCompleted;
  final List<String> communityInterests;

  UserProfile({
    required this.name,
    required this.language,
    required this.onboardingCompleted,
    this.journeyStage,
    this.journeyStageSince,
    this.babyBirthDate,
    this.lossDate,
    this.expectedDeliveryDate,
    this.pregnancyStartDate,
    this.pregnancyWeek,
    this.isFirstPregnancy,
    this.primaryConcern,
    this.dietPreference,
    this.learnedFacts = const {},
    this.facts = const {},
    this.profilePhotoUrl,
    this.country,
    this.stateProvince,
    this.city,
    this.communityOnboardingCompleted = false,
    this.communityInterests = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name']?.toString() ?? '',
      language: json['language']?.toString() ?? 'en',
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      journeyStage: JourneyStage.fromApi(json['journey_stage']?.toString()),
      journeyStageSince: _parseDate(json['journey_stage_since']),
      babyBirthDate: _parseDate(json['baby_birth_date']),
      lossDate: _parseDate(json['loss_date']),
      expectedDeliveryDate: _parseDate(json['expected_delivery_date']),
      pregnancyStartDate: _parseDate(json['pregnancy_start_date']),
      pregnancyWeek: _parseInt(json['pregnancy_week']),
      isFirstPregnancy: json['is_first_pregnancy'] as bool?,
      primaryConcern: json['primary_concern']?.toString(),
      dietPreference: json['diet_preference']?.toString(),
      learnedFacts: _parseFactMap(json['learned_facts']),
      facts: _parseFactMap(json['facts']),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      country: json['country']?.toString(),
      stateProvince: json['state_province']?.toString(),
      city: json['city']?.toString(),
      communityOnboardingCompleted:
          json['community_onboarding_completed'] as bool? ?? false,
      communityInterests: (json['community_interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
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
  final JourneyStage? journeyStage;
  final int? pregnancyWeek;
  final DateTime? expectedDeliveryDate;
  final DateTime? babyBirthDate;
  final DateTime? lossDate;
  final bool? isFirstPregnancy;
  final String? primaryConcern;
  final String? dietPreference;
  final String? profilePhotoUrl;
  final String? country;
  final String? stateProvince;
  final String? city;

  const ProfileSavePayload({
    required this.name,
    required this.language,
    this.journeyStage,
    this.pregnancyWeek,
    this.expectedDeliveryDate,
    this.babyBirthDate,
    this.lossDate,
    this.isFirstPregnancy,
    this.primaryConcern,
    this.dietPreference,
    this.profilePhotoUrl,
    this.country,
    this.stateProvince,
    this.city,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'language': language,
      if (journeyStage != null) 'journey_stage': journeyStage!.apiValue,
      if (pregnancyWeek != null) 'pregnancy_week': pregnancyWeek,
      if (expectedDeliveryDate != null)
        'expected_delivery_date':
            expectedDeliveryDate!.toUtc().toIso8601String(),
      if (babyBirthDate != null)
        'baby_birth_date': babyBirthDate!.toUtc().toIso8601String(),
      if (lossDate != null)
        'loss_date': lossDate!.toUtc().toIso8601String(),
      if (isFirstPregnancy != null) 'is_first_pregnancy': isFirstPregnancy,
      if (primaryConcern != null) 'primary_concern': primaryConcern,
      if (dietPreference != null) 'diet_preference': dietPreference,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (country != null) 'country': country,
      if (stateProvince != null) 'state_province': stateProvince,
      if (city != null) 'city': city,
    };
  }
}
