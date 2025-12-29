import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

/// Chat screen - Primary feature
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    await ref.read(chatProvider.notifier).connect();
    setState(() {
      _isConnected = ref.read(chatProvider).isConnected;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    ref.read(chatProvider.notifier).disconnect();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(content);
    _messageController.clear();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat',
          style: AppTypography.headingMedium,
        ),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.spaceMD),
            child: Icon(
              chatState.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: chatState.isConnected ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        Text(
                          'Start a conversation',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: AppSpacing.spaceSM),
                        Text(
                          'Ask me anything about pregnancy',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textLight.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.spaceMD),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return _buildMessageBubble(message.content, message.isUser);
                    },
                  ),
          ),

          // Error message
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.spaceSM),
              color: AppColors.error.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: AppSpacing.spaceSM),
                  Expanded(
                    child: Text(
                      chatState.error!,
                      style: AppTypography.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(AppSpacing.spaceMD),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spaceMD,
                        vertical: AppSpacing.spaceSM,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSM),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: AppColors.primaryPink,
                  onPressed: chatState.isConnected &&
                          ref.read(chatProvider.notifier).canSendMessage()
                      ? _sendMessage
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.spaceMD),
        padding: const EdgeInsets.all(AppSpacing.spaceMD),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryPink : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          content,
          style: AppTypography.bodyText.copyWith(
            color: isUser ? AppColors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
