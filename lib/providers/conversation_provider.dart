import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../utils/conversation_list_utils.dart';
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

  Future<Conversation?> createConversation([String? title]) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(conversationServiceProvider);
      final newConversation = await service.createConversation(
        title ?? defaultConversationTitle,
      );

      state = state.copyWith(
        conversations: [newConversation, ...state.conversations],
        isLoading: false,
      );
      return newConversation;
    } catch (e) {
      debugPrint('Failed to create conversation: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  Future<void> renameConversation(String id, String title) async {
    try {
      final service = ref.read(conversationServiceProvider);
      await service.updateConversation(id, title: title);

      state = state.copyWith(
        conversations: state.conversations
            .map(
              (c) => c.id == id ? c.copyWith(title: title) : c,
            )
            .toList(),
      );
    } catch (e) {
      debugPrint('Failed to rename conversation: $e');
    }
  }

  Future<void> setConversationPinned(String id, bool isStarred) async {
    try {
      final service = ref.read(conversationServiceProvider);
      await service.updateConversation(id, isStarred: isStarred);

      state = state.copyWith(
        conversations: state.conversations
            .map(
              (c) => c.id == id ? c.copyWith(isStarred: isStarred) : c,
            )
            .toList(),
      );
    } catch (e) {
      debugPrint('Failed to update pin state: $e');
      rethrow;
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
