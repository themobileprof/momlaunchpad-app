import 'journey_stage.dart';
import 'baby_gender.dart';

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
  final BabyGender? babyGender;
  final String? primaryConcern;
  final String? dietPreference;
  final Map<String, String> learnedFacts;
  final Map<String, String> facts;
  final String? profilePhotoUrl;
  final String? country;
  final String? countryCode;
  final String? stateProvince;
  final String? city;
  final bool communityOnboardingCompleted;
  final List<String> communityInterests;
  final String referralCode;
  final String referralLink;
  final int referralRewardPoints;
  final int totalReferrals;

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
    this.babyGender,
    this.primaryConcern,
    this.dietPreference,
    this.learnedFacts = const {},
    this.facts = const {},
    this.profilePhotoUrl,
    this.country,
    this.countryCode,
    this.stateProvince,
    this.city,
    this.communityOnboardingCompleted = false,
    this.communityInterests = const [],
    this.referralCode = '',
    this.referralLink = '',
    this.referralRewardPoints = 0,
    this.totalReferrals = 0,
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
      babyGender: BabyGender.fromApi(json['baby_gender']?.toString()),
      primaryConcern: json['primary_concern']?.toString(),
      dietPreference: json['diet_preference']?.toString(),
      learnedFacts: _parseFactMap(json['learned_facts']),
      facts: _parseFactMap(json['facts']),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      country: json['country']?.toString(),
      countryCode: json['country_code']?.toString(),
      stateProvince: json['state_province']?.toString(),
      city: json['city']?.toString(),
      communityOnboardingCompleted:
          json['community_onboarding_completed'] as bool? ?? false,
      communityInterests: (json['community_interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      referralCode: json['referral_code']?.toString() ?? '',
      referralLink: json['referral_link']?.toString() ?? '',
      referralRewardPoints: json['referral_reward_points'] as int? ?? 0,
      totalReferrals: json['total_referrals'] as int? ?? 0,
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

  UserProfile copyWith({
    String? name,
    String? language,
    bool? onboardingCompleted,
    JourneyStage? journeyStage,
    DateTime? journeyStageSince,
    DateTime? babyBirthDate,
    DateTime? lossDate,
    DateTime? expectedDeliveryDate,
    DateTime? pregnancyStartDate,
    int? pregnancyWeek,
    bool? isFirstPregnancy,
    BabyGender? babyGender,
    bool clearBabyGender = false,
    String? primaryConcern,
    String? dietPreference,
    Map<String, String>? learnedFacts,
    Map<String, String>? facts,
    String? profilePhotoUrl,
    String? country,
    String? countryCode,
    String? stateProvince,
    String? city,
    bool? communityOnboardingCompleted,
    List<String>? communityInterests,
    String? referralCode,
    String? referralLink,
    int? referralRewardPoints,
    int? totalReferrals,
  }) {
    return UserProfile(
      name: name ?? this.name,
      language: language ?? this.language,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      journeyStage: journeyStage ?? this.journeyStage,
      journeyStageSince: journeyStageSince ?? this.journeyStageSince,
      babyBirthDate: babyBirthDate ?? this.babyBirthDate,
      lossDate: lossDate ?? this.lossDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      pregnancyStartDate: pregnancyStartDate ?? this.pregnancyStartDate,
      pregnancyWeek: pregnancyWeek ?? this.pregnancyWeek,
      isFirstPregnancy: isFirstPregnancy ?? this.isFirstPregnancy,
      babyGender: clearBabyGender ? null : (babyGender ?? this.babyGender),
      primaryConcern: primaryConcern ?? this.primaryConcern,
      dietPreference: dietPreference ?? this.dietPreference,
      learnedFacts: learnedFacts ?? this.learnedFacts,
      facts: facts ?? this.facts,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      stateProvince: stateProvince ?? this.stateProvince,
      city: city ?? this.city,
      communityOnboardingCompleted:
          communityOnboardingCompleted ?? this.communityOnboardingCompleted,
      communityInterests: communityInterests ?? this.communityInterests,
      referralCode: referralCode ?? this.referralCode,
      referralLink: referralLink ?? this.referralLink,
      referralRewardPoints: referralRewardPoints ?? this.referralRewardPoints,
      totalReferrals: totalReferrals ?? this.totalReferrals,
    );
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
  final BabyGender? babyGender;
  final bool clearBabyGender;
  final String? primaryConcern;
  final String? dietPreference;
  final String? profilePhotoUrl;
  final String? country;
  final String? countryCode;
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
    this.babyGender,
    this.clearBabyGender = false,
    this.primaryConcern,
    this.dietPreference,
    this.profilePhotoUrl,
    this.country,
    this.countryCode,
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
      if (clearBabyGender) 'baby_gender': '',
      if (!clearBabyGender && babyGender != null)
        'baby_gender': babyGender!.apiValue,
      if (primaryConcern != null) 'primary_concern': primaryConcern,
      if (dietPreference != null) 'diet_preference': dietPreference,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (country != null) 'country': country,
      if (countryCode != null) 'country_code': countryCode,
      if (stateProvince != null) 'state_province': stateProvince,
      if (city != null) 'city': city,
    };
  }
}
