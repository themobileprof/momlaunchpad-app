import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/service_providers.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/community_post_card.dart';
import '../widgets/widgets.dart';
import 'community_create_post_screen.dart';
import 'community_notifications_screen.dart';
import 'community_onboarding_screen.dart';
import 'community_post_detail_screen.dart';

/// Primary compose actions — always visible above the feed (FAB is hidden by bottom nav).
class _CommunityComposeBar extends StatelessWidget {
  final CommunityFeedFilter filter;
  final VoidCallback onNewPost;
  final VoidCallback onCreateEvent;

  const _CommunityComposeBar({
    required this.filter,
    required this.onNewPost,
    required this.onCreateEvent,
  });

  @override
  Widget build(BuildContext context) {
    final eventsTab = filter == CommunityFeedFilter.events;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.spaceMD,
        0,
        AppSpacing.spaceMD,
        AppSpacing.spaceMD,
      ),
      child: Row(
        children: [
          Expanded(
            child: eventsTab
                ? OutlinedButton.icon(
                    onPressed: onNewPost,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('New post'),
                  )
                : FilledButton.icon(
                    onPressed: onNewPost,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('New post'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: AppColors.white,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.spaceSM),
          Expanded(
            child: eventsTab
                ? FilledButton.icon(
                    onPressed: onCreateEvent,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: const Text('Create event'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: AppColors.white,
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onCreateEvent,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: const Text('Create event'),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Main community tab: personalized local parenting feed.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(communityProvider.notifier).bootstrap();
    if (!mounted) return;
    final state = ref.read(communityProvider);
    if (state.needsOnboarding) {
      final completed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const CommunityOnboardingScreen()),
      );
      if (completed == true && mounted) {
        await ref.read(communityProvider.notifier).loadFeed(refresh: true);
      }
    }
  }

  Future<void> _openCompose(CommunityComposeMode mode) async {
    final post = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityCreatePostScreen(mode: mode),
      ),
    );
    if (post != null && mounted) {
      if (mode == CommunityComposeMode.event) {
        ref.read(communityProvider.notifier).setFilter(CommunityFeedFilter.events);
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityPostDetailScreen(postId: post.id),
        ),
      );
    }
  }

  void _openPost(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityPostDetailScreen(postId: postId)),
    );
  }

  void _showPostMenu(String postId) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(apiServiceProvider).reportCommunityPost(
                      postId,
                      reason: 'inappropriate',
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide post'),
              onTap: () {
                Navigator.pop(context);
                ref.read(communityProvider.notifier).hidePost(postId);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(
        pageTitle: 'Community',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityNotificationsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(communityProvider.notifier).loadFeed(refresh: true),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(CommunityState state) {
    if (state.isLoading && state.posts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (state.needsOnboarding) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.groups_outlined,
            title: 'Set up your community profile',
            description: 'Add your location and interests to see local posts and events.',
            actionLabel: 'Get started',
            onAction: () async {
              final completed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CommunityOnboardingScreen()),
              );
              if (completed == true && mounted) {
                await ref.read(communityProvider.notifier).loadFeed(refresh: true);
              }
            },
          ),
        ],
      );
    }

    if (state.error != null && state.posts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          ErrorState(
            title: state.error!,
            onRetry: () => ref.read(communityProvider.notifier).loadFeed(refresh: true),
          ),
        ],
      );
    }

    final isEventsTab = state.filter == CommunityFeedFilter.events;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.spaceSM),
            child: CommunityFilterBar(
              selected: state.filter,
              onSelected: (f) => ref.read(communityProvider.notifier).setFilter(f),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _CommunityComposeBar(
            filter: state.filter,
            onNewPost: () => _openCompose(CommunityComposeMode.post),
            onCreateEvent: () => _openCompose(CommunityComposeMode.event),
          ),
        ),
        if (state.posts.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: isEventsTab ? Icons.event_outlined : Icons.forum_outlined,
              title: isEventsTab ? 'No local events yet' : 'No posts yet',
              description: isEventsTab
                  ? 'Create a meetup, class, or playdate for moms near you.'
                  : 'Share a question, tip, or update with the community.',
              actionLabel: isEventsTab ? 'Create event' : 'New post',
              onAction: () => _openCompose(
                isEventsTab ? CommunityComposeMode.event : CommunityComposeMode.post,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceMD,
              0,
              AppSpacing.spaceMD,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= state.posts.length) {
                    if (state.nextCursor != null && !state.isLoadingMore) {
                      ref.read(communityProvider.notifier).loadFeed();
                    }
                    return state.isLoadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(AppSpacing.spaceMD),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink();
                  }
                  final post = state.posts[index];
                  return CommunityPostCard(
                    post: post,
                    onTap: () => _openPost(post.id),
                    onLike: () => ref.read(communityProvider.notifier).togglePostLike(post.id),
                    onMore: () => _showPostMenu(post.id),
                  );
                },
                childCount: state.posts.length + (state.nextCursor != null ? 1 : 0),
              ),
            ),
          ),
      ],
    );
  }
}
