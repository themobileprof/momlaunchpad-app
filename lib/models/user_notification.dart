/// General-purpose user notification (rewards, referral rewards, system messages).
/// Separate from CommunityNotification, which is scoped to community activity.
class UserNotification {
  final String id;
  final String type; // reward | referral_reward | system
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  const UserNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload = const {},
    this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  /// Reward payload accessors (present on reward notifications).
  String? get rewardKind => _string('reward_kind');
  String? get code => _string('code');
  String? get value => _string('value');
  String? get provider => _string('provider');

  DateTime? get expiresAt {
    final raw = _string('expires_at');
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// True when there is structured reward detail worth rendering.
  bool get hasRewardDetail =>
      code != null || value != null || provider != null || expiresAt != null;

  String? _string(String key) {
    final v = payload[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  UserNotification copyWith({DateTime? readAt}) {
    return UserNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      payload: payload,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
