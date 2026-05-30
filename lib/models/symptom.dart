/// Symptom model matching backend API response
class Symptom {
  final String id;
  final String symptomType;
  final String description;
  final String severity;
  final String frequency;
  final String? onsetTime;
  final List<String> associatedSymptoms;
  final bool isResolved;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? summary;
  final String? conversationId;
  final String? messageId;

  Symptom({
    required this.id,
    required this.symptomType,
    required this.description,
    required this.severity,
    required this.frequency,
    this.onsetTime,
    required this.associatedSymptoms,
    required this.isResolved,
    required this.reportedAt,
    this.resolvedAt,
    this.summary,
    this.conversationId,
    this.messageId,
  });

  bool get hasSourceChat =>
      conversationId != null && conversationId!.trim().isNotEmpty;

  /// One-sentence display text for health tracker UI.
  String get displayText => (summary != null && summary!.trim().isNotEmpty)
      ? summary!.trim()
      : description;

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as String,
      symptomType: json['symptom_type'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String? ?? 'unknown',
      frequency: json['frequency'] as String? ?? 'unknown',
      onsetTime: json['onset_time'] as String?,
      associatedSymptoms: (json['associated_symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isResolved: json['is_resolved'] as bool,
      reportedAt: DateTime.parse(json['reported_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      summary: json['summary'] as String?,
      conversationId: json['conversation_id'] as String?,
      messageId: json['message_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symptom_type': symptomType,
      'description': description,
      'severity': severity,
      'frequency': frequency,
      'onset_time': onsetTime,
      'associated_symptoms': associatedSymptoms,
      'is_resolved': isResolved,
      'reported_at': reportedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'summary': summary,
      'conversation_id': conversationId,
      'message_id': messageId,
    };
  }

  Symptom copyWith({
    String? id,
    String? symptomType,
    String? description,
    String? severity,
    String? frequency,
    String? onsetTime,
    List<String>? associatedSymptoms,
    bool? isResolved,
    DateTime? reportedAt,
    DateTime? resolvedAt,
    String? summary,
    String? conversationId,
    String? messageId,
  }) {
    return Symptom(
      id: id ?? this.id,
      symptomType: symptomType ?? this.symptomType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      frequency: frequency ?? this.frequency,
      onsetTime: onsetTime ?? this.onsetTime,
      associatedSymptoms: associatedSymptoms ?? this.associatedSymptoms,
      isResolved: isResolved ?? this.isResolved,
      reportedAt: reportedAt ?? this.reportedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      summary: summary ?? this.summary,
      conversationId: conversationId ?? this.conversationId,
      messageId: messageId ?? this.messageId,
    );
  }

  /// Get user-friendly symptom type name
  String get symptomTypeName {
    return symptomType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get severity color
  String get severityColor {
    switch (severity) {
      case 'mild':
        return '#4CAF50'; // Green
      case 'moderate':
        return '#FF9800'; // Orange
      case 'severe':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Gray
    }
  }
}

/// Symptom statistics
class SymptomStats {
  final int totalSymptoms;
  final int ongoing;
  final int resolved;
  final Map<String, int> byType;
  final Map<String, int> bySeverity;

  SymptomStats({
    required this.totalSymptoms,
    required this.ongoing,
    required this.resolved,
    required this.byType,
    required this.bySeverity,
  });

  factory SymptomStats.fromJson(Map<String, dynamic> json) {
    return SymptomStats(
      totalSymptoms: json['total_symptoms'] as int,
      ongoing: json['ongoing'] as int,
      resolved: json['resolved'] as int,
      byType: Map<String, int>.from(json['by_type'] as Map),
      bySeverity: Map<String, int>.from(json['by_severity'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_symptoms': totalSymptoms,
      'ongoing': ongoing,
      'resolved': resolved,
      'by_type': byType,
      'by_severity': bySeverity,
    };
  }
}
