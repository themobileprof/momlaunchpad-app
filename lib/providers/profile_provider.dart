import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  bool get needsOnboarding =>
      profile != null && !profile!.onboardingCompleted;

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  late final ApiService _apiService;

  @override
  ProfileState build() {
    _apiService = ref.read(apiServiceProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.isLoggedIn && next.user != null) {
        loadProfile();
      } else if (!next.isLoggedIn) {
        state = const ProfileState();
      }
    }, fireImmediately: true);

    return const ProfileState(isLoading: true);
  }

  Future<void> loadProfile() async {
    if (!ref.read(authProvider).isLoggedIn) {
      state = const ProfileState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _apiService.getUserProfile();
      state = ProfileState(profile: profile, isLoading: false);
    } catch (e) {
      debugPrint('Profile load error: $e');
      state = ProfileState(
        isLoading: false,
        error: 'Failed to load profile',
      );
    }
  }

  Future<UserProfile> updateProfile(ProfileSavePayload payload) async {
    final profile = await _apiService.updateProfile(payload);
    state = ProfileState(profile: profile, isLoading: false);
    await ref.read(authProvider.notifier).refreshUser();
    return profile;
  }

  Future<UserProfile> completeOnboarding({
    required String name,
    required String language,
    required int pregnancyWeek,
    required bool isFirstPregnancy,
    String? primaryConcern,
  }) async {
    final profile = await _apiService.completeOnboarding(
      name: name,
      language: language,
      pregnancyWeek: pregnancyWeek,
      isFirstPregnancy: isFirstPregnancy,
      primaryConcern: primaryConcern,
    );

    state = ProfileState(profile: profile, isLoading: false);
    await ref.read(authProvider.notifier).refreshUser();
    return profile;
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

final needsOnboardingProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  final profile = ref.watch(profileProvider);

  if (!auth.isLoggedIn) return false;
  if (profile.isLoading) return false;
  if (profile.profile == null) return false;
  return !profile.profile!.onboardingCompleted;
});
