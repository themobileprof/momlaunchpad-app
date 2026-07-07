import 'package:shared_preferences/shared_preferences.dart';

const _dismissedKeysPref = 'visit_check_in_dismissed_keys';
const _monthlyDismissedAtPref = 'visit_check_in_monthly_dismissed_at';

class VisitCheckInDismissals {
  static Future<Set<String>> loadDismissedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_dismissedKeysPref)?.toSet() ?? {};
  }

  static Future<void> dismiss(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_dismissedKeysPref)?.toSet() ?? {};
    keys.add(key);
    await prefs.setStringList(_dismissedKeysPref, keys.toList());
  }

  static Future<DateTime?> loadMonthlyDismissedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_monthlyDismissedAtPref);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Future<void> dismissMonthly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _monthlyDismissedAtPref,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
