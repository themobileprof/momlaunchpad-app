import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/models/vital_reading.dart';

void main() {
  test('VitalReading fromJson and summaryLines', () {
    final reading = VitalReading.fromJson({
      'id': 'v1',
      'user_id': 'u1',
      'recorded_at': '2026-05-01T10:00:00Z',
      'blood_pressure_systolic': 120,
      'blood_pressure_diastolic': 80,
      'weight_kg': 68.5,
      'source': 'manual',
      'created_at': '2026-05-01T10:00:00Z',
      'updated_at': '2026-05-01T10:00:00Z',
    });

    expect(reading.bloodPressureDisplay, '120/80 mmHg');
    expect(reading.summaryLines, contains('68.5 kg'));
  });
}
