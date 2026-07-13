import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pregnancy_week_entry.dart';

const pregnancyWeekMin = 4;
const pregnancyWeekMax = 40;

int clampPregnancyWeek(int week) {
  return week.clamp(pregnancyWeekMin, pregnancyWeekMax);
}

String trimesterLabel(int trimester) {
  switch (trimester) {
    case 1:
      return 'First trimester';
    case 2:
      return 'Second trimester';
    default:
      return 'Third trimester';
  }
}

String monthLabel(int month) => 'Month $month';

String pregnancyFoetusAssetPath(int gestationalMonth) {
  final month = gestationalMonth.clamp(1, 9);
  return 'assets/images/foetus/month$month.jpg';
}

final pregnancyTimelineProvider =
    FutureProvider<Map<int, PregnancyWeekEntry>>((ref) async {
  final raw =
      await rootBundle.loadString('assets/data/pregnancy_weeks.json');
  final list = (jsonDecode(raw) as List<dynamic>)
      .map((e) => PregnancyWeekEntry.fromJson(e as Map<String, dynamic>))
      .toList();
  return {for (final entry in list) entry.week: entry};
});

PregnancyWeekEntry getPregnancyWeekEntry(
  Map<int, PregnancyWeekEntry> byWeek,
  int week,
) {
  final w = clampPregnancyWeek(week);
  return byWeek[w] ?? byWeek[20]!;
}
