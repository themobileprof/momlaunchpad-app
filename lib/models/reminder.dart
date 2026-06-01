/// Reminder/Calendar entry model matching backend DTO
class Reminder {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final bool isCompleted;
  final String? communityEventId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledTime,
    required this.priority,
    required this.isCompleted,
    this.communityEventId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: DateTime.parse(json['reminder_time'] as String),
      priority: json['priority'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      communityEventId: json['community_event_id']?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      if (description != null) 'description': description,
      'reminder_time': scheduledTime.toIso8601String(),
      'priority': priority,
      'is_completed': isCompleted,
      if (communityEventId != null) 'community_event_id': communityEventId,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? priority,
    bool? isCompleted,
    String? communityEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      communityEventId: communityEventId ?? this.communityEventId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isOverdue {
    return !isCompleted && scheduledTime.isBefore(DateTime.now());
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledTime.year == now.year &&
        scheduledTime.month == now.month &&
        scheduledTime.day == now.day;
  }
}

/// Calendar suggestion from AI (via WebSocket)
class CalendarSuggestion {
  final String title;
  final String? description;
  final DateTime suggestedTime;
  final String priority;
  final String? reason;

  CalendarSuggestion({
    required this.title,
    this.description,
    required this.suggestedTime,
    required this.priority,
    this.reason,
  });

  factory CalendarSuggestion.fromJson(Map<String, dynamic> json) {
    return CalendarSuggestion(
      title: json['title'] as String,
      description: json['description'] as String?,
      suggestedTime: DateTime.parse(json['suggested_time'] as String),
      priority: json['priority'] as String? ?? 'medium',
      reason: json['reason'] as String?,
    );
  }

  /// Convert suggestion to a Reminder (after user confirms)
  Reminder toReminder(String userId) {
    final now = DateTime.now();
    return Reminder(
      id: '', // Will be assigned by backend
      userId: userId,
      title: title,
      description: description,
      scheduledTime: suggestedTime,
      priority: priority,
      isCompleted: false,
      createdAt: now,
    );
  }
}
