import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../providers/conversation_provider.dart';
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Chat', style: AppTypography.headingMedium),
        backgroundColor: AppColors.canvas,
        actions: [
          TextButton.icon(
            onPressed: state.isLoading ? null : _createNewConversation,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('New topic'),
          ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(ConversationState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.conversations.isEmpty) {
      return EmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'Ask anything about your pregnancy',
        description:
            'Start a conversation about symptoms, nutrition, appointments, or how you\'re feeling today.',
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
                  onDelete: () => _deleteConversation(conversation),
                ),
              ),
            const SizedBox(height: AppSpacing.spaceMD),
          ],
        ],
      ),
    );
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
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppColors.rose.withValues(alpha: 0.28),
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
                    child: const Icon(
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
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
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
      style: AppTypography.label.copyWith(color: AppColors.plum),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
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
        child: const Icon(Icons.delete_outline, color: AppColors.error),
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
                color: AppColors.plum.withValues(alpha: 0.08),
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
                        ? AppColors.orchidSoft
                        : AppColors.roseSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    conversation.isStarred
                        ? Icons.push_pin_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: conversation.isStarred
                        ? AppColors.plum
                        : AppColors.rose,
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
