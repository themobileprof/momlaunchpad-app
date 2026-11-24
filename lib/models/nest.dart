/// Delivery nest (EDD savings tribe) owned by a mom.
class Nest {
  final String id;
  final String title;
  final double goalAmount;
  final double? monthlyTargetAmount;
  final String currency;
  final DateTime? expectedDeliveryDate;
  final int reminderDayOfMonth;
  final String status;
  final String inviteToken;
  final String inviteLink;
  final double totalRaised;
  final double progressPercentage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Nest({
    required this.id,
    required this.title,
    required this.goalAmount,
    this.monthlyTargetAmount,
    required this.currency,
    this.expectedDeliveryDate,
    required this.reminderDayOfMonth,
    required this.status,
    required this.inviteToken,
    required this.inviteLink,
    required this.totalRaised,
    required this.progressPercentage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Nest.fromJson(Map<String, dynamic> json) {
    return Nest(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      goalAmount: _asDouble(json['goal_amount']),
      monthlyTargetAmount: json['monthly_target_amount'] != null
          ? _asDouble(json['monthly_target_amount'])
          : null,
      currency: json['currency'] as String? ?? 'NGN',
      expectedDeliveryDate: _asDate(json['expected_delivery_date']),
      reminderDayOfMonth: json['reminder_day_of_month'] as int? ?? 28,
      status: json['status'] as String? ?? 'active',
      inviteToken: json['invite_token'] as String? ?? '',
      inviteLink: json['invite_link'] as String? ?? '',
      totalRaised: _asDouble(json['total_raised']),
      progressPercentage: _asDouble(json['progress_percentage']),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _asDate(json['updated_at']) ?? DateTime.now(),
    );
  }

  Nest copyWith({
    String? inviteToken,
    String? inviteLink,
  }) {
    return Nest(
      id: id,
      title: title,
      goalAmount: goalAmount,
      monthlyTargetAmount: monthlyTargetAmount,
      currency: currency,
      expectedDeliveryDate: expectedDeliveryDate,
      reminderDayOfMonth: reminderDayOfMonth,
      status: status,
      inviteToken: inviteToken ?? this.inviteToken,
      inviteLink: inviteLink ?? this.inviteLink,
      totalRaised: totalRaised,
      progressPercentage: progressPercentage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class NestContribution {
  final String id;
  final double amount;
  final String currency;
  final String? note;
  final String status;
  final String contributorName;
  final String recordedBy;
  final DateTime createdAt;

  const NestContribution({
    required this.id,
    required this.amount,
    required this.currency,
    this.note,
    required this.status,
    required this.contributorName,
    required this.recordedBy,
    required this.createdAt,
  });

  factory NestContribution.fromJson(Map<String, dynamic> json) {
    return NestContribution(
      id: json['id'] as String? ?? '',
      amount: _asDouble(json['amount']),
      currency: json['currency'] as String? ?? 'NGN',
      note: json['note'] as String?,
      status: json['status'] as String? ?? 'recorded',
      contributorName: json['contributor_name'] as String? ?? '',
      recordedBy: json['recorded_by'] as String? ?? '',
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class NestContributor {
  final String id;
  final String displayName;
  final String? email;
  final String? phone;

  const NestContributor({
    required this.id,
    required this.displayName,
    this.email,
    this.phone,
  });

  factory NestContributor.fromJson(Map<String, dynamic> json) {
    return NestContributor(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class NestActivity {
  final List<NestContribution> contributions;
  final List<NestContributor> contributors;

  const NestActivity({
    required this.contributions,
    required this.contributors,
  });
}

/// Waitlist / interest survey while Nest is not live.
class NestInterestResponse {
  final String id;
  final String userId;
  final String interested;
  final String? moreInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NestInterestResponse({
    required this.id,
    required this.userId,
    required this.interested,
    this.moreInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NestInterestResponse.fromJson(Map<String, dynamic> json) {
    return NestInterestResponse(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      interested: json['interested'] as String? ?? '',
      moreInfo: json['more_info'] as String?,
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _asDate(json['updated_at']) ?? DateTime.now(),
    );
  }
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? _asDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
