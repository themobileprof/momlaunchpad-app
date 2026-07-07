import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_notification.dart';
import '../providers/notifications_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/widgets.dart';

/// "Rewards & updates" — the general notifications inbox (top-up codes,
/// store discounts, referral rewards, and system messages).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final hasUnread = state.unread > 0;

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(
        pageTitle: 'Rewards & updates',
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ErrorState(
        title: state.error!,
        onRetry: () => ref.read(notificationsProvider.notifier).load(),
      );
    }
    if (state.items.isEmpty) {
      return const EmptyState(
        icon: Icons.card_giftcard_outlined,
        title: 'No rewards or updates yet',
        description:
            'When you earn a reward or we have news for you, it shows up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spaceSM),
        itemBuilder: (context, index) =>
            _NotificationTile(notification: state.items[index]),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final UserNotification notification;

  const _NotificationTile({required this.notification});

  IconData get _icon {
    if (notification.type == 'referral_reward') return Icons.card_giftcard_rounded;
    switch (notification.rewardKind) {
      case 'topup_code':
        return Icons.phone_android_rounded;
      case 'store_discount':
        return Icons.local_offer_rounded;
      default:
        return notification.type == 'reward'
            ? Icons.card_giftcard_rounded
            : Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = notification.isUnread;
    return AppCard(
      onTap: unread
          ? () => ref
              .read(notificationsProvider.notifier)
              .markRead(notification.id)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: context.appPrimary, size: 22),
          ),
          const SizedBox(width: AppSpacing.spaceSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: AppTypography.bodyTextMedium),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: AppTypography.caption
                      .copyWith(color: context.appInkSubtle),
                ),
                if (notification.hasRewardDetail)
                  _RewardDetail(notification: notification),
                const SizedBox(height: 6),
                Text(
                  MaterialLocalizations.of(context)
                      .formatShortDate(notification.createdAt.toLocal()),
                  style: AppTypography.caption
                      .copyWith(color: context.appInkSubtle),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6, left: AppSpacing.spaceXS),
              decoration: BoxDecoration(
                color: context.appPrimary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardDetail extends StatelessWidget {
  final UserNotification notification;

  const _RewardDetail({required this.notification});

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = [notification.value, notification.provider]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');
    final code = notification.code;
    final expiresAt = notification.expiresAt;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.spaceSM),
      padding: const EdgeInsets.all(AppSpacing.spaceSM),
      decoration: BoxDecoration(
        color: context.appPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meta.isNotEmpty)
            Text(meta, style: AppTypography.bodyTextMedium),
          if (code != null) ...[
            if (meta.isNotEmpty) const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: AppTypography.bodyTextMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyCode(context, code),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ],
          if (expiresAt != null)
            Text(
              'Expires ${MaterialLocalizations.of(context).formatShortDate(expiresAt.toLocal())}',
              style: AppTypography.caption.copyWith(color: context.appInkSubtle),
            ),
        ],
      ),
    );
  }
}
