import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import '../providers/conversation_provider.dart';
import '../widgets/widgets.dart';
import 'chat_screen.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen> {
  @override
  void initState() {
    super.initState();
    // Load conversations on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationProvider.notifier).loadConversations();
    });
  }

  Future<void> _createNewConversation() async {
    debugPrint('DEBUG: _createNewConversation called');
    final title = 'Chat ${DateFormat('MMM d, h:mm a').format(DateTime.now())}';
    debugPrint('DEBUG: Generated title: $title');
    
    try {
      final conversation = await ref.read(conversationProvider.notifier).createConversation(title);
      debugPrint('DEBUG: createConversation result: $conversation');
      
      if (conversation != null && mounted) {
        debugPrint('DEBUG: Navigating to ChatScreen with ID: ${conversation.id}');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversation.id, 
              conversationTitle: conversation.title
            ),
          ),
        );
        debugPrint('DEBUG: Returned from ChatScreen');
      } else {
        debugPrint('DEBUG: Conversation is null or not mounted');
      }
    } catch (e) {
      debugPrint('DEBUG: Error creating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Conversations', style: AppTypography.headingMedium),
        backgroundColor: AppColors.canvas,
      ),
      body: _buildBody(state),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Raise above updated nav
        child: NeumorphicButton(
          onPressed: _createNewConversation,
          height: 56,
          width: 56,
          borderRadius: 28,
          color: AppColors.plum,
          padding: EdgeInsets.zero,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody(ConversationState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.conversations.isEmpty) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        description: 'Start a new chat to track your journey.',
        actionLabel: 'New Chat',
        onAction: _createNewConversation,
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(conversationProvider.notifier).loadConversations(),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          top: AppSpacing.spaceMD,
          left: AppSpacing.spaceMD,
          right: AppSpacing.spaceMD,
          bottom: 120, // Space for floating navbar
        ),
        itemCount: state.conversations.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spaceSM),
        itemBuilder: (context, index) {
          final conversation = state.conversations[index];
          return Dismissible(
            key: Key(conversation.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.spaceMD),
              color: AppColors.error,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) => _confirmDelete(context),
            onDismissed: (_) {
              ref.read(conversationProvider.notifier).deleteConversation(conversation.id);
            },
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
                side: BorderSide(color: AppColors.textLight.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceMD,
                  vertical: AppSpacing.spaceSM,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.roseSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: AppColors.rose,
                    size: 20,
                  ),
                ),
                title: Text(
                  conversation.title.isNotEmpty ? conversation.title : 'Untitled Chat',
                  style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Started ${_formatDate(conversation.createdAt)}',
                  style: AppTypography.caption,
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textLight),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await _confirmDelete(context);
                      if (confirm == true) {
                        ref.read(conversationProvider.notifier).deleteConversation(conversation.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        conversationId: conversation.id,
                        conversationTitle: conversation.title,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this chat?'),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
