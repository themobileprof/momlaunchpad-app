/// Message model for chat
class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'is_streaming': isStreaming,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isStreaming: json['is_streaming'] as bool? ?? false,
    );
  }
}

/// WebSocket message types from backend
enum MessageType {
  message, // AI response chunk
  done, // Response complete
  calendar, // Calendar suggestion
  error, // Error message
}

/// WebSocket message wrapper
class WebSocketMessage {
  final MessageType type;
  final String? content;
  final Map<String, dynamic>? data;
  final String? message;

  WebSocketMessage({
    required this.type,
    this.content,
    this.data,
    this.message,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final type = MessageType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => MessageType.error,
    );

    return WebSocketMessage(
      type: type,
      content: json['content'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      message: json['message'] as String?,
    );
  }
}
