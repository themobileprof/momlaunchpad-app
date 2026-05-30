import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/models/doctor_visit.dart';

void main() {
  group('DoctorVisit', () {
    test('fromJson parses visit with nested medications and labs', () {
      final visit = DoctorVisit.fromJson({
        'id': 'visit-1',
        'user_id': 'user-1',
        'visit_date': '2026-05-01T10:30:00Z',
        'visit_type': 'prenatal_checkup',
        'provider_name': 'Dr. Lee',
        'clinical_notes': 'Routine checkup',
        'blood_pressure_systolic': 118,
        'blood_pressure_diastolic': 76,
        'medications': [
          {
            'name': 'Prenatal vitamins',
            'dosage': '1 tablet',
            'frequency': 'Daily',
          },
        ],
        'lab_results': [
          {
            'test_name': 'Hemoglobin',
            'result': '12.1',
            'unit': 'g/dL',
          },
        ],
        'next_appointment_at': '2026-06-01T09:00:00Z',
        'recorded_by': 'user',
        'created_at': '2026-05-01T10:35:00Z',
        'updated_at': '2026-05-01T10:35:00Z',
      });

      expect(visit.visitTypeLabel, 'Prenatal checkup');
      expect(visit.bloodPressureDisplay, '118/76');
      expect(visit.medications, hasLength(1));
      expect(visit.labResults.first.testName, 'Hemoglobin');
      expect(visit.hasUpcomingAppointment, isTrue);
    });

    test('DoctorVisitPayload toJson uses snake_case keys', () {
      final payload = DoctorVisitPayload(
        visitDate: DateTime.utc(2026, 5, 1, 10, 30),
        visitType: 'ultrasound',
        providerName: 'Dr. Lee',
        medications: const [
          VisitMedication(
            name: 'Iron',
            dosage: '65 mg',
            frequency: 'Daily',
          ),
        ],
      );

      final json = payload.toJson();
      expect(json['visit_type'], 'ultrasound');
      expect(json['provider_name'], 'Dr. Lee');
      expect(json['medications'], isA<List<dynamic>>());
    });
  });
}
