class PregnancyWeekEntry {
  final int week;
  final String headline;
  final int trimester;
  final int gestationalMonth;
  final String babySizeLabel;
  final String momNarrative;
  final String babyNarrative;
  final String? gentleTip;

  const PregnancyWeekEntry({
    required this.week,
    required this.headline,
    required this.trimester,
    required this.gestationalMonth,
    required this.babySizeLabel,
    required this.momNarrative,
    required this.babyNarrative,
    this.gentleTip,
  });

  factory PregnancyWeekEntry.fromJson(Map<String, dynamic> json) {
    return PregnancyWeekEntry(
      week: json['week'] as int,
      headline: json['headline']?.toString() ?? '',
      trimester: json['trimester'] as int,
      gestationalMonth: json['gestationalMonth'] as int,
      babySizeLabel: json['babySizeLabel']?.toString() ?? '',
      momNarrative: json['momNarrative']?.toString() ?? '',
      babyNarrative: json['babyNarrative']?.toString() ?? '',
      gentleTip: json['gentleTip']?.toString(),
    );
  }
}
