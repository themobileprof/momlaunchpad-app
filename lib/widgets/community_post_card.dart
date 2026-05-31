import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'app_card.dart';
import 'community_author_row.dart';
import 'simple_formatted_text.dart';

class CommunityPostCard extends ConsumerWidget {
  final CommunityPost post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onMore;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeCatalog = ref.watch(communityProvider).badgeCatalog;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CommunityAuthorRow(
                  author: post.author,
                  timestamp: post.createdAt,
                  subtitle: post.locationLabel.isNotEmpty ? post.locationLabel : null,
                  badgeCatalog: badgeCatalog,
                ),
              ),
              if (onMore != null)
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  onPressed: onMore,
                  color: AppColors.textLight,
                ),
            ],
          ),
          if (post.isEvent) ...[
            const SizedBox(height: AppSpacing.spaceXS),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Local event',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.spaceSM),
          SimpleFormattedText(post.body),
          const SizedBox(height: AppSpacing.spaceMD),
          Row(
            children: [
              _ActionChip(
                icon: post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                label: '${post.likeCount}',
                active: post.likedByMe,
                onTap: onLike,
              ),
              const SizedBox(width: AppSpacing.spaceMD),
              _ActionChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: '${post.replyCount}',
                onTap: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryPurple : AppColors.textLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class CommunityFilterBar extends StatelessWidget {
  final CommunityFeedFilter selected;
  final ValueChanged<CommunityFeedFilter> onSelected;

  const CommunityFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceMD),
      child: Row(
        children: CommunityFeedFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.spaceSM),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onSelected(filter),
              selectedColor: AppColors.primaryPurple.withValues(alpha: 0.15),
              checkmarkColor: AppColors.primaryPurple,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryPurple : AppColors.textLight,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
