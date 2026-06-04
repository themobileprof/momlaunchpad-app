import 'community.dart';

/// A user-submitted request to verify a community badge.
class CommunityBadgeRequest {
  final String id;
  final String userId;
  final String badgeType;
  final String status;
  final String? message;
  final String? adminNote;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const CommunityBadgeRequest({
    required this.id,
    required this.userId,
    required this.badgeType,
    required this.status,
    this.message,
    this.adminNote,
    this.reviewedAt,
    required this.createdAt,
  });

  factory CommunityBadgeRequest.fromJson(Map<String, dynamic> json) {
    return CommunityBadgeRequest(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      badgeType: json['badge_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString(),
      adminNote: json['admin_note']?.toString(),
      reviewedAt: _parseOptionalDate(json['reviewed_at']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

/// Plan caps from system_settings (admin-configurable).
class CommunityBadgeLimits {
  final int free;
  final int premium;

  const CommunityBadgeLimits({this.free = 1, this.premium = 5});

  factory CommunityBadgeLimits.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CommunityBadgeLimits();
    return CommunityBadgeLimits(
      free: json['free'] as int? ?? 1,
      premium: json['premium'] as int? ?? 5,
    );
  }
}

/// Badges the user holds plus request history and types they may request.
class MyCommunityBadges {
  final List<String> badges;
  final List<CommunityBadgeRequest> requests;
  final List<CommunityCatalogItem> requestableTypes;
  final bool isPremium;
  final int badgeLimit;
  final int badgeSlotsUsed;
  final bool canRequestMoreBadges;
  final CommunityBadgeLimits badgeLimits;

  const MyCommunityBadges({
    this.badges = const [],
    this.requests = const [],
    this.requestableTypes = const [],
    this.isPremium = false,
    this.badgeLimit = 1,
    this.badgeSlotsUsed = 0,
    this.canRequestMoreBadges = true,
    this.badgeLimits = const CommunityBadgeLimits(),
  });

  factory MyCommunityBadges.fromJson(Map<String, dynamic> json) {
    final limit = json['badge_limit'] as int? ??
        json['badge_request_limit'] as int? ??
        1;
    final used = json['badge_slots_used'] as int? ??
        json['badge_request_pending'] as int? ??
        0;
    return MyCommunityBadges(
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      requests: (json['requests'] as List<dynamic>? ?? [])
          .map((e) => CommunityBadgeRequest.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      requestableTypes: (json['requestable_types'] as List<dynamic>? ?? [])
          .map((e) => CommunityCatalogItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      isPremium: json['is_premium'] as bool? ?? false,
      badgeLimit: limit,
      badgeSlotsUsed: used,
      canRequestMoreBadges:
          json['can_request_more_badges'] as bool? ?? used < limit,
      badgeLimits: CommunityBadgeLimits.fromJson(
        json['badge_limits'] as Map<String, dynamic>?,
      ),
    );
  }

  CommunityBadgeRequest? pendingRequestFor(String badgeType) {
    for (final r in requests) {
      if (r.badgeType == badgeType && r.isPending) return r;
    }
    return null;
  }
}

DateTime? _parseOptionalDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
