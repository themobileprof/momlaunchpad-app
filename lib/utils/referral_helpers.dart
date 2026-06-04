/// Extracts a referral code from a share link or raw code string.
String? referralCodeFromInput(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.queryParameters['ref'] != null) {
    final ref = uri.queryParameters['ref']!.trim();
    return ref.isEmpty ? null : ref.toUpperCase();
  }
  return trimmed.toUpperCase();
}
