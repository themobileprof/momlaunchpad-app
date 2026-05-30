import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/welcome_message.dart';
import 'service_providers.dart';

/// Loads the daily welcome message once per app session (backend caches per day).
final welcomeMessageProvider =
    FutureProvider.autoDispose<WelcomeMessage>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getWelcomeMessage();
});

/// Force-refresh today's welcome (e.g. pull-to-refresh on home).
final welcomeRefreshProvider = Provider<void Function()>((ref) {
  return () => ref.invalidate(welcomeMessageProvider);
});
