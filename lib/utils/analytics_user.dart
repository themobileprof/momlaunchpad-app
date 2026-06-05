import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_providers.dart';
import '../services/analytics_service.dart';

/// Binds GA4 user id and auth lifecycle events.
Future<void> bindAnalyticsUser(
  Ref ref, {
  required String userId,
  String? loginMethod,
  bool isSignup = false,
}) async {
  final analytics = ref.read(analyticsServiceProvider);
  await analytics.setUserId(userId);
  if (isSignup) {
    await analytics.logEvent(AnalyticsEvents.signupComplete, {
      if (loginMethod != null) AnalyticsParams.method: loginMethod,
    });
  } else if (loginMethod != null) {
    await analytics.logEvent(AnalyticsEvents.loginSuccess, {
      AnalyticsParams.method: loginMethod,
    });
  }
}

Future<void> clearAnalyticsUser(Ref ref) async {
  final analytics = ref.read(analyticsServiceProvider);
  await analytics.logEvent(AnalyticsEvents.logout);
  await analytics.setUserId(null);
}
