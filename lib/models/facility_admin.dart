/// Health-center admin claim and roster models.
class FacilityAdminClaim {
  final String id;
  final String userId;
  final String healthcareFacilityId;
  final String status;
  final String? roleTitle;
  final String? proofNote;
  final String? proofUrl;
  final String? adminNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userEmail;
  final String? userName;
  final String? userPhone;
  final String? facilityName;
  final String? facilityCity;
  final String? facilityStateProvince;
  final String? facilityCountryCode;

  const FacilityAdminClaim({
    required this.id,
    required this.userId,
    required this.healthcareFacilityId,
    required this.status,
    this.roleTitle,
    this.proofNote,
    this.proofUrl,
    this.adminNote,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userEmail,
    this.userName,
    this.userPhone,
    this.facilityName,
    this.facilityCity,
    this.facilityStateProvince,
    this.facilityCountryCode,
  });

  factory FacilityAdminClaim.fromJson(Map<String, dynamic> json) {
    return FacilityAdminClaim(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      healthcareFacilityId: json['healthcare_facility_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      roleTitle: json['role_title'] as String?,
      proofNote: json['proof_note'] as String?,
      proofUrl: json['proof_url'] as String?,
      adminNote: json['admin_note'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: _asDate(json['reviewed_at']),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      updatedAt: _asDate(json['updated_at']) ?? DateTime.now(),
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
      userPhone: json['user_phone'] as String?,
      facilityName: json['facility_name'] as String?,
      facilityCity: json['facility_city'] as String?,
      facilityStateProvince: json['facility_state_province'] as String?,
      facilityCountryCode: json['facility_country_code'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'revoked':
        return 'Revoked';
      default:
        return 'Pending review';
    }
  }
}

class FacilityMember {
  final String userId;
  final String displayName;
  final String? city;
  final String? phoneNumber;
  final String? journeyStage;
  final DateTime? lastActive;
  final bool facilityAnnouncementsOptIn;

  const FacilityMember({
    required this.userId,
    required this.displayName,
    this.city,
    this.phoneNumber,
    this.journeyStage,
    this.lastActive,
    required this.facilityAnnouncementsOptIn,
  });

  factory FacilityMember.fromJson(Map<String, dynamic> json) {
    return FacilityMember(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Member',
      city: json['city'] as String?,
      phoneNumber: json['phone_number'] as String?,
      journeyStage: json['journey_stage'] as String?,
      lastActive: _asDate(json['last_active']),
      facilityAnnouncementsOptIn:
          json['facility_announcements_opt_in'] as bool? ?? true,
    );
  }
}

class FacilityAnnouncement {
  final String id;
  final String healthcareFacilityId;
  final String sentBy;
  final String title;
  final String body;
  final int recipientCount;
  final DateTime createdAt;

  const FacilityAnnouncement({
    required this.id,
    required this.healthcareFacilityId,
    required this.sentBy,
    required this.title,
    required this.body,
    required this.recipientCount,
    required this.createdAt,
  });

  factory FacilityAnnouncement.fromJson(Map<String, dynamic> json) {
    return FacilityAnnouncement(
      id: json['id'] as String? ?? '',
      healthcareFacilityId: json['healthcare_facility_id'] as String? ?? '',
      sentBy: json['sent_by'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      recipientCount: json['recipient_count'] as int? ?? 0,
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

class FacilityAdminPeer {
  final String userId;
  final String displayName;
  final String? roleTitle;
  final DateTime approvedAt;

  const FacilityAdminPeer({
    required this.userId,
    required this.displayName,
    this.roleTitle,
    required this.approvedAt,
  });

  factory FacilityAdminPeer.fromJson(Map<String, dynamic> json) {
    return FacilityAdminPeer(
      userId: json['user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Admin',
      roleTitle: json['role_title'] as String?,
      approvedAt: _asDate(json['approved_at']) ?? DateTime.now(),
    );
  }
}

class FacilityAdminMe {
  final List<FacilityAdminClaim> claims;
  final List<FacilityAdminClaim> approved;

  const FacilityAdminMe({
    required this.claims,
    required this.approved,
  });
}

class FacilityMembersPage {
  final List<FacilityMember> members;
  final int total;

  const FacilityMembersPage({
    required this.members,
    required this.total,
  });
}

DateTime? _asDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
