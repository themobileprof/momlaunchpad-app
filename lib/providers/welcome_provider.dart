import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/welcome_message.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

class WelcomeState {
  final WelcomeMessage? message;
  final bool isLoading;
  final String? error;

  const WelcomeState({
    this.message,
    this.isLoading = false,
    this.error,
  });

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

  @override
  WelcomeState build() {
    _apiService = ref.read(apiServiceProvider);
    Future.microtask(fetchWelcome);
    return const WelcomeState(isLoading: true);
  }

  Future<void> fetchWelcome() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final message = await _apiService.getWelcomeMessage();
      state = WelcomeState(message: message, isLoading: false);
    } on ApiException catch (e) {
      state = WelcomeState(isLoading: false, error: e.message);
    } catch (_) {
      state = const WelcomeState(
        isLoading: false,
        error: 'Failed to load welcome message',
      );
    }
  }

  /// Reload after profile or health data changes (backend invalidates daily cache on profile save).
  Future<void> refreshWelcome() async {
    state = const WelcomeState(isLoading: true);
    await fetchWelcome();
  }
}

final welcomeProvider = NotifierProvider<WelcomeNotifier, WelcomeState>(
  WelcomeNotifier.new,
);

/// @deprecated Use [welcomeProvider] — kept for any stale imports during migration.
final welcomeMessageProvider = welcomeProvider;
