import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
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
  late final GoogleSignIn _googleSignIn;

  static bool _looksLikeConnectionFailure(Object e) {
    final s = e.toString();
    return s.contains('Failed host lookup') || s.contains('Connection refused');
  }

  @override
  AuthState build() {
    _apiService = ref.read(apiServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    _googleSignIn = ref.read(googleSignInProvider);
    // Check login status asynchronously after initialization
    Future.microtask(() => _checkLoginStatus());
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
      debugPrint('Login check error: $e');
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
      debugPrint('Registration API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = _looksLikeConnectionFailure(e)
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Registration failed. Please try again.';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;

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
      debugPrint('Login API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = _looksLikeConnectionFailure(e)
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Login failed. Please check your credentials.';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  /// Google Sign-In (separate from email/password; same account if email matches)
  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _googleSignIn.signOut();

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Sign-in cancelled',
        );
        return;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      final authResponse = await _apiService.googleSignIn(
        idToken: googleAuth.idToken!,
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
      debugPrint('Google Sign-In API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = _looksLikeConnectionFailure(e)
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Google sign-in failed. Please try again.';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign-out error: $e');
    }

    await _storageService.clearAll();
    state = AuthState(isLoggedIn: false);
  }

  /// Refresh user data
  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (e) {
      debugPrint('Error refreshing user: $e');
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
