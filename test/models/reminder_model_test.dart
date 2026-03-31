import 'package:flutter_test/flutter_test.dart';

import 'package:momlaunchpad_mobile/models/reminder.dart';

void main() {
  group('Reminder', () {
    test('fromJson maps backend fields', () {
      final when = DateTime.utc(2025, 7, 20, 14, 30);
      final created = DateTime.utc(2025, 1, 1);
      final r = Reminder.fromJson({
        'id': 'r1',
        'user_id': 'u1',
        'title': 'Ultrasound',
        'description': 'Bring records',
        'reminder_time': when.toIso8601String(),
        'priority': 'medium',
        'is_completed': true,
        'created_at': created.toIso8601String(),
      });

      expect(r.id, 'r1');
      expect(r.userId, 'u1');
      expect(r.title, 'Ultrasound');
      expect(r.description, 'Bring records');
      expect(r.scheduledTime.toUtc(), when);
      expect(r.priority, 'medium');
      expect(r.isCompleted, true);
      expect(r.createdAt.toUtc(), created);
    });
  });
}
