import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';

/// Storage service provider (singleton)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// API service provider (singleton)
final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  // TODO: Replace with actual backend URL
  const baseUrl = 'http://localhost:8080';
  return ApiService(baseUrl: baseUrl, storage: storage);
});

/// WebSocket service provider (singleton)
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  // TODO: Replace with actual backend WebSocket URL
  const wsUrl = 'ws://localhost:8080';
  return WebSocketService(wsUrl: wsUrl, storage: storage);
});
