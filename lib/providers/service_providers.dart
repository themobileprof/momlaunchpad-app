import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/conversation_service.dart';
import '../config/app_config.dart';

/// Storage service provider (singleton)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// API service provider (singleton)
final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiService(baseUrl: AppConfig.baseUrl, storage: storage);
});

/// WebSocket service provider (singleton)
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return WebSocketService(wsUrl: AppConfig.chatWsUrl, storage: storage);
});

/// Conversation service provider (singleton)
final conversationServiceProvider = Provider<ConversationService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ConversationService(baseUrl: AppConfig.baseUrl, storage: storage);
});
