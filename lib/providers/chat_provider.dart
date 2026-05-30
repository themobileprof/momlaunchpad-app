import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../services/websocket_service.dart';
import '../services/conversation_service.dart';
import '../utils/conversation_list_utils.dart';
import 'service_providers.dart';
import 'conversation_provider.dart';

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

  @override
  ChatState build() {
    _wsService = ref.read(webSocketServiceProvider);
    _conversationService = ref.read(conversationServiceProvider);
    return ChatState();
  }

  /// Initialize chat with a specific conversation
  Future<void> initialize(String conversationId, {String? title}) async {
    if (state.currentConversationId == conversationId &&
        state.conversationTitle == title) {
      return;
    }

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
        messages: messages.reversed.toList(), // Assuming API returns newest first, or we adjust sort order
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
    await _wsService.connect(conversationId: id);
    debugPrint('DEBUG: WebSocketService connected status: ${_wsService.isConnected}');
    state = state.copyWith(isConnected: _wsService.isConnected);

    // Listen to WebSocket messages
    _messageSubscription?.cancel();
    _messageSubscription = _wsService.messages.listen(_handleMessage);
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(WebSocketMessage wsMessage) {
    debugPrint('ChatProvider received message: type=${wsMessage.type}, content=${wsMessage.content}');

    switch (wsMessage.type) {
      case MessageType.message:
        _applyStreamingChunk(wsMessage.content);
        break;

      case MessageType.done:
        _finalizeStreamingAiMessage();
        break;

      case MessageType.calendar:
        // Calendar suggestion from AI
        if (wsMessage.data != null) {
          final suggestion = CalendarSuggestion.fromJson(wsMessage.data!);
          state = state.copyWith(pendingSuggestion: suggestion);
        }
        break;

      case MessageType.error:
        // Error from backend
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

  /// Send message to backend
  void sendMessage(String content) {
    if (content.trim().isEmpty) return;

    debugPrint('DEBUG: Sending message: "$content"');

    // Add user message to UI
    final userMessage = Message(
      id: DateTime.now().toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // DON'T create AI message here - let the first chunk create it
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      currentResponse: '', 
      error: null,
    );

    // Send to backend via WebSocket
    final sent = _wsService.sendMessage(content);
    debugPrint('DEBUG: Message sent status: $sent');
    
    if (!sent) {
      state = state.copyWith(
        error: 'Could not send message. Please try again.',
      );
      return;
    }

    _maybeAutoTitleConversation(content);
  }

  Future<void> _maybeAutoTitleConversation(String content) async {
    final conversationId = state.currentConversationId;
    final currentTitle = state.conversationTitle;
    if (conversationId == null || currentTitle == null) return;
    if (!isGenericConversationTitle(currentTitle)) return;

    final userMessages =
        state.messages.where((message) => message.isUser).length;
    if (userMessages != 1) return;

    final newTitle = titleFromFirstMessage(content);
    if (newTitle == currentTitle) return;

    state = state.copyWith(conversationTitle: newTitle);

    try {
      await _conversationService.updateConversation(
        conversationId,
        title: newTitle,
      );
      await ref.read(conversationProvider.notifier).renameConversation(
            conversationId,
            newTitle,
          );
    } catch (e) {
      debugPrint('Failed to auto-title conversation: $e');
    }
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
    _wsService.disconnect();
    _messageSubscription?.cancel();
    state = state.copyWith(isConnected: false);
  }
}

/// Chat provider instance
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
