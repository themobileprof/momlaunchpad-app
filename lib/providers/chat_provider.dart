import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../services/websocket_service.dart';
import '../services/conversation_service.dart';
import 'service_providers.dart';

/// Chat state
class ChatState {
  final List<Message> messages;
  final bool isConnected;
  final String? error;
  final String currentResponse; // For streaming responses
  final CalendarSuggestion? pendingSuggestion;
  final String? currentConversationId;
  final bool isLoading;

  ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.error,
    this.currentResponse = '',
    this.pendingSuggestion,
    this.currentConversationId,
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
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      currentResponse: currentResponse ?? this.currentResponse,
      pendingSuggestion: clearSuggestion ? null : (pendingSuggestion ?? this.pendingSuggestion),
      currentConversationId: currentConversationId ?? this.currentConversationId,
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
  Future<void> initialize(String conversationId) async {
    // If already initialized for this conversation, do nothing
    if (state.currentConversationId == conversationId) return;

    // Reset state for new conversation
    state = ChatState(
      currentConversationId: conversationId,
      isLoading: true,
    );
    
    // Disconnect previous connection if any
    disconnect();

    try {
      // Load existing messages
      final messages = await _conversationService.getMessages(conversationId);
      state = state.copyWith(
        messages: messages.reversed.toList(), // Assuming API returns newest first, or we adjust sort order
        isLoading: false,
      );

      // Connect to WebSocket for this conversation
      await connect(conversationId: conversationId);
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversation: $e',
      );
    }
  }

  /// Connect to WebSocket
  Future<void> connect({String? conversationId}) async {
    final id = conversationId ?? state.currentConversationId;
    await _wsService.connect(conversationId: id);
    state = state.copyWith(isConnected: _wsService.isConnected);

    // Listen to WebSocket messages
    _messageSubscription?.cancel();
    _messageSubscription = _wsService.messages.listen(_handleMessage);
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(WebSocketMessage wsMessage) {
    print('ChatProvider received message: type=${wsMessage.type}, content=${wsMessage.content}');
    
    switch (wsMessage.type) {
      case MessageType.message:
        // Streaming AI response chunk
        // Ensure there's an AI message to update
        if (state.messages.isEmpty || state.messages.last.isUser) {
          // Create new AI message if none exists - start fresh
          final aiMessage = Message(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            content: wsMessage.content ?? '',
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: true,
          );
          state = state.copyWith(
            messages: [...state.messages, aiMessage],
            currentResponse: wsMessage.content ?? '', 
          );
        } else {
          // Update existing AI message with new chunk
          final updatedResponse = state.currentResponse + (wsMessage.content ?? '');
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
        break;

      case MessageType.done:
        // Response complete - finalize message
        if (state.messages.isNotEmpty && !state.messages.last.isUser) {
          final updatedMessages = List<Message>.from(state.messages);
          updatedMessages[updatedMessages.length - 1] = updatedMessages.last.copyWith(
            isStreaming: false,
          );
          state = state.copyWith(
            messages: updatedMessages,
            currentResponse: '', // Reset for next message
          );
        }
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

  /// Send message to backend
  void sendMessage(String content) {
    if (content.trim().isEmpty) return;

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
    
    if (!sent) {
      state = state.copyWith(
        error: 'Could not send message. Please try again.',
      );
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
