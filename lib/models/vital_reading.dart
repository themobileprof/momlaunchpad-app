/// Standalone vital signs reading (manual log from health tracker).
class VitalReading {
  final String id;
  final String userId;
  final DateTime recordedAt;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? weightKg;
  final int? heartRateBpm;
  final double? temperatureCelsius;
  final double? fundalHeightCm;
  final int? fetalHeartRateBpm;
  final int? gestationalAgeWeeks;
  final String? notes;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VitalReading({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.weightKg,
    this.heartRateBpm,
    this.temperatureCelsius,
    this.fundalHeightCm,
    this.fetalHeartRateBpm,
    this.gestationalAgeWeeks,
    this.notes,
    this.source = 'manual',
    required this.createdAt,
    required this.updatedAt,
  });

  factory VitalReading.fromJson(Map<String, dynamic> json) {
    return VitalReading(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      bloodPressureSystolic: json['blood_pressure_systolic'] as int?,
      bloodPressureDiastolic: json['blood_pressure_diastolic'] as int?,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heartRateBpm: json['heart_rate_bpm'] as int?,
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
      fundalHeightCm: (json['fundal_height_cm'] as num?)?.toDouble(),
      fetalHeartRateBpm: json['fetal_heart_rate_bpm'] as int?,
      gestationalAgeWeeks: json['gestational_age_weeks'] as int?,
      notes: json['notes'] as String?,
      source: json['source'] as String? ?? 'manual',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String? get bloodPressureDisplay {
    if (bloodPressureSystolic == null && bloodPressureDiastolic == null) {
      return null;
    }
    return '${bloodPressureSystolic ?? '—'}/${bloodPressureDiastolic ?? '—'} mmHg';
  }

  List<String> get summaryLines {
    final lines = <String>[];
    if (bloodPressureDisplay != null) lines.add(bloodPressureDisplay!);
    if (weightKg != null) lines.add('$weightKg kg');
    if (heartRateBpm != null) lines.add('$heartRateBpm bpm');
    if (temperatureCelsius != null) lines.add('$temperatureCelsius °C');
    if (fundalHeightCm != null) lines.add('Fundal $fundalHeightCm cm');
    if (fetalHeartRateBpm != null) lines.add('FHR $fetalHeartRateBpm bpm');
    if (gestationalAgeWeeks != null) lines.add('$gestationalAgeWeeks wks');
    return lines;
  }
}

/// Payload for creating a vital reading.
class VitalReadingPayload {
  final DateTime recordedAt;
  final int? bloodPressureSystolic;
  final int? bloodPressureDiastolic;
  final double? weightKg;
  final int? heartRateBpm;
  final double? temperatureCelsius;
  final double? fundalHeightCm;
  final int? fetalHeartRateBpm;
  final int? gestationalAgeWeeks;
  final String? notes;

  const VitalReadingPayload({
    required this.recordedAt,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.weightKg,
    this.heartRateBpm,
    this.temperatureCelsius,
    this.fundalHeightCm,
    this.fetalHeartRateBpm,
    this.gestationalAgeWeeks,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'recorded_at': recordedAt.toUtc().toIso8601String(),
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
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
