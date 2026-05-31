import 'package:flutter/material.dart';
import '../models/community.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

class CommunityBadgeChip extends StatelessWidget {
  final String badgeType;

  const CommunityBadgeChip({super.key, required this.badgeType});

  @override
  Widget build(BuildContext context) {
    final label = communityBadgeLabels[badgeType] ?? badgeType;
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.spaceXS),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class CommunityAuthorRow extends StatelessWidget {
  final CommunityAuthor author;
  final DateTime? timestamp;
  final String? subtitle;

  const CommunityAuthorRow({
    super.key,
    required this.author,
    this.timestamp,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.15),
          backgroundImage:
              author.photoUrl != null ? NetworkImage(author.photoUrl!) : null,
          child: author.photoUrl == null
              ? Text(
                  author.displayName.isNotEmpty
                      ? author.displayName[0].toUpperCase()
                      : 'M',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.spaceSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      author.displayName,
                      style: AppTypography.bodyTextMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...author.badges.map((b) => CommunityBadgeChip(badgeType: b)),
                ],
              ),
              if (subtitle != null || timestamp != null)
                Text(
                  [
                    if (subtitle != null) subtitle!,
                    if (timestamp != null) _formatTime(timestamp!),
                  ].join(' · '),
                  style: AppTypography.caption.copyWith(color: AppColors.textLight),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.month}/${time.day}';
  }
}
