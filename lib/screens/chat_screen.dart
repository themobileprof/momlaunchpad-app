import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../providers/chat_provider.dart';
import '../providers/service_providers.dart';
import '../services/network_monitor.dart';
import '../utils/chat_utils.dart';
import '../models/reminder.dart';

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
  NetworkMonitor? _networkMonitor;

  @override
  void initState() {
    super.initState();
    // Start network monitoring for auto-reconnection
    _networkMonitor = NetworkMonitor(ref);
    _networkMonitor?.startMonitoring();
  }

  Future<void> _connectWebSocket() async {
    if (_isConnected) return; // Already connected
    await ref.read(chatProvider.notifier).connect();
    setState(() {
      _isConnected = ref.read(chatProvider).isConnected;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _networkMonitor?.dispose();
    if (_isConnected) {
      ref.read(chatProvider.notifier).disconnect();
    }
    super.dispose();
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Connect to WebSocket if not already connected (lazy connection)
    if (!_isConnected) {
      await _connectWebSocket();
    }

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

    // Show calendar suggestion dialog when available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.pendingSuggestion != null) {
        _showCalendarSuggestionDialog(chatState.pendingSuggestion!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat History',
              style: AppTypography.headingMedium,
            ),
            Text(
              'View past conversations & transcripts',
              style: AppTypography.caption.copyWith(
                color: AppColors.textLight,
              ),
            ),
          ],
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
                          Icons.history,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: AppSpacing.spaceMD),
                        Text(
                          'No conversation history yet',
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rate limit indicator
                if (!ref.read(chatProvider.notifier).canSendMessage())
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spaceSM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sending too fast. Please wait a moment.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.warning,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.spaceMD,
                            vertical: AppSpacing.spaceSM,
                          ),
                          suffixIcon: chatState.isConnected
                              ? null
                              : const Tooltip(
                                  message: 'Connecting...',
                                  child: Icon(
                                    Icons.cloud_off,
                                    size: 16,
                                    color: AppColors.textLight,
                                  ),
                                ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: chatState.isConnected &&
                            ref.read(chatProvider.notifier).canSendMessage(),
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
                      tooltip: !chatState.isConnected
                          ? 'Connecting...'
                          : !ref.read(chatProvider.notifier).canSendMessage()
                              ? 'Rate limit reached'
                              : 'Send message',
                    ),
                  ],
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

  /// Show calendar suggestion dialog
  void _showCalendarSuggestionDialog(CalendarSuggestion suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primaryPink),
            SizedBox(width: 8),
            Text('Add Reminder?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.title,
              style: AppTypography.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description ?? '',
              style: AppTypography.bodyText,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  formatTimestamp(suggestion.suggestedTime),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
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
          ElevatedButton(
            onPressed: () async {
              // Create reminder via API
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.createReminder(
                  title: suggestion.title,
                  description: suggestion.description,
                  scheduledTime: suggestion.suggestedTime,
                  priority: 'medium',
                );

                ref.read(chatProvider.notifier).clearCalendarSuggestion();
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reminder created successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to create reminder: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }
}
