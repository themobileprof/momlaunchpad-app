/// Gestational timing helpers matching backend `internal/profile/pregnancy.go`.
class PregnancyTiming {
  PregnancyTiming._();

  static const fullTermWeeks = 40;

  /// Expected delivery date from current gestational week.
  static DateTime eddFromWeek(int week, [DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    final clamped = week.clamp(1, 42);
    final weeksRemaining = fullTermWeeks - clamped;
    return today.add(Duration(days: weeksRemaining * 7));
  }

  /// Gestational week estimated from expected delivery date.
  static int weekFromEdd(DateTime edd, [DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    final due = _dateOnly(edd);
    final daysUntil = due.difference(today).inDays;
    final weeksRemaining = daysUntil ~/ 7;
    final week = fullTermWeeks - weeksRemaining;
    return week.clamp(1, 42);
  }

  /// True when [edd] matches what [week] would produce (same calendar day).
  static bool eddMatchesWeek(DateTime edd, int week, [DateTime? now]) {
    final expected = eddFromWeek(week, now);
    return _dateOnly(expected) == _dateOnly(edd);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
