import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/welcome_message.dart';
import '../services/api_service.dart';
import '../utils/welcome_cache.dart';
import 'service_providers.dart';

const _welcomePrefsKey = 'welcome_message_v1';

class WelcomeState {
  final WelcomeMessage? message;
  final bool isLoading;
  final String? error;

  const WelcomeState({
    this.message,
    this.isLoading = false,
    this.error,
  });

  bool get hasFreshMessage {
    final msg = message;
    if (msg == null) return false;
    return WelcomeCache.isFresh(msg.cacheDate);
  }

  WelcomeState copyWith({
    WelcomeMessage? message,
    bool? isLoading,
    String? error,
  }) {
    return WelcomeState(
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WelcomeNotifier extends Notifier<WelcomeState> {
  late final ApiService _apiService;
  bool _fetchInProgress = false;

  @override
  WelcomeState build() {
    _apiService = ref.read(apiServiceProvider);
    Future.microtask(_restoreFromDisk);
    return const WelcomeState(isLoading: false);
  }

  /// Called when Home loads: show stored message, fetch only if missing or >7 days old.
  Future<void> ensureFreshForHome() async {
    if (state.message == null) {
      await _restoreFromDisk();
    }
    if (state.hasFreshMessage || _fetchInProgress) return;
    await _fetch(showLoadingSpinner: state.message == null);
  }

  Future<void> refreshWelcome() async {
    await _fetch(showLoadingSpinner: state.message == null);
  }

  /// After journey or personalization changes (server clears its cache).
  Future<void> refreshAfterPersonalizationChange() async {
    await _clearDiskCache();
    await _fetch(showLoadingSpinner: false);
  }

  Future<void> _restoreFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_welcomePrefsKey);
      if (raw == null) return;

      final message = WelcomeMessage.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      state = WelcomeState(message: message, isLoading: false);
    } catch (_) {
      // Ignore corrupt local cache.
    }
  }

  Future<void> _persistToDisk(WelcomeMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_welcomePrefsKey, jsonEncode(message.toJson()));
  }

  Future<void> _clearDiskCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomePrefsKey);
    state = const WelcomeState(isLoading: false);
  }

  Future<void> _fetch({required bool showLoadingSpinner}) async {
    if (_fetchInProgress) return;
    _fetchInProgress = true;

    if (showLoadingSpinner) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final message = await _apiService.getWelcomeMessage();
      state = WelcomeState(message: message, isLoading: false);
      await _persistToDisk(message);
    } on ApiException catch (e) {
      state = WelcomeState(
        message: state.message,
        isLoading: false,
        error: e.message,
      );
    } catch (_) {
      state = WelcomeState(
        message: state.message,
        isLoading: false,
        error: state.message == null ? 'Failed to load welcome message' : null,
      );
    } finally {
      _fetchInProgress = false;
    }
  }
}

/// Whether a profile update should regenerate the welcome on the server.
bool welcomeRelevantProfileChange(UserProfile? before, UserProfile after) {
  if (before == null) return true;
  return before.journeyStage != after.journeyStage ||
      before.pregnancyWeek != after.pregnancyWeek ||
      before.expectedDeliveryDate != after.expectedDeliveryDate ||
      before.babyBirthDate != after.babyBirthDate ||
      before.lossDate != after.lossDate ||
      before.primaryConcern != after.primaryConcern;
}

final welcomeProvider = NotifierProvider<WelcomeNotifier, WelcomeState>(
  WelcomeNotifier.new,
);

/// @deprecated Use [welcomeProvider] — kept for any stale imports during migration.
final welcomeMessageProvider = welcomeProvider;
