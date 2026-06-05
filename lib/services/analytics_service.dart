import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../firebase_options.dart';

/// Product analytics (GA4 via Firebase). No-ops when disabled or not configured.
abstract class AnalyticsService {
  Future<void> init();
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
  Future<void> logEvent(String name, [Map<String, Object>? params]);
  Future<void> logScreen(String screenName);
  Future<void> logAppOpen();
}

class NoOpAnalyticsService implements AnalyticsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {}

  @override
  Future<void> logScreen(String screenName) async {}

  @override
  Future<void> logAppOpen() async {}
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalytics? _analytics;
  DateTime? _lastAppOpen;

  @override
  Future<void> init() async {
    if (!AppConfig.analyticsEnabled || !DefaultFirebaseOptions.enabled) {
      debugPrint('Analytics: disabled or Firebase not configured');
      return;
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      debugPrint('Analytics: Firebase GA4 initialized');
    } catch (e, st) {
      debugPrint('Analytics: Firebase init failed: $e\n$st');
      _analytics = null;
    }
  }

  FirebaseAnalytics? get _a => _analytics;

  @override
  Future<void> setUserId(String? userId) async {
    await _a?.setUserId(id: userId);
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    if (value == null || value.isEmpty) return;
    await _a?.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    await _a?.logEvent(name: name, parameters: params);
  }

  @override
  Future<void> logScreen(String screenName) async {
    await _a?.logScreenView(screenName: screenName);
  }

  @override
  Future<void> logAppOpen() async {
    final now = DateTime.now();
    if (_lastAppOpen != null &&
        now.difference(_lastAppOpen!) < const Duration(minutes: 30)) {
      return;
    }
    _lastAppOpen = now;
    await logEvent(AnalyticsEvents.appOpen);
  }
}

/// GA4 event and parameter names — keep stable for dashboards.
class AnalyticsEvents {
  static const appOpen = 'app_open';
  static const loginSuccess = 'login_success';
  static const signupComplete = 'signup_complete';
  static const logout = 'logout';
  static const screenView = 'screen_view';
  static const featureUsed = 'feature_used';
  static const tabSelected = 'tab_selected';
  static const aiQuestionSent = 'ai_question_sent';
  static const testimonialSubmitted = 'testimonial_submitted';
}

class AnalyticsParams {
  static const method = 'method';
  static const featureName = 'feature_name';
  static const tabName = 'tab_name';
  static const screenName = 'screen_name';
  static const topicBucket = 'topic_bucket';
  static const intentCategory = 'intent_category';
  static const messageLengthBucket = 'message_length_bucket';
  static const rating = 'rating';
  static const hasWrittenFeedback = 'has_written_feedback';
  static const source = 'source';
}
