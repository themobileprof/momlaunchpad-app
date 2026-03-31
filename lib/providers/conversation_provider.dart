import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import 'service_providers.dart';

class ConversationState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  ConversationState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationNotifier extends Notifier<ConversationState> {
  @override
  ConversationState build() {
    return ConversationState();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(conversationServiceProvider);
      final conversations = await service.getConversations();
      state = state.copyWith(
        conversations: conversations,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<Conversation?> createConversation(String title) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(conversationServiceProvider);
      debugPrint('DEBUG: Calling service.createConversation...');
      final newConversation = await service.createConversation(title);
      debugPrint('DEBUG: Service returned: ${newConversation.id}');
      
      state = state.copyWith(
        conversations: [newConversation, ...state.conversations],
        isLoading: false,
      );
      return newConversation;
    } catch (e) {
      debugPrint('DEBUG: createConversation failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      final service = ref.read(conversationServiceProvider);
      await service.deleteConversation(id);
      
      state = state.copyWith(
        conversations: state.conversations.where((c) => c.id != id).toList(),
      );
    } catch (e) {
      // Handle error (maybe show toast via side effect, but for state just keep it simple)
      debugPrint('Failed to delete conversation: $e');
    }
  }
}

final conversationProvider = NotifierProvider<ConversationNotifier, ConversationState>(ConversationNotifier.new);
