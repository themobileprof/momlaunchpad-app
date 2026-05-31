import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';
import 'welcome_provider.dart';

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
        final userChanged = previous?.user?.id != next.user?.id;
        final loggedIn = previous?.isLoggedIn != true;
        if (loggedIn || userChanged || previous == null) {
          loadProfile();
        }
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
      final message = e is ApiException ? e.message : 'Failed to load profile';
      state = ProfileState(
        isLoading: false,
        error: message,
      );
    }
  }

  Future<UserProfile> updateProfile(ProfileSavePayload payload) async {
    final previous = state.profile;
    final profile = await _apiService.updateProfile(payload);
    state = ProfileState(profile: profile, isLoading: false);
    await ref.read(authProvider.notifier).refreshUser();
    if (welcomeRelevantProfileChange(previous, profile)) {
      await ref.read(welcomeProvider.notifier).refreshAfterPersonalizationChange();
    }
    return profile;
  }

  Future<UserProfile> uploadProfilePhoto(String filePath) async {
    final profile = await _apiService.uploadProfilePhoto(filePath);
    state = ProfileState(profile: profile, isLoading: false);
    await ref.read(authProvider.notifier).refreshUser();
    return profile;
  }

  Future<UserProfile> deleteProfilePhoto() async {
    final profile = await _apiService.deleteProfilePhoto();
    state = ProfileState(profile: profile, isLoading: false);
    await ref.read(authProvider.notifier).refreshUser();
    return profile;
  }

  Future<UserProfile> completeOnboarding(ProfileSavePayload payload) async {
    final profile = await _apiService.completeOnboarding(payload);

    state = ProfileState(profile: profile, isLoading: false);
    await ref.read(authProvider.notifier).refreshUser();
    await ref.read(welcomeProvider.notifier).refreshAfterPersonalizationChange();
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
