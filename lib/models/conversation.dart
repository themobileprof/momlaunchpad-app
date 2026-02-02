class Conversation {
  final String id;
  final String userId;
  final String title;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.isStarred,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      isStarred: json['is_starred'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'is_starred': isStarred,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? title,
    bool? isStarred,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      title: title ?? this.title,
      isStarred: isStarred ?? this.isStarred,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
