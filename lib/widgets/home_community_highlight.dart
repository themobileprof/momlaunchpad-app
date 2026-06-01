import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community.dart';
import '../providers/home_community_preview_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../screens/community_post_detail_screen.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';
import 'glass_container.dart';
import 'gradient_button.dart';

/// Home dashboard card summarizing nearby community activity from existing feed data.
class HomeCommunityHighlight extends ConsumerWidget {
  const HomeCommunityHighlight({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final previewState = ref.watch(homeCommunityPreviewProvider);
    final preview = previewState.preview;

    if (previewState.isLoading && preview == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
        child: SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (preview == null) {
      return const SizedBox.shrink();
    }

    if (preview.needsOnboarding) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
        child: _JoinCommunityCard(
          locationLabel: preview.locationLabel,
          onTap: () => ref.read(homeTabRequestProvider.notifier).openTab(
                communityTabIndex,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
      child: _NearbyPulseCard(
        preview: preview,
        onOpenCommunity: () => ref.read(homeTabRequestProvider.notifier).openTab(
              communityTabIndex,
            ),
        onOpenPost: (postId) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityPostDetailScreen(postId: postId),
          ),
        ),
      ),
    );
  }
}

class _JoinCommunityCard extends StatelessWidget {
  final String? locationLabel;
  final VoidCallback onTap;

  const _JoinCommunityCard({
    required this.locationLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.92,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: context.appPrimary, size: 22),
              const SizedBox(width: AppSpacing.spaceSM),
              Expanded(
                child: Text(
                  'Moms near you',
                  style: AppTypography.bodyTextMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            locationLabel != null
                ? 'Connect with moms around $locationLabel — share tips, questions, and local meetups.'
                : 'Set up your community profile to see local posts and events from other moms.',
            style: AppTypography.bodyText.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.spaceMD),
          GradientButton(
            label: 'Explore community',
            icon: Icons.arrow_forward_rounded,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _NearbyPulseCard extends StatelessWidget {
  final HomeCommunityPreview preview;
  final VoidCallback onOpenCommunity;
  final ValueChanged<String> onOpenPost;

  const _NearbyPulseCard({
    required this.preview,
    required this.onOpenCommunity,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    final spotlight = preview.spotlightPost;
    final featuredEvent = preview.featuredEventPost;

    return GlassContainer(
      opacity: 0.92,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: context.appPrimary, size: 22),
              const SizedBox(width: AppSpacing.spaceSM),
              Expanded(
                child: Text(
                  preview.locationLabel != null
                      ? 'Near ${preview.locationLabel}'
                      : 'Community near you',
                  style: AppTypography.bodyTextMedium,
                ),
              ),
              TextButton(
                onPressed: onOpenCommunity,
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Wrap(
            spacing: AppSpacing.spaceSM,
            runSpacing: AppSpacing.spaceSM,
            children: [
              if (preview.nearbyPostCount > 0)
                _StatChip(
                  icon: Icons.forum_outlined,
                  label: _postCountLabel(preview.nearbyPostCount),
                ),
              if (preview.nearbyEventCount > 0)
                _StatChip(
                  icon: Icons.event_outlined,
                  label: _eventCountLabel(preview.nearbyEventCount),
                ),
              if (preview.totalNearbyEngagement > 0)
                _StatChip(
                  icon: Icons.favorite_outline_rounded,
                  label: '${preview.totalNearbyEngagement} reactions nearby',
                ),
            ],
          ),
          if (spotlight != null) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            _HighlightTile(
              title: spotlight.isEvent ? 'Upcoming local event' : 'Trending nearby',
              body: spotlight.body,
              meta: _spotlightMeta(spotlight),
              onTap: () => onOpenPost(spotlight.id),
            ),
          ] else if (featuredEvent != null) ...[
            const SizedBox(height: AppSpacing.spaceMD),
            _HighlightTile(
              title: 'Next local event',
              body: featuredEvent.body,
              meta: _spotlightMeta(featuredEvent),
              onTap: () => onOpenPost(featuredEvent.id),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.spaceMD),
            Text(
              'Be the first to post or host a meetup in your area.',
              style: AppTypography.bodyText.copyWith(
                color: AppColors.textLight,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _postCountLabel(int count) =>
      count == 1 ? '1 discussion nearby' : '$count discussions nearby';

  static String _eventCountLabel(int count) =>
      count == 1 ? '1 upcoming event' : '$count upcoming events';

  static String _spotlightMeta(CommunityPost post) {
    final author = post.isAnonymous ? 'Anonymous mom' : post.author.displayName;
    final reactions = post.likeCount + post.replyCount;
    if (reactions == 0) return author;
    final reactionLabel = reactions == 1 ? '1 reaction' : '$reactions reactions';
    return '$author · $reactionLabel';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceSM,
        vertical: AppSpacing.spaceXS,
      ),
      decoration: BoxDecoration(
        color: context.appPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: context.appPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final String title;
  final String body;
  final String meta;
  final VoidCallback onTap;

  const _HighlightTile({
    required this.title,
    required this.body,
    required this.meta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.spaceXS),
          Text(
            _truncate(body, 140),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyText.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.spaceSM),
          Text(
            meta,
            style: AppTypography.caption.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  static String _truncate(String text, int maxChars) {
    final trimmed = text.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars).trim()}…';
  }
}
