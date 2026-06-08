import '../services/api_service.dart';

/// Detects API responses that mean the stored session is no longer valid.
class SessionErrors {
  SessionErrors._();

  static bool isInvalidSession(ApiException exception) {
    if (exception.isUnauthorized) return true;
    // JWT accepted but user row missing (stale token after DB reset, etc.)
    if (exception.isNotFound) return true;
    return false;
  }
}
