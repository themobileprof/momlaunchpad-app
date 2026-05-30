import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/chat_provider.dart';
import '../providers/service_providers.dart';
import '../services/network_monitor.dart';
import '../widgets/widgets.dart';
import '../models/reminder.dart';
import '../models/message.dart';
import '../models/conversation_group.dart';
import '../utils/conversation_list_utils.dart';

/// Chat screen - Primary text-based chat feature
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? conversationTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversationTitle,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  NetworkMonitor? _networkMonitor;
  String? _lastShownSuggestionId; // Track which suggestion was shown

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: ChatScreen initialized for conversation: ${widget.conversationId}');
    _networkMonitor = NetworkMonitor(ref);
    _networkMonitor?.startMonitoring();
    
    // Initialize chat with specific conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('DEBUG: Calling chatProvider.initialize...');
      ref.read(chatProvider.notifier).initialize(
            widget.conversationId,
            title: widget.conversationTitle,
          );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _networkMonitor?.dispose();
    // Use addPostFrameCallback to avoid state errors during dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Optional: Disconnect when leaving screen to save resources
      // ref.read(chatProvider.notifier).disconnect(); 
      // Kept commented out if we want to keep connection alive for a bit
    });
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    if (ref.read(chatProvider).isConnected) return;
    debugPrint('DEBUG: Manual WebSocket connect requested from ChatScreen');
    await ref.read(chatProvider.notifier).connect(conversationId: widget.conversationId);
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    debugPrint('DEBUG: ChatScreen._sendMessage: "$content"');

    if (!ref.read(chatProvider).isConnected) {
      debugPrint('DEBUG: Not connected, attempting to connect before sending...');
      await ref.read(chatProvider.notifier).connect(conversationId: widget.conversationId);
    }

    ref.read(chatProvider.notifier).sendMessage(content);
    _messageController.clear();
    _inputFocusNode.requestFocus();

    // Scroll to bottom
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

    // Show calendar suggestion dialog when available (only once per suggestion)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.pendingSuggestion != null && 
          _lastShownSuggestionId != chatState.pendingSuggestion!.title) {
        _lastShownSuggestionId = chatState.pendingSuggestion!.title;
        _showCalendarSuggestionDialog(chatState.pendingSuggestion!);
      }
    });

    return Scaffold(
      appBar: _buildAppBar(chatState),
      body: chatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Error banner
                if (chatState.error != null) _buildErrorBanner(chatState.error!),

                // Messages list
                Expanded(child: _buildMessagesList(chatState)),

                // Input field
                _buildInputArea(chatState),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatState chatState) {
    return AppBar(
      titleSpacing: AppSpacing.spaceMD,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversationDisplayTitle(
              chatState.conversationTitle ??
                  widget.conversationTitle ??
                  defaultConversationTitle,
            ),
            style: AppTypography.headingMedium,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              StatusDot(
                isActive: chatState.isConnected,
                size: 6,
                pulse: chatState.isConnected,
              ),
              const SizedBox(width: 6),
              Text(
                chatState.isConnected ? 'Connected' : 'Disconnected',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: chatState.isConnected
                      ? AppColors.success
                      : AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.spaceSM),
          child: IconButton(
            icon: Icon(
              chatState.isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: chatState.isConnected ? AppColors.success : AppColors.error,
            ),
            onPressed: () {
              if (!chatState.isConnected) {
                _connectWebSocket();
              }
            },
            tooltip: chatState.isConnected ? 'Connected' : 'Tap to reconnect',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMD,
        vertical: AppSpacing.spaceSM,
      ),
      color: AppColors.error.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.spaceSM),
          Expanded(
            child: Text(
              error,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              // Could add a way to dismiss error
            },
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.messages.isEmpty) {
      return EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No messages yet',
        description: 'Start the conversation!',
        actionLabel: 'Say Hello',
        onAction: () {
          _messageController.text = "Hello!";
          _inputFocusNode.requestFocus();
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMD,
        vertical: AppSpacing.spaceSM,
      ),
      itemCount: _calculateListItemCount(chatState.messages),
      itemBuilder: (context, index) {
        return _buildGroupedMessage(context, chatState.messages, index);
      },
    );
  }

  Widget _buildInputArea(ChatState chatState) {
    final canSend = chatState.isConnected &&
        ref.read(chatProvider.notifier).canSendMessage();

    return Container(
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
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rate limit warning
            if (!ref.read(chatProvider.notifier).canSendMessage())
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Sending too fast. Please wait a moment.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _inputFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spaceMD,
                          vertical: AppSpacing.spaceSM + 4,
                        ),
                        hintStyle: AppTypography.bodyText.copyWith(
                          color: AppColors.textLight.withOpacity(0.6),
                        ),
                      ),
                      style: AppTypography.bodyText,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: canSend,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spaceSM),
                _SendButton(
                  onPressed: canSend ? _sendMessage : null,
                  isConnected: chatState.isConnected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCalendarSuggestionDialog(CalendarSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primaryPink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Add Reminder?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.title, style: AppTypography.headingMedium),
            const SizedBox(height: 8),
            Text(suggestion.description ?? '', style: AppTypography.bodyText),
            const SizedBox(height: 16),
            AppBadge(
              label: _formatDate(suggestion.suggestedTime),
              icon: Icons.access_time,
              variant: AppBadgeVariant.secondary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearCalendarSuggestion();
              Navigator.pop(context);
            },
            child: const Text('Not Now'),
          ),
          AppButton(
            label: 'Add Reminder',
            onPressed: () => _createReminder(suggestion),
            isFullWidth: false,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _createReminder(CalendarSuggestion suggestion) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.createReminder(
        title: suggestion.title,
        description: suggestion.description,
        scheduledTime: suggestion.suggestedTime,
        priority: 'medium',
      );

      ref.read(chatProvider.notifier).clearCalendarSuggestion();
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder created successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Show hint to switch to Calendar tab
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switch to Calendar tab to view your reminders'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create reminder: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper methods for conversation grouping

  int _calculateListItemCount(List<Message> messages) {
    if (messages.isEmpty) return 0;

    final groups = groupMessagesByConversation(messages);
    int count = 0;
    
    for (final group in groups) {
      count++; // Date/time header
      count += group.messages.length; // Messages
    }
    
    return count;
  }

  Widget _buildGroupedMessage(BuildContext context, List<Message> messages, int flatIndex) {
    final groups = groupMessagesByConversation(messages);
    
    int currentIndex = 0;
    
    for (var groupIdx = 0; groupIdx < groups.length; groupIdx++) {
      final group = groups[groupIdx];
      
      // Check if this is the header position
      if (currentIndex == flatIndex) {
        return _buildConversationHeader(group);
      }
      currentIndex++;
      
      // Check if this is one of the message positions
      for (var msgIdx = 0; msgIdx < group.messages.length; msgIdx++) {
        if (currentIndex == flatIndex) {
          final message = group.messages[msgIdx];
          return Padding(
            padding: EdgeInsets.only(
              bottom: msgIdx == group.messages.length - 1 
                ? AppSpacing.spaceLG 
                : AppSpacing.spaceXS,
            ),
            child: ChatBubble(
              content: message.content,
              isUser: message.isUser,
              timestamp: message.timestamp,
              isStreaming: message.isStreaming,
            ),
          );
        }
        currentIndex++;
      }
    }
    
    // Should not reach here
    return const SizedBox.shrink();
  }

  Widget _buildConversationHeader(ConversationGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.spaceMD,
      ),
      child: Column(
        children: [
          // Date divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.textLight.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spaceSM,
                ),
                child: Text(
                  group.dateHeader,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.textLight.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spaceXS),
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spaceSM,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.radiusSmall),
            ),
            child: Text(
              'Started at ${group.timeHeader}',
              style: AppTypography.caption.copyWith(
                color: AppColors.primaryPink,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated send button
class _SendButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isConnected;

  const _SendButton({this.onPressed, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: onPressed != null
            ? const LinearGradient(
                colors: [AppColors.primaryPink, Color(0xFFFF6B9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? AppColors.textLight.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.radiusMedium),
          child: Icon(
            isConnected ? Icons.send_rounded : Icons.cloud_off,
            color: AppColors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
