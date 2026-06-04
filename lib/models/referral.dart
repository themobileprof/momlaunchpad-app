/// Referral reward history entry from the API.
class ReferralRewardRecord {
  final int id;
  final String userId;
  final int referralsCount;
  final String rewardDescription;
  final String rewardedByAdminId;
  final DateTime createdAt;

  ReferralRewardRecord({
    required this.id,
    required this.userId,
    required this.referralsCount,
    required this.rewardDescription,
    required this.rewardedByAdminId,
    required this.createdAt,
  });

  factory ReferralRewardRecord.fromJson(Map<String, dynamic> json) {
    return ReferralRewardRecord(
      id: json['id'] as int? ?? 0,
      userId: json['user_id']?.toString() ?? '',
      referralsCount: json['referrals_count'] as int? ?? 0,
      rewardDescription: json['reward_description']?.toString() ?? '',
      rewardedByAdminId: json['rewarded_by_admin_id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
