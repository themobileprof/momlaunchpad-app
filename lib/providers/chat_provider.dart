import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../services/websocket_service.dart';
import '../services/conversation_service.dart';
import '../services/analytics_service.dart';
import '../utils/analytics_topic_classifier.dart';
import 'service_providers.dart';
import 'conversation_provider.dart';

const _replyTimeout = Duration(seconds: 45);

/// Chat state
class ChatState {
  final List<Message> messages;
  final bool isConnected;
  final String? error;
  final String currentResponse; // For streaming responses
  final CalendarSuggestion? pendingSuggestion;
  final String? currentConversationId;
  final String? conversationTitle;
  final bool isLoading;

  ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.error,
    this.currentResponse = '',
    this.pendingSuggestion,
    this.currentConversationId,
    this.conversationTitle,
    this.isLoading = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isConnected,
    String? error,
    String? currentResponse,
    CalendarSuggestion? pendingSuggestion,
    bool clearSuggestion = false,
    String? currentConversationId,
    String? conversationTitle,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      currentResponse: currentResponse ?? this.currentResponse,
      pendingSuggestion: clearSuggestion ? null : (pendingSuggestion ?? this.pendingSuggestion),
      currentConversationId: currentConversationId ?? this.currentConversationId,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Chat provider (Notifier)
class ChatNotifier extends Notifier<ChatState> {
  late final WebSocketService _wsService;
  late final ConversationService _conversationService;
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  Timer? _replyTimeoutTimer;
  bool _everConnected = false;

  @override
  ChatState build() {
    _wsService = ref.read(webSocketServiceProvider);
    _conversationService = ref.read(conversationServiceProvider);
    ref.onDispose(() {
      _replyTimeoutTimer?.cancel();
      _messageSubscription?.cancel();
    });
    return ChatState();
  }

  /// Initialize chat with a specific conversation
  Future<void> initialize(String conversationId, {String? title}) async {
    if (state.currentConversationId == conversationId &&
        state.conversationTitle == title) {
      return;
    }

    _everConnected = false;
    state = ChatState(
      currentConversationId: conversationId,
      conversationTitle: title,
      isLoading: true,
    );

    // Disconnect previous connection if any
    disconnect();

    try {
      // Load existing messages
      debugPrint('DEBUG: Loading messages for $conversationId...');
      final messages = await _conversationService.getMessages(conversationId);
      debugPrint('DEBUG: Loaded ${messages.length} messages.');
      state = state.copyWith(
        messages: messages,
        isLoading: false,
      );

      // Connect to WebSocket for this conversation
      await connect(conversationId: conversationId);
    } catch (e) {
      debugPrint('DEBUG: Error initializing chat: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversation: $e',
      );
    }
  }

  /// Connect to WebSocket
  Future<void> connect({String? conversationId}) async {
    final id = conversationId ?? state.currentConversationId;
    debugPrint('DEBUG: ChatNotifier.connect for ID: $id');
    final wasConnected = state.isConnected;
    await _wsService.connect(conversationId: id);
    debugPrint('DEBUG: WebSocketService connected status: ${_wsService.isConnected}');
    final nowConnected = _wsService.isConnected;
    state = state.copyWith(isConnected: nowConnected);

    // Listen to WebSocket messages
    _messageSubscription?.cancel();
    _messageSubscription = _wsService.messages.listen(_handleMessage);

    if (nowConnected) {
      if (_everConnected && !wasConnected && id != null) {
        await _syncMessagesFromServer(id);
      }
      _everConnected = true;
    }
  }

