// Helpers for external HTTPS image links (no server-side file storage).
import '../config/app_config.dart';

bool isValidHttpsImageUrl(String? value) {
  if (value == null || value.trim().isEmpty) return true;
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

String? httpsImageUrlValidator(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  if (!isValidHttpsImageUrl(value)) {
    return 'Enter a valid https:// image link';
  }
  return null;
}

String? normalizedHttpsImageUrl(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Builds an absolute URL for API-hosted media paths.
String? resolveMediaUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final trimmed = value.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  if (trimmed.startsWith('/')) {
    return '${AppConfig.baseUrl}$trimmed';
  }
  return trimmed;
}
