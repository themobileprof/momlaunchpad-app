/// Rolling cache window for the home welcome message.
class WelcomeCache {
  WelcomeCache._();

  static const maxAge = Duration(days: 7);

  /// True when [cacheDate] is less than 7 days old.
  static bool isFresh(DateTime cacheDate, [DateTime? now]) {
    final anchor = (now ?? DateTime.now()).toUtc();
    final cached = cacheDate.toUtc();
    return anchor.difference(cached) < maxAge;
  }
}