  Future<void> _syncMessagesFromServer(String conversationId) async {
    try {
      final server = await _conversationService.getMessages(conversationId);
      final pending = state.messages
          .where((m) => m.isUser && m.sendStatus != null)
          .toList();
      if (pending.isEmpty) {
        state = state.copyWith(messages: server);
        return;
      }
      final serverContents = server
          .where((m) => m.isUser)
          .map((m) => m.content.trim())
          .toSet();
      final stillLocal = pending
          .where((m) => !serverContents.contains(m.content.trim()))
          .toList();
      state = state.copyWith(messages: [...server, ...stillLocal]);
    } catch (e) {
      debugPrint('DEBUG: Failed to sync messages after reconnect: $e');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(WebSocketMessage wsMessage) {
    debugPrint('ChatProvider received message: type=${wsMessage.type}, content=${wsMessage.content}');

    switch (wsMessage.type) {
      case MessageType.message:
        _clearPendingSendStatus();
        _cancelReplyTimeout();
        _applyStreamingChunk(wsMessage.content);
        break;

      case MessageType.done:
        _clearPendingSendStatus();
        _cancelReplyTimeout();
        _finalizeStreamingAiMessage();
        break;

      case MessageType.titleUpdated:
        _applyTitleUpdate(wsMessage.content);
        break;

      case MessageType.calendar:
        // Calendar suggestion from AI
        if (wsMessage.data != null) {
          final suggestion = CalendarSuggestion.fromJson(wsMessage.data!);
          state = state.copyWith(pendingSuggestion: suggestion);
        }
        break;

      case MessageType.error:
        _markLastSendingFailed();
        state = state.copyWith(error: wsMessage.message ?? 'Unknown error');
        break;
    }
  }

  void _applyStreamingChunk(String? chunk) {
    final piece = chunk ?? '';
    if (state.messages.isEmpty || state.messages.last.isUser) {
      final aiMessage = Message(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: piece,
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        currentResponse: piece,
      );
      return;
    }

    final updatedResponse = state.currentResponse + piece;
    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages[updatedMessages.length - 1] = updatedMessages.last.copyWith(
      content: updatedResponse,
      isStreaming: true,
    );
    state = state.copyWith(
      messages: updatedMessages,
      currentResponse: updatedResponse,
    );
  }

  void _finalizeStreamingAiMessage() {
    if (state.messages.isEmpty || state.messages.last.isUser) return;
    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages[updatedMessages.length - 1] = updatedMessages.last.copyWith(
      isStreaming: false,
    );
    state = state.copyWith(
      messages: updatedMessages,
      currentResponse: '',
    );
  }

  void _applyTitleUpdate(String? title) {
    final conversationId = state.currentConversationId;
    if (conversationId == null || title == null || title.trim().isEmpty) return;

    final newTitle = title.trim();
    state = state.copyWith(conversationTitle: newTitle);
    ref.read(conversationProvider.notifier).renameConversation(
          conversationId,
          newTitle,
        );
  }

  void _armReplyTimeout() {
    _replyTimeoutTimer?.cancel();
    _replyTimeoutTimer = Timer(_replyTimeout, () {
      _markLastSendingFailed();
      state = state.copyWith(
        error: 'No reply yet — check your connection and tap Retry.',
      );
    });
  }

  void _cancelReplyTimeout() {
    _replyTimeoutTimer?.cancel();
    _replyTimeoutTimer = null;
  }

  void _clearPendingSendStatus() {
    final updated = state.messages
        .map((m) => m.isUser && m.sendStatus != null
            ? m.copyWith(clearSendStatus: true)
            : m)
        .toList();
    state = state.copyWith(messages: updated);
  }

  void _markLastSendingFailed() {
    _cancelReplyTimeout();
    _wsService.clearPendingQueue();
    final updated = List<Message>.from(state.messages);
    for (var i = updated.length - 1; i >= 0; i--) {
      if (updated[i].isUser &&
          updated[i].sendStatus == MessageSendStatus.sending) {
        updated[i] = updated[i].copyWith(sendStatus: MessageSendStatus.failed);
        break;
      }
    }
    state = state.copyWith(messages: updated);
  }

  /// Send message to backend
  void sendMessage(String content, {String? existingMessageId}) {
    if (content.trim().isEmpty) return;

    debugPrint('DEBUG: Sending message: "$content"');

    final trimmed = content.trim();
    List<Message> nextMessages;

    if (existingMessageId != null) {
      nextMessages = state.messages
          .map((m) => m.id == existingMessageId
              ? m.copyWith(sendStatus: MessageSendStatus.sending)
              : m)
          .toList();
    } else {
      final userMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
        sendStatus: MessageSendStatus.sending,
      );
      nextMessages = [...state.messages, userMessage];

      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.aiQuestionSent,
        {
          AnalyticsParams.topicBucket:
              AnalyticsTopicClassifier.topicBucket(trimmed),
          AnalyticsParams.intentCategory:
              AnalyticsTopicClassifier.intentCategory(trimmed),
          AnalyticsParams.messageLengthBucket:
              AnalyticsTopicClassifier.messageLengthBucket(trimmed.length),
        },
      );
      ref.read(analyticsServiceProvider).logEvent(
        AnalyticsEvents.featureUsed,
        {AnalyticsParams.featureName: 'chat'},
      );
    }

    state = state.copyWith(
      messages: nextMessages,
      currentResponse: '',
      error: null,
    );

    // Send to backend via WebSocket (queues if offline)
    final sent = _wsService.sendMessage(
      trimmed,
      conversationId: state.currentConversationId,
    );
    debugPrint('DEBUG: Message sent status: $sent');
    _armReplyTimeout();
  }

  void retryMessage(String messageId) {
    Message? target;
    for (final m in state.messages) {
      if (m.id == messageId) {
        target = m;
        break;
      }
    }
    if (target == null ||
        !target.isUser ||
        target.sendStatus != MessageSendStatus.failed) {
      return;
    }
    sendMessage(target.content, existingMessageId: messageId);
  }

  /// Clear pending calendar suggestion
  void clearCalendarSuggestion() {
    state = state.copyWith(clearSuggestion: true);
  }

  /// Check if can send message (rate limiting)
  bool canSendMessage() {
    return _wsService.canSendMessage();
  }

  /// Get remaining messages in current minute
  int getRemainingMessages() {
    return _wsService.getRemainingMessages();
  }

  /// Disconnect WebSocket
  void disconnect() {
    _cancelReplyTimeout();
    _wsService.disconnect();
    _messageSubscription?.cancel();
    state = state.copyWith(isConnected: false);
  }
}

/// Chat provider instance
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
