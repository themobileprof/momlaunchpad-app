import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/conversation_provider.dart';
import '../providers/service_providers.dart';
import '../screens/chat_screen.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../widgets/premium_upsell_dialog.dart';

/// Opens a new chat seeded with a personalized community review.
Future<void> openCommunityThreadEvaluation(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
  String? replyId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  try {
    final result = await ref.read(apiServiceProvider).evaluateCommunityPostForMe(
          postId,
          replyId: replyId,
        );

    final source = replyId != null
        ? 'community_reply'
        : result.scope == 'post'
            ? 'community_post'
            : 'community_discussion';

    await ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.featureUsed,
      {
        AnalyticsParams.featureName: 'community_thread_evaluate',
        AnalyticsParams.source: source,
      },
    );

    await ref.read(conversationProvider.notifier).loadConversations();

    if (!context.mounted) return;
    await navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: result.conversationId,
          conversationTitle: result.title,
        ),
      ),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    if (e.isRateLimited) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => const PremiumUpsellDialog(
          featureName: 'AI chat',
        ),
      );
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (_) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not start a personalized review. Try again.'),
      ),
    );
  }
}

/// Review the full discussion, or the post alone when there are no replies yet.
class CommunityReviewDiscussionButton extends ConsumerStatefulWidget {
  const CommunityReviewDiscussionButton({
    super.key,
    required this.postId,
    required this.hasReplies,
  });

  final String postId;
  final bool hasReplies;

  @override
  ConsumerState<CommunityReviewDiscussionButton> createState() =>
      _CommunityReviewDiscussionButtonState();
}

class _CommunityReviewDiscussionButtonState
    extends ConsumerState<CommunityReviewDiscussionButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await openCommunityThreadEvaluation(
        context,
        ref,
        postId: widget.postId,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.hasReplies ? 'Review discussion' : 'Good for me?';
    return OutlinedButton.icon(
      onPressed: _loading ? null : _onPressed,
      icon: _loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              widget.hasReplies
                  ? Icons.forum_outlined
                  : Icons.health_and_safety_outlined,
            ),
      label: Text(label),
    );
  }
}

/// Evaluate a single reply recommendation in context of the original post.
class CommunityReplyGoodForMeButton extends ConsumerStatefulWidget {
  const CommunityReplyGoodForMeButton({
    super.key,
    required this.postId,
    required this.replyId,
  });

  final String postId;
  final String replyId;

  @override
  ConsumerState<CommunityReplyGoodForMeButton> createState() =>
      _CommunityReplyGoodForMeButtonState();
}

class _CommunityReplyGoodForMeButtonState
    extends ConsumerState<CommunityReplyGoodForMeButton> {
  bool _loading = false;

  Future<void> _onPressed() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await openCommunityThreadEvaluation(
        context,
        ref,
        postId: widget.postId,
        replyId: widget.replyId,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _loading ? null : _onPressed,
      icon: _loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.health_and_safety_outlined, size: 18),
      label: const Text('Good for me?'),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
