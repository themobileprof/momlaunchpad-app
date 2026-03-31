import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import 'storage_service.dart';

/// WebSocket service for real-time chat
/// Handles connection, streaming responses, and reconnection
class WebSocketService {
  final String wsUrl;
  final StorageService _storage;

  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  bool _isConnecting = false; // Prevent duplicate connection attempts
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelaySecondsPerAttempt = 3;
  DateTime? _lastConnectionAttempt;

  // Rate limiting (10 messages per minute)
  DateTime? _lastMessageTime;
  int _messageCount = 0;

  WebSocketService({
    required this.wsUrl,
    required StorageService storage,
  }) : _storage = storage;

  bool get isConnected => _isConnected;

  Stream<WebSocketMessage> get messages {
    _messageController ??= StreamController<WebSocketMessage>.broadcast();
    return _messageController!.stream;
  }

  /// Connect to WebSocket with JWT token and optional conversation ID
  Future<void> connect({String? conversationId}) async {
    // Prevent duplicate connection attempts
    if (_isConnecting || _isConnected) {
      debugPrint('Connection already in progress or connected');
      return;
    }

    // Minimum 5 seconds between connection attempts
    if (_lastConnectionAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastConnectionAttempt!);
      if (timeSinceLastAttempt < const Duration(seconds: 5)) {
        debugPrint('Too soon to reconnect. Wait ${5 - timeSinceLastAttempt.inSeconds} more seconds');
        return;
      }
    }

    _isConnecting = true;
    _lastConnectionAttempt = DateTime.now();

    try {
      final token = await _storage.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Parse base URL and add token as query parameter
      final baseUri = Uri.parse(wsUrl);
      final queryParams = {'token': token};
      if (conversationId != null) {
        queryParams['conversation_id'] = conversationId;
      }
      
      final uri = baseUri.replace(queryParameters: queryParams);
      
      debugPrint('Connecting to WebSocket: $uri');
      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      debugPrint('WebSocket connected');
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _isConnected = false;
      _isConnecting = false;
      _attemptReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleIncomingMessage(Object? data) {
    try {
      debugPrint('Received raw WebSocket data: $data');
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      debugPrint('Parsed JSON: $json');
      final message = WebSocketMessage.fromJson(json);
      debugPrint('WebSocket message type: ${message.type}, content: ${message.content}');
      _messageController?.add(message);
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(Object? error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    _attemptReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    
    if (_shouldReconnect) {
      _attemptReconnect();
    }
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _messageController?.add(WebSocketMessage(
        type: MessageType.error,
        message: 'Connection lost. Please check your internet and try again.',
      ));
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * _reconnectDelaySecondsPerAttempt);
    
    debugPrint('Reconnecting in ${delay.inSeconds} seconds... (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    
    Timer(delay, () {
      if (_shouldReconnect) {
        connect();
      }
    });
  }

  /// Send message to backend
  /// Returns false if rate limited
  bool sendMessage(String content) {
    if (!_isConnected) {
      debugPrint('Cannot send message: WebSocket not connected');
      return false;
    }

    if (!canSendMessage()) {
      debugPrint('Rate limit exceeded');
      _messageController?.add(WebSocketMessage(
        type: MessageType.error,
        message: 'You\'re sending messages too quickly. Please wait a moment.',
      ));
      return false;
    }

    try {
      final message = jsonEncode({'content': content});
      debugPrint('Sending message to WebSocket: $message');
      _channel!.sink.add(message);
      _messageCount++;
      _lastMessageTime = DateTime.now();
      debugPrint('Message sent successfully');
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Check if user can send message (rate limiting)
  bool canSendMessage() {
    final now = DateTime.now();
    
    // Reset counter every minute
    if (_lastMessageTime == null || 
        now.difference(_lastMessageTime!) > const Duration(minutes: 1)) {
      _messageCount = 0;
      _lastMessageTime = now;
    }
    
    // 10 messages per minute limit
    return _messageCount < 10;
  }

  /// Get remaining messages in current minute
  int getRemainingMessages() {
    if (!canSendMessage()) return 0;
    return 10 - _messageCount;
  }

  /// Disconnect WebSocket
  void disconnect() {
    _shouldReconnect = false;
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _messageController?.close();
    _messageController = null;
  }
}
