import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/community_post_images.dart';
import '../widgets/community_author_row.dart';
import '../widgets/simple_formatted_text.dart';
import '../widgets/widgets.dart';

class CommunityPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommunityPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState
    extends ConsumerState<CommunityPostDetailScreen> {
  CommunityPost? _post;
  CommunityEvent? _event;
  List<CommunityReply> _replies = [];
  bool _loading = true;
  String? _error;
  final _replyController = TextEditingController();
  bool _replyAnonymous = false;
  bool _submittingReply = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiServiceProvider);
      final results = await Future.wait([
        api.getCommunityPost(widget.postId),
        api.getCommunityReplies(widget.postId),
        api.getCommunityEvent(widget.postId),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as CommunityPost;
        _replies = results[1] as List<CommunityReply>;
        _event = results[2] as CommunityEvent?;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _submitReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _submittingReply = true);
    try {
      final reply = await ref.read(apiServiceProvider).createCommunityReply(
            postId: widget.postId,
            body: body,
            isAnonymous: _replyAnonymous,
          );
      if (!mounted) return;
      setState(() {
        _replies = [..._replies, reply];
        _replyController.clear();
        _submittingReply = false;
        if (_post != null) {
          _post = _post!.copyWith(replyCount: _post!.replyCount + 1);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submittingReply = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _togglePostLike() async {
    if (_post == null) return;
    final result = await ref.read(apiServiceProvider).toggleCommunityPostLike(_post!.id);
    setState(() {
      _post = _post!.copyWith(
        likeCount: result.likeCount,
        likedByMe: result.liked,
      );
    });
  }

  Future<void> _toggleEventInterest() async {
    if (_event == null) return;
    final result =
        await ref.read(apiServiceProvider).toggleEventInterest(_event!.id);
    setState(() {
      _event = CommunityEvent(
        id: _event!.id,
        postId: _event!.postId,
        title: _event!.title,
        description: _event!.description,
        venue: _event!.venue,
        startsAt: _event!.startsAt,
        endsAt: _event!.endsAt,
        country: _event!.country,
        stateProvince: _event!.stateProvince,
        city: _event!.city,
        interestedCount: result.count,
        interestedByMe: result.interested,
      );
    });
  }

  void _showPostActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report post'),
              onTap: () {
                Navigator.pop(context);
                _reportPost();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Hide post'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(communityProvider.notifier).hidePost(widget.postId);
                if (mounted) Navigator.pop(context);
              },
            ),
            if (_post?.author.id != null)
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('Block user'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(apiServiceProvider).blockCommunityUser(_post!.author.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User blocked')),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportPost() async {
    await ref.read(apiServiceProvider).reportCommunityPost(
          widget.postId,
          reason: 'inappropriate',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted. Thank you.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(
        pageTitle: 'Post',
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: _post == null ? null : _showPostActions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _post == null) {
      return ErrorState(
        title: _error ?? 'Post not found',
        onRetry: _load,
      );
    }

    final post = _post!;
    final dateFormat = DateFormat('EEE, MMM d · h:mm a');

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spaceMD,
              AppSpacing.spaceSM,
              AppSpacing.spaceMD,
              AppSpacing.spaceMD,
            ),
            children: [
              CommunityAuthorRow(
                author: post.author,
                timestamp: post.createdAt,
                subtitle: post.locationLabel.isNotEmpty ? post.locationLabel : null,
                badgeCatalog: ref.watch(communityProvider).badgeCatalog,
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              SimpleFormattedText(post.body),
              CommunityPostImages(imageUrls: post.imageUrls),
              const SizedBox(height: AppSpacing.spaceMD),
              Row(
                children: [
                  IconButton(
                    onPressed: _togglePostLike,
                    icon: Icon(
                      post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: post.likedByMe ? AppColors.primaryPurple : AppColors.textLight,
                    ),
                  ),
                  Text('${post.likeCount}'),
                ],
              ),
              if (_event != null) ...[
                const Divider(),
                Text('Event details', style: AppTypography.bodyTextMedium),
                const SizedBox(height: AppSpacing.spaceSM),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_event!.title, style: AppTypography.headingSmall),
                      const SizedBox(height: AppSpacing.spaceXS),
                      Text(
                        dateFormat.format(_event!.startsAt.toLocal()),
                        style: AppTypography.caption.copyWith(color: AppColors.textLight),
                      ),
                      if (_event!.venue != null) ...[
                        const SizedBox(height: AppSpacing.spaceXS),
                        Text(_event!.venue!, style: AppTypography.bodyText),
                      ],
                      if (_event!.description != null) ...[
                        const SizedBox(height: AppSpacing.spaceSM),
                        Text(_event!.description!),
                      ],
                      const SizedBox(height: AppSpacing.spaceMD),
                      OutlinedButton.icon(
                        onPressed: _toggleEventInterest,
                        icon: Icon(
                          _event!.interestedByMe
                              ? Icons.check_circle_rounded
                              : Icons.event_available_outlined,
                        ),
                        label: Text(
                          _event!.interestedByMe
                              ? 'Interested · ${_event!.interestedCount}'
                              : 'Mark interested · ${_event!.interestedCount}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.spaceLG),
              Text('Replies (${_replies.length})', style: AppTypography.bodyTextMedium),
              const SizedBox(height: AppSpacing.spaceSM),
              for (final reply in _replies)
                AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommunityAuthorRow(
                        author: reply.author,
                        timestamp: reply.createdAt,
                        badgeCatalog: ref.watch(communityProvider).badgeCatalog,
                      ),
                      const SizedBox(height: AppSpacing.spaceSM),
                      SimpleFormattedText(reply.body),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _buildReplyComposer(),
      ],
    );
  }

  Widget _buildReplyComposer() {
    return Material(
      color: context.appSurface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spaceMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _replyAnonymous,
                    onChanged: (v) => setState(() => _replyAnonymous = v ?? false),
                  ),
                  const Expanded(
                    child: Text('Reply as Anonymous Mom'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write a reply…',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceSM),
                  IconButton(
                    onPressed: _submittingReply ? null : _submitReply,
                    icon: _submittingReply
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
