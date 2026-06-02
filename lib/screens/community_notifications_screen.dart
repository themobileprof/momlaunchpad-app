import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community.dart';
import '../providers/service_providers.dart';
import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';
import 'community_post_detail_screen.dart';

class CommunityNotificationsScreen extends ConsumerStatefulWidget {
  const CommunityNotificationsScreen({super.key});

  @override
  ConsumerState<CommunityNotificationsScreen> createState() =>
      _CommunityNotificationsScreenState();
}

class _CommunityNotificationsScreenState
    extends ConsumerState<CommunityNotificationsScreen> {
  List<CommunityNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(apiServiceProvider).getCommunityNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _openNotification(CommunityNotification notification) async {
    if (notification.readAt == null) {
      await ref.read(apiServiceProvider).markCommunityNotificationRead(notification.id);
    }
    final postId = notification.payload['post_id']?.toString();
    if (postId != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CommunityPostDetailScreen(postId: postId)),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(pageTitle: 'Notifications'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(title: _error!, onRetry: _load);
    }
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'No notifications yet',
        description: 'Replies, likes, follows, and event reminders appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spaceMD),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spaceSM),
      itemBuilder: (context, index) {
        final item = _items[index];
        final unread = item.readAt == null;
        return AppCard(
          onTap: () => _openNotification(item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: AppSpacing.spaceSM),
                decoration: BoxDecoration(
                  color: unread ? context.appPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTypography.bodyTextMedium),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: AppTypography.caption.copyWith(color: context.appInkSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
