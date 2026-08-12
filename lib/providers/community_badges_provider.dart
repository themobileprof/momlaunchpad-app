import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_badge_request.dart';
import 'service_providers.dart';

final myCommunityBadgesProvider =
    FutureProvider<MyCommunityBadges>((ref) async {
  return ref.read(apiServiceProvider).getMyCommunityBadges();
});
