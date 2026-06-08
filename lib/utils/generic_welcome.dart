import '../models/journey_stage.dart';
import '../models/user_profile.dart';
import 'journey_helpers.dart';

/// Static welcome copy when the personalized API message is unavailable.
String genericWelcomeMessage(UserProfile? profile) {
  final name = _firstName(profile?.name);
  final stage = JourneyHelpers.stageOf(profile);

  switch (stage) {
    case JourneyStage.ttc:
      return 'Hi $name! However your TTC journey looks today, you deserve support '
          'and care. We\'re here whenever you want to talk things through.';
    case JourneyStage.postpartum:
      return 'Hi $name! Postpartum is a lot — your recovery matters just as much '
          'as everything else. Be gentle with yourself today.';
    case JourneyStage.miscarriage:
      return 'Hi $name. We\'re holding space for you — there\'s no right way to feel. '
          'Reach out whenever you need a listening ear.';
    case JourneyStage.pregnant:
      final week = profile?.pregnancyWeek;
      final weekNote = week != null ? ' Week $week is a big milestone—' : ' ';
      return 'Hi $name!$weekNote you\'re doing meaningful work caring for yourself '
          'and your growing baby. Keep listening to your body and reach out to your '
          'care team with any concerns.';
    case null:
      return 'Hi $name! Welcome back. Take a moment for yourself today — we\'re here '
          'whenever you want to chat, track how you\'re feeling, or connect with other moms.';
  }
}

String _firstName(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  if (trimmed.isEmpty) return 'there';
  return trimmed.split(RegExp(r'\s+')).first;
}
