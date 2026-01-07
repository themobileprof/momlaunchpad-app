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

/// Chat screen - Primary text-based chat feature
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isConnected = false;
  NetworkMonitor? _networkMonitor;

  @override
  void initState() {
    super.initState();
    _networkMonitor = NetworkMonitor(ref);
    _networkMonitor?.startMonitoring();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _networkMonitor?.dispose();
    // Don't use ref in dispose - it's unsafe
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    if (_isConnected) return;
    await ref.read(chatProvider.notifier).connect();
    setState(() {
      _isConnected = ref.read(chatProvider).isConnected;
    });
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (!_isConnected) {
      await _connectWebSocket();
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

    // Show calendar suggestion dialog when available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.pendingSuggestion != null) {
        _showCalendarSuggestionDialog(chatState.pendingSuggestion!);
      }
    });

    return Scaffold(
      appBar: _buildAppBar(chatState),
      body: Column(
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
          Text('Chat History', style: AppTypography.headingMedium),
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
        title: 'No conversation history yet',
        description: 'Ask me anything about pregnancy\nI\'m here to help!',
        actionLabel: 'Start Chat',
        onAction: () => _inputFocusNode.requestFocus(),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spaceMD,
        vertical: AppSpacing.spaceSM,
      ),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final message = chatState.messages[index];
        return ChatBubble(
          content: message.content,
          isUser: message.isUser,
          timestamp: message.timestamp,
          isStreaming: message.isStreaming,
        );
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
