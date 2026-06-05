import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

/// Logs GA4 screen_view on route changes.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _log(newRoute);
  }

  void _log(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _analytics.logScreen(name);
    _analytics.logEvent(
      AnalyticsEvents.screenView,
      {AnalyticsParams.screenName: name},
    );
  }
}
