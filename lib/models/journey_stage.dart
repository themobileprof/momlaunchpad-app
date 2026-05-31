/// Where someone is on their reproductive journey.
enum JourneyStage {
  ttc(
    'ttc',
    'Trying to conceive',
    'Support through fertility questions, cycles, and the wait.',
  ),
  pregnant(
    'pregnant',
    'Currently pregnant',
    'Stage-matched guidance through your pregnancy.',
  ),
  postpartum(
    'postpartum',
    'Postpartum',
    'Recovery and wellbeing after birth — focused on you.',
  ),
  miscarriage(
    'miscarriage',
    'Pregnancy loss',
    'Gentle support after miscarriage or pregnancy loss.',
  );

  const JourneyStage(this.apiValue, this.label, this.description);

  final String apiValue;
  final String label;
  final String description;

  static JourneyStage? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final stage in JourneyStage.values) {
      if (stage.apiValue == value) return stage;
    }
    return null;
  }

  /// Allowed next stages from the current one.
  List<JourneyStage> get allowedTransitions {
    switch (this) {
      case JourneyStage.ttc:
        return [JourneyStage.pregnant];
      case JourneyStage.pregnant:
        return [JourneyStage.postpartum, JourneyStage.miscarriage];
      case JourneyStage.miscarriage:
        return [JourneyStage.ttc, JourneyStage.pregnant];
      case JourneyStage.postpartum:
        return [JourneyStage.ttc, JourneyStage.pregnant];
    }
  }

  String get transitionHint {
    switch (this) {
      case JourneyStage.ttc:
        return 'Congratulations — update when you become pregnant.';
      case JourneyStage.pregnant:
        return 'Update when you give birth or if you experience a loss.';
      case JourneyStage.postpartum:
        return 'Update if you begin trying again or become pregnant.';
      case JourneyStage.miscarriage:
        return 'Update when you\'re ready to try again or if you become pregnant.';
    }
  }
}
