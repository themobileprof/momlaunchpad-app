/// Medication prescribed or noted during a visit.
class VisitMedication {
  final String name;
  final String dosage;
  final String frequency;
  final String? route;
  final String? duration;
  final String? instructions;

  const VisitMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.route,
    this.duration,
    this.instructions,
  });

  factory VisitMedication.fromJson(Map<String, dynamic> json) {
    return VisitMedication(
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      route: json['route'] as String?,
      duration: json['duration'] as String?,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        if (route != null && route!.isNotEmpty) 'route': route,
        if (duration != null && duration!.isNotEmpty) 'duration': duration,
        if (instructions != null && instructions!.isNotEmpty)
          'instructions': instructions,
      };

  VisitMedication copyWith({
    String? name,
    String? dosage,
    String? frequency,
    String? route,
    String? duration,
    String? instructions,
  }) {
    return VisitMedication(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      route: route ?? this.route,
      duration: duration ?? this.duration,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// Lab result recorded during a visit.
class VisitLabResult {
  final String testName;
  final String result;
  final String? unit;
  final String? referenceRange;
  final String? notes;

  const VisitLabResult({
    required this.testName,
    required this.result,
    this.unit,
    this.referenceRange,
    this.notes,
  });

  factory VisitLabResult.fromJson(Map<String, dynamic> json) {
    return VisitLabResult(
      testName: json['test_name'] as String? ?? '',
      result: json['result'] as String? ?? '',
      unit: json['unit'] as String?,
      referenceRange: json['reference_range'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'test_name': testName,
        'result': result,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        if (referenceRange != null && referenceRange!.isNotEmpty)
          'reference_range': referenceRange,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  VisitLabResult copyWith({
    String? testName,
    String? result,
    String? unit,
    String? referenceRange,
    String? notes,
  }) {
    return VisitLabResult(
      testName: testName ?? this.testName,
      result: result ?? this.result,
      unit: unit ?? this.unit,
      referenceRange: referenceRange ?? this.referenceRange,
      notes: notes ?? this.notes,
    );
  }
}

/// Ordered test that is not yet completed (post-visit debrief).
class VisitPendingTest {
  final String testName;
  final DateTime? dueBy;
  final String status; // pending, done, skipped
  final String? notes;

  const VisitPendingTest({
    required this.testName,
    this.dueBy,
    this.status = 'pending',
    this.notes,
  });

  factory VisitPendingTest.fromJson(Map<String, dynamic> json) {
    return VisitPendingTest(
      testName: json['test_name'] as String? ?? '',
      dueBy: json['due_by'] != null
          ? DateTime.parse(json['due_by'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'test_name': testName,
        if (dueBy != null) 'due_by': dueBy!.toUtc().toIso8601String(),
        'status': status,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

/// Body for saving a post-visit debrief from the home check-in card.
class VisitDebriefPayload {
  final List<VisitPendingTest> pendingTests;
  final List<VisitMedication> medications;
  final bool markCompleted;

  const VisitDebriefPayload({
    this.pendingTests = const [],
    this.medications = const [],
    this.markCompleted = true,
  });

  Map<String, dynamic> toJson() => {
        'pending_tests': pendingTests.map((t) => t.toJson()).toList(),
        if (medications.isNotEmpty)
          'medications': medications.map((m) => m.toJson()).toList(),
        'mark_completed': markCompleted,
      };
}

/// Doctor / prenatal visit record (micro EMR).
class DoctorVisit {
  final String id;
  final String userId;
  final DateTime visitDate;
  final String visitType;
  final String? providerName;
  final String? facilityName;
  final String? chiefComplaint;
  final String? clinicalNotes;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? followUpInstructions;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? weightKg;
  final int? heartRateBpm;
  final double? temperatureCelsius;
  final double? fundalHeightCm;
  final int? fetalHeartRateBpm;
  final int? gestationalAgeWeeks;
  final List<VisitMedication> medications;
  final List<VisitLabResult> labResults;
  final List<VisitPendingTest> pendingTests;
  final DateTime? nextAppointmentAt;
  final String? nextAppointmentNotes;
  final DateTime? debriefCompletedAt;
  final String recordedBy;
  final String? providerUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorVisit({
    required this.id,
    required this.userId,
    required this.visitDate,
    required this.visitType,
    this.providerName,
    this.facilityName,
    this.chiefComplaint,
    this.clinicalNotes,
    this.diagnosis,
    this.treatmentPlan,
    this.followUpInstructions,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.weightKg,
    this.heartRateBpm,
    this.temperatureCelsius,
    this.fundalHeightCm,
    this.fetalHeartRateBpm,
    this.gestationalAgeWeeks,
    this.medications = const [],
    this.labResults = const [],
    this.pendingTests = const [],
    this.nextAppointmentAt,
    this.nextAppointmentNotes,
    this.debriefCompletedAt,
    this.recordedBy = 'user',
    this.providerUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorVisit.fromJson(Map<String, dynamic> json) {
    return DoctorVisit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      visitDate: DateTime.parse(json['visit_date'] as String),
      visitType: json['visit_type'] as String,
      providerName: json['provider_name'] as String?,
      facilityName: json['facility_name'] as String?,
      chiefComplaint: json['chief_complaint'] as String?,
      clinicalNotes: json['clinical_notes'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatmentPlan: json['treatment_plan'] as String?,
      followUpInstructions: json['follow_up_instructions'] as String?,
      bloodPressureSystolic: json['blood_pressure_systolic'] as int?,
      bloodPressureDiastolic: json['blood_pressure_diastolic'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heartRateBpm: json['heart_rate_bpm'] as int?,
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
      fundalHeightCm: (json['fundal_height_cm'] as num?)?.toDouble(),
      fetalHeartRateBpm: json['fetal_heart_rate_bpm'] as int?,
      gestationalAgeWeeks: json['gestational_age_weeks'] as int?,
      medications: (json['medications'] as List<dynamic>? ?? [])
          .map((e) => VisitMedication.fromJson(e as Map<String, dynamic>))
          .toList(),
      labResults: (json['lab_results'] as List<dynamic>? ?? [])
          .map((e) => VisitLabResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingTests: (json['pending_tests'] as List<dynamic>? ?? [])
          .map((e) => VisitPendingTest.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextAppointmentAt: json['next_appointment_at'] != null
          ? DateTime.parse(json['next_appointment_at'] as String)
          : null,
      nextAppointmentNotes: json['next_appointment_notes'] as String?,
      debriefCompletedAt: json['debrief_completed_at'] != null
          ? DateTime.parse(json['debrief_completed_at'] as String)
          : null,
      recordedBy: json['recorded_by'] as String? ?? 'user',
      providerUserId: json['provider_user_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get visitTypeLabel =>
      doctorVisitTypeLabels[visitType] ?? _titleCase(visitType);

  String? get bloodPressureDisplay {
    if (bloodPressureSystolic == null && bloodPressureDiastolic == null) {
      return null;
    }
    return '${bloodPressureSystolic ?? '—'}/${bloodPressureDiastolic ?? '—'}';
  }

  bool get hasUpcomingAppointment {
    if (nextAppointmentAt == null) return false;
    return nextAppointmentAt!.isAfter(DateTime.now());
  }

  bool get needsDebrief {
    if (debriefCompletedAt != null) return false;
    final daysSince =
        DateTime.now().difference(visitDate.toLocal()).inDays;
    return daysSince >= 0 && daysSince <= 14;
  }

  bool get isProviderRecorded => recordedBy == 'provider';

  static String _titleCase(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

/// Payload for creating or updating a visit record.
class DoctorVisitPayload {
  final DateTime visitDate;
  final String visitType;
  final String? providerName;
  final String? facilityName;
  final String? chiefComplaint;
  final String? clinicalNotes;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? followUpInstructions;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? weightKg;
  final int? heartRateBpm;
  final double? temperatureCelsius;
  final double? fundalHeightCm;
  final int? fetalHeartRateBpm;
  final int? gestationalAgeWeeks;
  final List<VisitMedication> medications;
  final List<VisitLabResult> labResults;
  final DateTime? nextAppointmentAt;
  final String? nextAppointmentNotes;

  const DoctorVisitPayload({
    required this.visitDate,
    required this.visitType,
    this.providerName,
    this.facilityName,
    this.chiefComplaint,
    this.clinicalNotes,
    this.diagnosis,
    this.treatmentPlan,
    this.followUpInstructions,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.weightKg,
    this.heartRateBpm,
    this.temperatureCelsius,
    this.fundalHeightCm,
    this.fetalHeartRateBpm,
    this.gestationalAgeWeeks,
    this.medications = const [],
    this.labResults = const [],
    this.nextAppointmentAt,
    this.nextAppointmentNotes,
  });

  factory DoctorVisitPayload.fromVisit(DoctorVisit visit) {
    return DoctorVisitPayload(
      visitDate: visit.visitDate,
      visitType: visit.visitType,
      providerName: visit.providerName,
      facilityName: visit.facilityName,
      chiefComplaint: visit.chiefComplaint,
      clinicalNotes: visit.clinicalNotes,
      diagnosis: visit.diagnosis,
      treatmentPlan: visit.treatmentPlan,
      followUpInstructions: visit.followUpInstructions,
      bloodPressureSystolic: visit.bloodPressureSystolic,
      bloodPressureDiastolic: visit.bloodPressureDiastolic,
      weightKg: visit.weightKg,
      heartRateBpm: visit.heartRateBpm,
      temperatureCelsius: visit.temperatureCelsius,
      fundalHeightCm: visit.fundalHeightCm,
      fetalHeartRateBpm: visit.fetalHeartRateBpm,
      gestationalAgeWeeks: visit.gestationalAgeWeeks,
      medications: visit.medications,
      labResults: visit.labResults,
      nextAppointmentAt: visit.nextAppointmentAt,
      nextAppointmentNotes: visit.nextAppointmentNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'visit_date': visitDate.toUtc().toIso8601String(),
        'visit_type': visitType,
        if (providerName != null && providerName!.isNotEmpty)
          'provider_name': providerName,
        if (facilityName != null && facilityName!.isNotEmpty)
          'facility_name': facilityName,
        if (chiefComplaint != null && chiefComplaint!.isNotEmpty)
          'chief_complaint': chiefComplaint,
        if (clinicalNotes != null && clinicalNotes!.isNotEmpty)
          'clinical_notes': clinicalNotes,
        if (diagnosis != null && diagnosis!.isNotEmpty) 'diagnosis': diagnosis,
        if (treatmentPlan != null && treatmentPlan!.isNotEmpty)
          'treatment_plan': treatmentPlan,
        if (followUpInstructions != null && followUpInstructions!.isNotEmpty)
          'follow_up_instructions': followUpInstructions,
        if (bloodPressureSystolic != null)
          'blood_pressure_systolic': bloodPressureSystolic,
        if (bloodPressureDiastolic != null)
          'blood_pressure_diastolic': bloodPressureDiastolic,
        if (weightKg != null) 'weight_kg': weightKg,
        if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
        if (temperatureCelsius != null)
          'temperature_celsius': temperatureCelsius,
        if (fundalHeightCm != null) 'fundal_height_cm': fundalHeightCm,
        if (fetalHeartRateBpm != null)
          'fetal_heart_rate_bpm': fetalHeartRateBpm,
        if (gestationalAgeWeeks != null)
          'gestational_age_weeks': gestationalAgeWeeks,
        'medications': medications.map((m) => m.toJson()).toList(),
        'lab_results': labResults.map((l) => l.toJson()).toList(),
        if (nextAppointmentAt != null)
          'next_appointment_at': nextAppointmentAt!.toUtc().toIso8601String(),
        if (nextAppointmentNotes != null && nextAppointmentNotes!.isNotEmpty)
          'next_appointment_notes': nextAppointmentNotes,
      };
}

const doctorVisitTypes = [
  'prenatal_checkup',
  'ultrasound',
  'lab_work',
  'specialist',
  'emergency',
  'postpartum',
  'other',
];

const doctorVisitTypeLabels = {
  'prenatal_checkup': 'Prenatal checkup',
  'ultrasound': 'Ultrasound',
  'lab_work': 'Lab work',
  'specialist': 'Specialist visit',
  'emergency': 'Emergency',
  'postpartum': 'Postpartum',
  'other': 'Other',
};
