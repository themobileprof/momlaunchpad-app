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

  @override
  AuthState build() {
    _apiService = ref.read(apiServiceProvider);
    _storageService = ref.read(storageServiceProvider);
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
      print('Registration API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = e.toString().contains('Failed host lookup') || 
                       e.toString().contains('Connection refused')
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Registration failed. Please try again.';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      print('Registration error: $e');
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
      
      print('🔍 Login response - User name: ${authResponse.user.name}');
      print('🔍 Login response - User email: ${authResponse.user.email}');
      print('🔍 Login response - User ID: ${authResponse.user.id}');
      
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
      print('Login API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = e.toString().contains('Failed host lookup') || 
                       e.toString().contains('Connection refused')
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Login failed. Please check your credentials.';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      print('Login error: $e');
      rethrow;
    }
  }

  /// Google Sign-In
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out first to ensure account picker shows
      await googleSignIn.signOut();
      
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        state = state.copyWith(
          isLoading: false,
          error: 'Sign-in cancelled',
        );
        return;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }

      // Send ID token to backend
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
      print('Google Sign-In API error: ${e.message}');
      rethrow;
    } catch (e) {
      final errorMsg = e.toString().contains('Failed host lookup') || 
                       e.toString().contains('Connection refused')
          ? 'Unable to connect to server. Please check your internet connection.'
          : 'Google sign-in failed. Please try again.';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      print('Google Sign-In error: $e');
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
