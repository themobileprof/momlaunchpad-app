import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community.dart';
import '../providers/community_provider.dart';
import '../screens/community_create_post_screen.dart';
import '../screens/community_post_detail_screen.dart';

CommunityComposeMode composeModeForFilter(CommunityFeedFilter filter) {
  return filter == CommunityFeedFilter.events
      ? CommunityComposeMode.event
      : CommunityComposeMode.post;
}

/// Opens compose for a post or event; [mode] defaults from the active feed filter.
Future<void> openCommunityCompose(
  BuildContext context,
  WidgetRef ref, {
  CommunityComposeMode? mode,
}) async {
  final effectiveMode =
      mode ?? composeModeForFilter(ref.read(communityProvider).filter);

  final post = await Navigator.push<CommunityPost>(
    context,
    MaterialPageRoute(
      builder: (_) => CommunityCreatePostScreen(mode: effectiveMode),
    ),
  );
  if (post == null || !context.mounted) return;

  if (effectiveMode == CommunityComposeMode.event) {
    ref.read(communityProvider.notifier).setFilter(CommunityFeedFilter.events);
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CommunityPostDetailScreen(postId: post.id),
    ),
  );
}
