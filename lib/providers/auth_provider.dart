import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/google_sign_in_errors.dart';
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
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
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
    return s.contains('Failed host lookup') ||
        s.contains('Connection refused') ||
        s.contains('SocketException') ||
        s.contains('ClientException') ||
        s.contains('Network is unreachable');
  }

  static String _connectionErrorMessage() {
    final host = Uri.tryParse(AppConfig.baseUrl)?.host ?? '';
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'Cannot reach the API at localhost from this device. '
          'Use http://10.0.2.2:8080 on the Android emulator, or your '
          'computer\'s LAN IP in .env for a physical device.';
    }
    return 'Unable to connect to the server. Check your network and try again.';
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
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
      final hasToken = await _storageService.isLoggedIn();
      if (!hasToken) {
        state = AuthState(isLoggedIn: false);
        return;
      }

      try {
        final authResponse = await _apiService.refreshSession();
        state = AuthState(
          user: authResponse.user,
          isLoggedIn: true,
        );
        return;
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          await _storageService.clearAll();
          state = AuthState(isLoggedIn: false);
          return;
        }
      } catch (e) {
        debugPrint('Session refresh error: $e');
      }

      final cachedUser = await _storageService.getCachedUser();
      if (cachedUser != null) {
        state = AuthState(user: cachedUser, isLoggedIn: true);
        return;
      }

      state = AuthState(isLoggedIn: false);
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Silently extend the session when the app returns to the foreground.
  Future<void> refreshSessionIfLoggedIn() async {
    if (!state.isLoggedIn) return;
    if (!await _storageService.isLoggedIn()) return;

    try {
      final authResponse = await _apiService.refreshSession();
      state = state.copyWith(user: authResponse.user);
    } catch (e) {
      debugPrint('Background session refresh: $e');
    }
  }

  /// Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final authResponse = await _apiService.register(
        email: email,
        password: password,
        name: name,
        referralCode: referralCode,
      );
      await _storageService.clearPendingReferralCode();
      
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
          ? _connectionErrorMessage()
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

    state = state.copyWith(isLoading: true, clearError: true);
    
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
          ? _connectionErrorMessage()
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

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        debugPrint('Google sign-out before sign-in (ignored): $e');
      }

      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw StateError('Failed to get ID token from Google');
      }

      final pendingReferral =
          await _storageService.getPendingReferralCode();
      final authResponse = await _apiService.googleSignIn(
        idToken: googleAuth.idToken!,
        referralCode: pendingReferral,
      );
      await _storageService.clearPendingReferralCode();

      state = AuthState(
        user: authResponse.user,
        isLoggedIn: true,
        isLoading: false,
      );
    } on ApiException catch (e) {
      final errorMsg = e.statusCode == 503
          ? e.message
          : e.statusCode == 401
              ? 'Server rejected the Google sign-in token. If this persists, '
                  'confirm the API has GOOGLE_ALLOWED_CLIENT_IDS configured.'
              : e.message;
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      debugPrint('Google Sign-In API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = googleSignInErrorMessage(
        e,
        apiBaseUrl: AppConfig.baseUrl,
      );
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
