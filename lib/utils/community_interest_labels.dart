import '../models/community.dart';

/// Maps stored interest keys to human-readable labels from the catalog.
List<String> communityInterestLabels(
  List<String> keys,
  List<CommunityInterestGroup> groups,
) {
  if (keys.isEmpty) return const [];

  final labelsByKey = <String, String>{};
  for (final group in groups) {
    for (final item in group.items) {
      labelsByKey[item.key] = item.label;
    }
  }

  return keys.map((key) => labelsByKey[key] ?? key).toList();
}
