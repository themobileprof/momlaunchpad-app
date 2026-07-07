import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/google_calendar_sync_service.dart';
import 'service_providers.dart';

const _enabledPrefKey = 'google_calendar_sync_enabled';

class GoogleCalendarSyncState {
  final bool enabled;
  final bool isLoading;
  final String? error;

  const GoogleCalendarSyncState({
    this.enabled = false,
    this.isLoading = false,
    this.error,
  });

  GoogleCalendarSyncState copyWith({
    bool? enabled,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return GoogleCalendarSyncState(
      enabled: enabled ?? this.enabled,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GoogleCalendarSyncNotifier extends Notifier<GoogleCalendarSyncState> {
  @override
  GoogleCalendarSyncState build() {
    Future.microtask(_loadEnabled);
    return const GoogleCalendarSyncState(isLoading: true);
  }

  Future<void> _loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    state = GoogleCalendarSyncState(
      enabled: prefs.getBool(_enabledPrefKey) ?? false,
    );
  }

  Future<bool> enable() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authorized =
          await ref.read(googleCalendarSyncServiceProvider).ensureAuthorized();
      if (!authorized) {
        state = state.copyWith(
          isLoading: false,
          enabled: false,
          error: 'Google Calendar access was not granted',
        );
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledPrefKey, true);
      state = state.copyWith(enabled: true, isLoading: false);
      return true;
    } on GoogleCalendarSyncException catch (e) {
      state = state.copyWith(isLoading: false, enabled: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        enabled: false,
        error: 'Could not connect Google Calendar',
      );
      return false;
    }
  }

  Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPrefKey, false);
    state = state.copyWith(enabled: false, clearError: true);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final googleCalendarSyncServiceProvider =
    Provider<GoogleCalendarSyncService>((ref) {
  return GoogleCalendarSyncService(ref.watch(googleSignInProvider));
});

final googleCalendarSyncProvider =
    NotifierProvider<GoogleCalendarSyncNotifier, GoogleCalendarSyncState>(
  GoogleCalendarSyncNotifier.new,
);
