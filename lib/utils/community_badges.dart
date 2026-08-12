import '../models/community_badge_request.dart';

/// Badge keys that identify healthcare / clinic ambassadors on home and profile.
const professionalBadgeKeys = <String>[
  'doctor',
  'midwife',
  'pediatrician',
  'nurse',
  'lactation_consultant',
  'ambassador',
];

final _professionalBadgeSet = professionalBadgeKeys.toSet();

bool isProfessionalBadgeKey(String key) => _professionalBadgeSet.contains(key);

bool hasProfessionalBadge(Iterable<String> badges) =>
    badges.any(isProfessionalBadgeKey);

String? primaryProfessionalBadgeKey(Iterable<String> badges) {
  for (final key in professionalBadgeKeys) {
    if (badges.contains(key)) return key;
  }
  return null;
}

String badgeLabelForKey(String key, MyCommunityBadges data) {
  for (final t in data.requestableTypes) {
    if (t.key == key) return t.label;
  }
  return key.replaceAll('_', ' ');
}

String? primaryProfessionalBadgeLabel(MyCommunityBadges data) {
  final key = primaryProfessionalBadgeKey(data.badges);
  if (key == null) return null;
  return badgeLabelForKey(key, data);
}

bool credentialRequiredForBadge(String badgeType) => badgeType != 'ambassador';

String? validateBadgeRequestDetails(String badgeType, BadgeRequestDetails details) {
  if (details.workplace.trim().isEmpty) {
    return 'Workplace or facility is required';
  }
  if (details.roleTitle.trim().isEmpty) {
    return 'Role or job title is required';
  }
  if (credentialRequiredForBadge(badgeType) &&
      (details.credentialId == null || details.credentialId!.trim().isEmpty)) {
    return 'License or registration number is required for this badge';
  }
  final url = details.verificationUrl?.trim();
  if (url != null && url.isNotEmpty) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
      return 'Verification link must be a valid URL';
    }
  }
  return null;
}

List<String> formatBadgeRequestDetails(BadgeRequestDetails details) {
  final lines = <String>[];
  if (details.workplace.trim().isNotEmpty) {
    lines.add('Workplace: ${details.workplace.trim()}');
  }
  if (details.roleTitle.trim().isNotEmpty) {
    lines.add('Role: ${details.roleTitle.trim()}');
  }
  if (details.credentialId != null && details.credentialId!.trim().isNotEmpty) {
    lines.add('Credential: ${details.credentialId!.trim()}');
  }
  if (details.verificationUrl != null && details.verificationUrl!.trim().isNotEmpty) {
    lines.add('Link: ${details.verificationUrl!.trim()}');
  }
  return lines;
}
