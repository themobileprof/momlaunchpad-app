import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/models/doctor_visit.dart';
import 'package:momlaunchpad_mobile/models/reminder.dart';
import 'package:momlaunchpad_mobile/utils/visit_check_in_logic.dart';

void main() {
  group('resolveVisitCheckIn', () {
    final now = DateTime(2026, 6, 1, 12);

    DoctorVisit visit({
      required String id,
      required DateTime visitDate,
      DateTime? nextAppointmentAt,
      DateTime? debriefCompletedAt,
    }) {
      return DoctorVisit(
        id: id,
        userId: 'user-1',
        visitDate: visitDate,
        visitType: 'prenatal_checkup',
        nextAppointmentAt: nextAppointmentAt,
        debriefCompletedAt: debriefCompletedAt,
        createdAt: visitDate,
        updatedAt: visitDate,
      );
    }

    test('shows upcoming appointment within 14 days', () {
      final appt = now.add(const Duration(days: 5));
      final context = resolveVisitCheckIn(
        visits: [visit(id: 'v1', visitDate: now.subtract(const Duration(days: 3)), nextAppointmentAt: appt)],
        reminders: const [],
        dismissedKeys: const {},
        monthlyDismissedAt: null,
        now: now,
      );

      expect(context?.kind, VisitCheckInKind.upcomingAppointment);
      expect(context?.appointmentAt, appt);
    });

    test('hides upcoming appointment when calendar reminder exists', () {
      final appt = now.add(const Duration(days: 5));
      final context = resolveVisitCheckIn(
        visits: [
          visit(
            id: 'v1',
            visitDate: now.subtract(const Duration(days: 3)),
            nextAppointmentAt: appt,
            debriefCompletedAt: now,
          ),
        ],
        reminders: [
          Reminder(
            id: 'r1',
            userId: 'user-1',
            title: 'Doctor appointment',
            scheduledTime: appt,
            priority: 'medium',
            isCompleted: false,
            createdAt: now,
          ),
        ],
        dismissedKeys: const {},
        monthlyDismissedAt: null,
        now: now,
      );

      expect(context?.kind, VisitCheckInKind.monthlyLog);
    });

    test('shows recent debrief for visit in last 14 days', () {
      final context = resolveVisitCheckIn(
        visits: [visit(id: 'v1', visitDate: now.subtract(const Duration(days: 2)))],
        reminders: const [],
        dismissedKeys: const {},
        monthlyDismissedAt: null,
        now: now,
      );

      expect(context?.kind, VisitCheckInKind.recentDebrief);
    });

    test('shows monthly log when nothing else applies', () {
      final context = resolveVisitCheckIn(
        visits: const [],
        reminders: const [],
        dismissedKeys: const {},
        monthlyDismissedAt: now.subtract(const Duration(days: 40)),
        now: now,
      );

      expect(context?.kind, VisitCheckInKind.monthlyLog);
    });
  });
}
