import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

/// Client-derived community snapshot for the home dashboard (no new backend metrics).
class HomeCommunityPreview {
  final bool needsOnboarding;
  final String? locationLabel;
  final CommunityPost? spotlightPost;
  final int nearbyPostCount;
  final int nearbyEventCount;
  final int totalNearbyEngagement;
  final CommunityPost? featuredEventPost;

  const HomeCommunityPreview({
    required this.needsOnboarding,
    this.locationLabel,
    this.spotlightPost,
    this.nearbyPostCount = 0,
    this.nearbyEventCount = 0,
    this.totalNearbyEngagement = 0,
    this.featuredEventPost,
  });

  static const loading = HomeCommunityPreview(needsOnboarding: false);
  static const hidden = HomeCommunityPreview(needsOnboarding: true);
}

class HomeCommunityPreviewState {
  final HomeCommunityPreview? preview;
  final bool isLoading;
  final String? error;

  const HomeCommunityPreviewState({
    this.preview,
    this.isLoading = false,
    this.error,
  });

  HomeCommunityPreviewState copyWith({
    HomeCommunityPreview? preview,
    bool? isLoading,
    String? error,
  }) {
    return HomeCommunityPreviewState(
      preview: preview ?? this.preview,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class HomeCommunityPreviewNotifier extends Notifier<HomeCommunityPreviewState> {
  late final ApiService _api;

  @override
  HomeCommunityPreviewState build() {
    _api = ref.read(apiServiceProvider);
    return const HomeCommunityPreviewState();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final status = await _api.getCommunityStatus();
      if (!status.onboardingCompleted) {
        state = HomeCommunityPreviewState(
          preview: HomeCommunityPreview(
            needsOnboarding: true,
            locationLabel: _locationLabel(status),
          ),
          isLoading: false,
        );
        return;
      }

      late CommunityFeedPage nearby;
      late CommunityFeedPage events;
      await Future.wait([
        _api
            .getCommunityFeed(filter: CommunityFeedFilter.nearby, limit: 12)
            .then((page) => nearby = page),
        _api
            .getCommunityFeed(filter: CommunityFeedFilter.events, limit: 5)
            .then((page) => events = page),
      ]);

      CommunityPost? spotlight;
      var engagement = 0;
      for (final post in nearby.posts) {
        engagement += post.likeCount + post.replyCount;
        if (spotlight == null ||
            _engagement(post) > _engagement(spotlight)) {
          spotlight = post;
        }
      }

      state = HomeCommunityPreviewState(
        preview: HomeCommunityPreview(
          needsOnboarding: false,
          locationLabel: _locationLabel(status),
          spotlightPost: spotlight,
          nearbyPostCount: nearby.posts.where((p) => !p.isEvent).length,
          nearbyEventCount: events.posts.length,
          totalNearbyEngagement: engagement,
          featuredEventPost:
              events.posts.isNotEmpty ? events.posts.first : null,
        ),
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load community highlights',
      );
    }
  }

  static int _engagement(CommunityPost post) =>
      post.likeCount + (post.replyCount * 2);

  static String? _locationLabel(CommunityStatus status) {
    final parts = [status.city, status.stateProvince, status.country]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

final homeCommunityPreviewProvider = NotifierProvider<
    HomeCommunityPreviewNotifier, HomeCommunityPreviewState>(
  HomeCommunityPreviewNotifier.new,
);
