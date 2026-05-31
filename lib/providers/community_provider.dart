import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../services/api_service.dart';
import 'service_providers.dart';

class CommunityState {
  final CommunityStatus? status;
  final List<CommunityInterestGroup> interestGroups;
  final List<CommunityCountryOption> countries;
  final CommunityBadgeCatalog badgeCatalog;
  final CommunityFeedFilter filter;
  final List<CommunityPost> posts;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const CommunityState({
    this.status,
    this.interestGroups = const [],
    this.countries = const [],
    this.badgeCatalog = const CommunityBadgeCatalog({}),
    this.filter = CommunityFeedFilter.forYou,
    this.posts = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  bool get needsOnboarding => status != null && !status!.onboardingCompleted;

  CommunityState copyWith({
    CommunityStatus? status,
    List<CommunityInterestGroup>? interestGroups,
    List<CommunityCountryOption>? countries,
    CommunityBadgeCatalog? badgeCatalog,
    CommunityFeedFilter? filter,
    List<CommunityPost>? posts,
    String? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return CommunityState(
      status: status ?? this.status,
      interestGroups: interestGroups ?? this.interestGroups,
      countries: countries ?? this.countries,
      badgeCatalog: badgeCatalog ?? this.badgeCatalog,
      filter: filter ?? this.filter,
      posts: posts ?? this.posts,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }
}

class CommunityNotifier extends Notifier<CommunityState> {
  late final ApiService _api;

  @override
  CommunityState build() {
    _api = ref.read(apiServiceProvider);
    return const CommunityState();
  }

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _api.getCommunityStatus(),
        _api.getCommunityInterests(),
        _api.getCommunityCountries(),
        _api.getCommunityBadgeCatalog(),
      ]);
      state = state.copyWith(
        status: results[0] as CommunityStatus,
        interestGroups: results[1] as List<CommunityInterestGroup>,
        countries: results[2] as List<CommunityCountryOption>,
        badgeCatalog: results[3] as CommunityBadgeCatalog,
        isLoading: false,
      );
      if (!state.needsOnboarding) {
        await loadFeed(refresh: true);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load community');
    }
  }

  Future<bool> completeOnboarding({
    required String countryCode,
    required String stateProvince,
    required String city,
    required List<String> interests,
  }) async {
    try {
      final status = await _api.completeCommunityOnboarding(
        countryCode: countryCode,
        stateProvince: stateProvince,
        city: city,
        interests: interests,
      );
      state = state.copyWith(status: status);
      await loadFeed(refresh: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<void> setFilter(CommunityFeedFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(filter: filter);
    await loadFeed(refresh: true);
  }

  Future<void> loadFeed({bool refresh = false}) async {
    if (state.needsOnboarding) return;
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, posts: [], nextCursor: null);
    } else {
      if (state.isLoadingMore || state.nextCursor == null) return;
      state = state.copyWith(isLoadingMore: true, error: null);
    }

    try {
      final page = await _api.getCommunityFeed(
        filter: state.filter,
        cursor: refresh ? null : state.nextCursor,
      );
      state = state.copyWith(
        posts: refresh ? page.posts : [...state.posts, ...page.posts],
        nextCursor: page.nextCursor,
        isLoading: false,
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e.message);
    }
  }

  Future<void> togglePostLike(String postId) async {
    try {
      final result = await _api.toggleCommunityPostLike(postId);
      state = state.copyWith(
        posts: state.posts.map((p) {
          if (p.id != postId) return p;
          return CommunityPost(
            id: p.id,
            body: p.body,
            isAnonymous: p.isAnonymous,
            category: p.category,
            scope: p.scope,
            medicalRelevance: p.medicalRelevance,
            isEvent: p.isEvent,
            likeCount: result.likeCount,
            replyCount: p.replyCount,
            likedByMe: result.liked,
            country: p.country,
            stateProvince: p.stateProvince,
            city: p.city,
            createdAt: p.createdAt,
            author: p.author,
          );
        }).toList(),
      );
    } catch (_) {}
  }

  Future<CommunityPost?> createPost(CreatePostPayload payload) async {
    try {
      final post = await _api.createCommunityPost(payload);
      if (state.filter == CommunityFeedFilter.myPosts ||
          state.filter == CommunityFeedFilter.forYou) {
        state = state.copyWith(posts: [post, ...state.posts]);
      }
      return post;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    }
  }

  Future<void> hidePost(String postId) async {
    await _api.hideCommunityPost(postId);
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
  }
}

final communityProvider =
    NotifierProvider<CommunityNotifier, CommunityState>(CommunityNotifier.new);
