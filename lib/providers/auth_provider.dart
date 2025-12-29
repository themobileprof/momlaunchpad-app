import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';

/// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

/// Auth provider (Notifier)
class AuthNotifier extends Notifier<AuthState> {
  late final ApiService _apiService;
  late final StorageService _storageService;

  @override
  AuthState build() {
    _apiService = ref.read(apiServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    _checkLoginStatus();
    return AuthState();
  }

  /// Check if user is logged in on app start
  Future<void> _checkLoginStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final isLoggedIn = await _storageService.isLoggedIn();
      if (isLoggedIn) {
        final user = await _apiService.getCurrentUser();
        state = AuthState(user: user, isLoggedIn: true);
      } else {
        state = AuthState(isLoggedIn: false);
      }
    } catch (e) {
      print('Login check error: $e');
      state = AuthState(isLoggedIn: false);
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String language,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authResponse = await _apiService.register(
        email: email,
        password: password,
        name: name,
        language: language,
      );
      
      state = AuthState(
        user: authResponse.user,
        isLoggedIn: true,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
      rethrow;
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final authResponse = await _apiService.login(
        email: email,
        password: password,
      );
      
      state = AuthState(
        user: authResponse.user,
        isLoggedIn: true,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Please check your credentials.',
      );
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _storageService.clearAll();
    state = AuthState(isLoggedIn: false);
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}

/// Auth provider instance
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for login status
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});
