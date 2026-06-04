import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/user_profile.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../providers/conversation_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/journey_helpers.dart';
import '../utils/conversation_list_utils.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).loadConversations();
    });
  }

  Future<void> _openChat(Conversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation.id,
          conversationTitle: conversation.title,
        ),
      ),
    );
    if (mounted) {
      ref.read(conversationProvider.notifier).loadConversations();
    }
  }

  Future<void> _createNewConversation() async {
    final conversation =
        await ref.read(conversationProvider.notifier).createConversation();
    if (conversation != null && mounted) {
      await _openChat(conversation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);
    final profile = ref.watch(profileProvider).profile;

    return Scaffold(
      backgroundColor: context.appCanvas,
      appBar: MomAppBar(
        pageTitle: 'Chat',
        actions: [
          TextButton.icon(
            onPressed: state.isLoading ? null : _createNewConversation,
            icon: Icon(Icons.add_rounded, size: 20),
            label: const Text('New topic'),
          ),
        ],
      ),
      body: _buildBody(state, profile),
    );
  }

  Widget _buildBody(ConversationState state, UserProfile? profile) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.conversations.isEmpty) {
      return EmptyState(
        icon: Icons.auto_awesome_rounded,
        title: JourneyHelpers.chatEmptyTitle(profile),
        description: JourneyHelpers.chatEmptyDescription(profile),
        actionLabel: 'Start chatting',
        onAction: _createNewConversation,
      );
    }

    final sections = groupConversationsByDate(state.conversations);
    final mostRecent = state.conversations.reduce(
      (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );
    final listSections = sections
        .map(
          (section) => ConversationSection(
            section: section.section,
            label: section.label,
            conversations: section.conversations
                .where((c) => c.id != mostRecent.id)
                .toList(),
          ),
        )
        .where((section) => section.conversations.isNotEmpty)
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationProvider.notifier).loadConversations(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceMD,
          AppSpacing.spaceSM,
          AppSpacing.spaceMD,
          120,
        ),
        children: [
          _ContinueChatCard(
            conversation: mostRecent,
            onTap: () => _openChat(mostRecent),
          ),
          const SizedBox(height: AppSpacing.spaceLG),
          for (final section in listSections) ...[
            _SectionHeader(label: section.label),
            const SizedBox(height: AppSpacing.spaceSM),
            for (final conversation in section.conversations)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                child: _ConversationTile(
                  conversation: conversation,
                  onTap: () => _openChat(conversation),
                  onTogglePin: () => _togglePin(conversation),
                  onDelete: () => _deleteConversation(conversation),
                ),
              ),
            const SizedBox(height: AppSpacing.spaceMD),
          ],
        ],
      ),
    );
  }

  Future<void> _togglePin(Conversation conversation) async {
    try {
      await ref.read(conversationProvider.notifier).setConversationPinned(
            conversation.id,
            !conversation.isStarred,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update pin')),
        );
      }
    }
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    final confirm = await _confirmDelete(
      context,
      conversationDisplayTitle(conversation.title),
    );
    if (confirm == true && mounted) {
      await ref
          .read(conversationProvider.notifier)
          .deleteConversation(conversation.id);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ContinueChatCard extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ContinueChatCard({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.spaceLG),
          decoration: BoxDecoration(
            color: context.appPrimary,
            borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: context.appPrimary.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spaceMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue chatting',
                          style: AppTypography.label.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          conversationDisplayTitle(conversation.title),
                          style: AppTypography.headingSmall.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              Text(
                conversationActivityLabel(conversation.updatedAt),
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: AppSpacing.spaceMD),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.radiusMedium),
                    ),
                  ),
                  icon: Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    'Open conversation',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.label.copyWith(color: context.appPrimary),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.spaceMD),
        decoration: BoxDecoration(
          color: AppColors.errorSoft,
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
              border: Border.all(
                color: context.appPrimary.withValues(alpha: 0.08),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceMD,
              vertical: AppSpacing.spaceMD,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: conversation.isStarred
                        ? context.appPrimary
                        : context.appSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.appPrimary.withValues(
                        alpha: conversation.isStarred ? 0 : 0.2,
                      ),
                    ),
                  ),
                  child: Icon(
                    conversation.isStarred
                        ? Icons.push_pin_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: conversation.isStarred
                        ? context.appOnPrimary
                        : context.appPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversationDisplayTitle(conversation.title),
                        style: AppTypography.bodyTextMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversationActivityLabel(conversation.updatedAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: context.appInkSubtle),
                  onSelected: (value) {
                    if (value == 'pin') onTogglePin();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            conversation.isStarred
                                ? Icons.push_pin_outlined
                                : Icons.push_pin_rounded,
                            size: 20,
                            color: context.appPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conversation.isStarred ? 'Unpin' : 'Pin chat',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
