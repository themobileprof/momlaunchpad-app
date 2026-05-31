import '../models/journey_stage.dart';
import '../models/user_profile.dart';
import 'pregnancy_timing.dart';

/// Display helpers for journey-aware UI.
class JourneyHelpers {
  JourneyHelpers._();

  static JourneyStage? stageOf(UserProfile? profile) {
    if (profile == null) return null;
    return profile.journeyStage ??
        (profile.pregnancyWeek != null || profile.expectedDeliveryDate != null
            ? JourneyStage.pregnant
            : null);
  }

  static String homeBadgeLabel(UserProfile profile) {
    final stage = stageOf(profile);
    switch (stage) {
      case JourneyStage.ttc:
        return 'Trying to conceive';
      case JourneyStage.pregnant:
        if (profile.pregnancyWeek != null) {
          return 'Week ${profile.pregnancyWeek}';
        }
        return 'Pregnant';
      case JourneyStage.postpartum:
        if (profile.babyBirthDate != null) {
          final weeks = weeksPostpartum(profile.babyBirthDate!);
          if (weeks == 0) return 'New postpartum';
          return '$weeks wks postpartum';
        }
        return 'Postpartum';
      case JourneyStage.miscarriage:
        return 'Here for you';
      case null:
        return profile.pregnancySummary;
    }
  }

  static int weeksPostpartum(DateTime birthDate, [DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    final birth = _dateOnly(birthDate);
    final days = today.difference(birth).inDays;
    if (days < 0) return 0;
    return days ~/ 7;
  }

  static String profileSummary(UserProfile profile) {
    final stage = stageOf(profile);
    switch (stage) {
      case JourneyStage.ttc:
        return 'Trying to conceive';
      case JourneyStage.pregnant:
        return profile.pregnancySummary;
      case JourneyStage.postpartum:
        if (profile.babyBirthDate != null) {
          final weeks = weeksPostpartum(profile.babyBirthDate!);
          return weeks == 0
              ? 'Postpartum · baby just arrived'
              : 'Postpartum · $weeks weeks';
        }
        return 'Postpartum recovery';
      case JourneyStage.miscarriage:
        if (profile.lossDate != null) {
          return 'Pregnancy loss · ${_formatShortDate(profile.lossDate!)}';
        }
        return 'Pregnancy loss support';
      case null:
        return profile.pregnancySummary;
    }
  }

  static bool needsPregnancyWeek(JourneyStage stage) => stage == JourneyStage.pregnant;

  static bool needsBabyBirthDate(JourneyStage stage) => stage == JourneyStage.postpartum;

  static DateTime eddFromWeek(int week) => PregnancyTiming.eddFromWeek(week);

  static String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
