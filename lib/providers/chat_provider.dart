import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../models/reminder.dart';
import '../services/websocket_service.dart';
import 'service_providers.dart';

/// Chat state
class ChatState {
  final List<Message> messages;
  final bool isConnected;
  final String? error;
  final String currentResponse; // For streaming responses
  final CalendarSuggestion? pendingSuggestion;

  ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.error,
    this.currentResponse = '',
    this.pendingSuggestion,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isConnected,
    String? error,
    String? currentResponse,
    CalendarSuggestion? pendingSuggestion,
    bool clearSuggestion = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      currentResponse: currentResponse ?? this.currentResponse,
      pendingSuggestion: clearSuggestion ? null : (pendingSuggestion ?? this.pendingSuggestion),
    );
  }
}

/// Chat provider (Notifier)
class ChatNotifier extends Notifier<ChatState> {
  late final WebSocketService _wsService;
  StreamSubscription<WebSocketMessage>? _messageSubscription;

  @override
  ChatState build() {
    _wsService = ref.read(webSocketServiceProvider);
    return ChatState();
  }

  /// Connect to WebSocket
  Future<void> connect() async {
    await _wsService.connect();
    state = state.copyWith(isConnected: _wsService.isConnected);

    // Listen to WebSocket messages
    _messageSubscription = _wsService.messages.listen(_handleMessage);
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(WebSocketMessage wsMessage) {
    print('ChatProvider received message: type=${wsMessage.type}, content=${wsMessage.content}');
    print('Current state - messages count: ${state.messages.length}, currentResponse length: ${state.currentResponse.length}');
    
    switch (wsMessage.type) {
      case MessageType.message:
        // Streaming AI response chunk
        print('Processing message chunk: "${wsMessage.content}"');
        
        // Ensure there's an AI message to update
        if (state.messages.isEmpty || state.messages.last.isUser) {
          // Create new AI message if none exists - start fresh
          print('Creating new AI message with content: "${wsMessage.content}"');
          final aiMessage = Message(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            content: wsMessage.content ?? '',
            isUser: false,
            timestamp: DateTime.now(),
            isStreaming: true,
          );
          state = state.copyWith(
            messages: [...state.messages, aiMessage],
            currentResponse: wsMessage.content ?? '', // Start accumulating from this chunk
          );
        } else {
          // Update existing AI message with new chunk
          final updatedResponse = state.currentResponse + (wsMessage.content ?? '');
          print('Updating AI message - old length: ${state.currentResponse.length}, new chunk: "${wsMessage.content}", total: ${updatedResponse.length}');
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
        print('After processing - last message content: "${state.messages.last.content}"');
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

    print('=== sendMessage called with: "$content" ===');

    // Add user message to UI
    final userMessage = Message(
      id: DateTime.now().toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // DON'T create AI message here - let the first chunk create it
    // This prevents duplicate AI messages
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      currentResponse: '', // Reset accumulator for new response
      error: null,
    );

    print('User message added. Total messages: ${state.messages.length}');

    // Send to backend via WebSocket
    print('Sending message from ChatProvider: $content');
    final sent = _wsService.sendMessage(content);
    print('Message send result: $sent');
    
    if (!sent) {
      // Rate limited or connection error
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
