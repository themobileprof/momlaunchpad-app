/// Community feed filter tabs.
enum CommunityFeedFilter {
  forYou('for_you', 'For You'),
  nearby('nearby', 'Nearby'),
  events('events', 'Events'),
  myPosts('my_posts', 'My Posts');

  final String apiValue;
  final String label;
  const CommunityFeedFilter(this.apiValue, this.label);
}

/// Author shown on posts and replies.
class CommunityAuthor {
  final String? id;
  final String displayName;
  final String? photoUrl;
  final List<String> badges;

  const CommunityAuthor({
    this.id,
    required this.displayName,
    this.photoUrl,
    this.badges = const [],
  });

  factory CommunityAuthor.fromJson(Map<String, dynamic> json) {
    return CommunityAuthor(
      id: json['id']?.toString(),
      displayName: json['display_name']?.toString() ?? 'Anonymous Mom',
      photoUrl: json['photo_url']?.toString(),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// A community feed post.
class CommunityPost {
  final String id;
  final String body;
  final bool isAnonymous;
  final String category;
  final String scope;
  final String medicalRelevance;
  final bool isEvent;
  final int likeCount;
  final int replyCount;
  final bool likedByMe;
  final String? country;
  final String? stateProvince;
  final String? city;
  final DateTime createdAt;
  final CommunityAuthor author;

  const CommunityPost({
    required this.id,
    required this.body,
    required this.isAnonymous,
    required this.category,
    required this.scope,
    required this.medicalRelevance,
    required this.isEvent,
    required this.likeCount,
    required this.replyCount,
    required this.likedByMe,
    this.country,
    this.stateProvince,
    this.city,
    required this.createdAt,
    required this.author,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'].toString(),
      body: json['body']?.toString() ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      category: json['category']?.toString() ?? '',
      scope: json['scope']?.toString() ?? 'local',
      medicalRelevance: json['medical_relevance']?.toString() ?? 'none',
      isEvent: json['is_event'] as bool? ?? false,
      likeCount: json['like_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      country: json['country']?.toString(),
      stateProvince: json['state_province']?.toString(),
      city: json['city']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      author: CommunityAuthor.fromJson(
        Map<String, dynamic>.from(json['author'] as Map? ?? {}),
      ),
    );
  }

  String get locationLabel {
    final parts = [city, stateProvince, country]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}

/// Flat reply on a post.
class CommunityReply {
  final String id;
  final String postId;
  final String body;
  final bool isAnonymous;
  final int likeCount;
  final bool likedByMe;
  final DateTime createdAt;
  final CommunityAuthor author;

  const CommunityReply({
    required this.id,
    required this.postId,
    required this.body,
    required this.isAnonymous,
    required this.likeCount,
    required this.likedByMe,
    required this.createdAt,
    required this.author,
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    return CommunityReply(
      id: json['id'].toString(),
      postId: json['post_id'].toString(),
      body: json['body']?.toString() ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      likeCount: json['like_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'].toString()),
      author: CommunityAuthor.fromJson(
        Map<String, dynamic>.from(json['author'] as Map? ?? {}),
      ),
    );
  }
}

/// Local event linked to a post.
class CommunityEvent {
  final String id;
  final String postId;
  final String? eventType;
  final String title;
  final String? description;
  final String? venue;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? country;
  final String? stateProvince;
  final String? city;
  final int interestedCount;
  final bool interestedByMe;

  const CommunityEvent({
    required this.id,
    required this.postId,
    this.eventType,
    required this.title,
    this.description,
    this.venue,
    required this.startsAt,
    this.endsAt,
    this.country,
    this.stateProvince,
    this.city,
    required this.interestedCount,
    required this.interestedByMe,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id'].toString(),
      postId: json['post_id'].toString(),
      eventType: json['event_type']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      venue: json['venue']?.toString(),
      startsAt: DateTime.parse(json['starts_at'].toString()),
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'].toString())
          : null,
      country: json['country']?.toString(),
      stateProvince: json['state_province']?.toString(),
      city: json['city']?.toString(),
      interestedCount: json['interested_count'] as int? ?? 0,
      interestedByMe: json['interested_by_me'] as bool? ?? false,
    );
  }
}

/// Interest catalog group from API.
class CommunityInterestGroup {
  final String key;
  final String label;
  final List<CommunityInterest> items;

  const CommunityInterestGroup({
    required this.key,
    required this.label,
    required this.items,
  });

  factory CommunityInterestGroup.fromJson(Map<String, dynamic> json) {
    return CommunityInterestGroup(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => CommunityInterestItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class CommunityInterest {
  final String key;
  final String label;

  const CommunityInterest({required this.key, required this.label});

  factory CommunityInterest.fromJson(Map<String, dynamic> json) {
    return CommunityInterest(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

/// Alias for catalog interest items returned by the API.
typedef CommunityInterestItem = CommunityInterest;

/// Community onboarding / status from API.
class CommunityStatus {
  final bool onboardingCompleted;
  final String? country;
  final String? stateProvince;
  final String? city;
  final List<String> interests;

  const CommunityStatus({
    required this.onboardingCompleted,
    this.country,
    this.stateProvince,
    this.city,
    this.interests = const [],
  });

  factory CommunityStatus.fromJson(Map<String, dynamic> json) {
    return CommunityStatus(
      onboardingCompleted:
          json['community_onboarding_completed'] as bool? ?? false,
      country: json['country']?.toString(),
      stateProvince: json['state_province']?.toString(),
      city: json['city']?.toString(),
      interests: (json['interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class CommunityNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  const CommunityNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.payload = const {},
    this.readAt,
    required this.createdAt,
  });

  factory CommunityNotification.fromJson(Map<String, dynamic> json) {
    return CommunityNotification(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class CommunityFeedPage {
  final List<CommunityPost> posts;
  final String? nextCursor;

  const CommunityFeedPage({required this.posts, this.nextCursor});
}

class CreatePostPayload {
  final String body;
  final bool isAnonymous;
  final CreateEventPayload? event;

  const CreatePostPayload({
    required this.body,
    this.isAnonymous = false,
    this.event,
  });

  Map<String, dynamic> toJson() => {
        'body': body,
        'is_anonymous': isAnonymous,
        if (event != null) 'event': event!.toJson(),
      };
}

class CreateEventPayload {
  final String eventType;
  final String title;
  final String? description;
  final String? venue;
  final DateTime startsAt;
  final DateTime? endsAt;

  const CreateEventPayload({
    required this.eventType,
    required this.title,
    this.description,
    this.venue,
    required this.startsAt,
    this.endsAt,
  });

  Map<String, dynamic> toJson() => {
        'event_type': eventType,
        'title': title,
        if (description != null) 'description': description,
        if (venue != null) 'venue': venue,
        'starts_at': startsAt.toUtc().toIso8601String(),
        if (endsAt != null) 'ends_at': endsAt!.toUtc().toIso8601String(),
      };
}

class CommunityCountryOption {
  final String code;
  final String name;

  const CommunityCountryOption({required this.code, required this.name});

  factory CommunityCountryOption.fromJson(Map<String, dynamic> json) {
    return CommunityCountryOption(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class CommunityRegionOption {
  final String id;
  final String countryCode;
  final String code;
  final String name;

  const CommunityRegionOption({
    required this.id,
    required this.countryCode,
    required this.code,
    required this.name,
  });

  factory CommunityRegionOption.fromJson(Map<String, dynamic> json) {
    return CommunityRegionOption(
      id: json['id']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class CommunityCatalogItem {
  final String key;
  final String label;
  final String? description;

  const CommunityCatalogItem({
    required this.key,
    required this.label,
    this.description,
  });

  factory CommunityCatalogItem.fromJson(Map<String, dynamic> json) {
    return CommunityCatalogItem(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }
}

/// Badge labels resolved from GET /community/badge-types (no hard-coded map).
class CommunityBadgeCatalog {
  final Map<String, String> labels;

  const CommunityBadgeCatalog(this.labels);

  String labelFor(String key) => labels[key] ?? key;
}
