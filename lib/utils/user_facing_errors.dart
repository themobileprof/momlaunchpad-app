/// Maps raw API errors to copy suitable for end users.
class UserFacingErrors {
  UserFacingErrors._();

  static String communityLoad(String? apiMessage) {
    final lower = apiMessage?.toLowerCase().trim() ?? '';
    if (lower.contains('user not found')) {
      return 'We couldn\'t load your community profile. Try again, or sign out and '
          'sign back in if this keeps happening.';
    }
    if (lower.contains('failed host lookup') ||
        lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('socket')) {
      return 'Check your internet connection and try again.';
    }
    if (apiMessage != null && apiMessage.isNotEmpty && !_looksInternal(apiMessage)) {
      return apiMessage;
    }
    return 'Community isn\'t available right now. Please try again in a moment.';
  }

  static bool _looksInternal(String message) {
    final lower = message.toLowerCase();
    return lower.contains('sql') ||
        lower.contains('internal server') ||
        lower.contains('panic') ||
        lower.startsWith('failed to ');
  }
}
