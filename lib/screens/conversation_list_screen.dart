import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final titleController = TextEditingController();
    
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: 'Enter chat title',
            labelText: 'Title',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, titleController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      if (!mounted) return;
      
      final conversation = await ref.read(conversationProvider.notifier).createConversation(title);
      if (conversation != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(conversationId: conversation.id, conversationTitle: conversation.title),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Conversations', style: AppTypography.headingMedium),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: state.isLoading && state.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.conversations.isEmpty
              ? EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No conversations yet',
                  description: 'Start a new chat to track your journey.',
                  actionLabel: 'New Chat',
                  onAction: _createNewConversation,
                )
              :  RefreshIndicator(
                  onRefresh: () => ref.read(conversationProvider.notifier).loadConversations(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.spaceSM),
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
                        confirmDismiss: (direction) async {
                          return await showDialog(
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
                        },
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
                                color: AppColors.primaryPink.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryPink, size: 20),
                            ),
                            title: Text(
                              conversation.title.isNotEmpty ? conversation.title : 'Untitled Chat',
                              style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Started ${_formatDate(conversation.createdAt)}',
                              style: AppTypography.caption,
                            ),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
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
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewConversation,
        backgroundColor: AppColors.primaryPink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
