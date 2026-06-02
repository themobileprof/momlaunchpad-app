import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Renders external image URLs attached to a community post.
class CommunityPostImages extends StatelessWidget {
  final List<String> imageUrls;
  final bool compact;

  const CommunityPostImages({
    super.key,
    required this.imageUrls,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.spaceSM),
        child: _NetworkImageTile(url: imageUrls.first, height: compact ? 160 : 220),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spaceSM),
      child: SizedBox(
        height: compact ? 120 : 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.spaceSM),
          itemBuilder: (context, index) {
            return SizedBox(
              width: compact ? 120 : 160,
              child: _NetworkImageTile(
                url: imageUrls[index],
                height: compact ? 120 : 160,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NetworkImageTile extends StatelessWidget {
  final String url;
  final double height;

  const _NetworkImageTile({required this.url, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height,
          color: context.appPrimary.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: context.appInkSubtle),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            color: context.appPrimary.withValues(alpha: 0.08),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
