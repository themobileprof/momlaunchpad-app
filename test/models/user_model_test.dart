import 'package:flutter_test/flutter_test.dart';

import 'package:momlaunchpad_mobile/models/user.dart';

void main() {
  group('User', () {
    test('fromJson and toJson round-trip', () {
      final original = User(
        id: '1',
        email: 'x@y.com',
        name: 'Test User',
        language: 'en',
        isAdmin: false,
        createdAt: DateTime.utc(2024, 3, 15, 12),
        updatedAt: DateTime.utc(2024, 3, 16, 8),
      );

      final json = original.toJson();
      final restored = User.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.language, original.language);
      expect(restored.isAdmin, original.isAdmin);
      expect(restored.createdAt.toUtc(), original.createdAt.toUtc());
      expect(restored.updatedAt?.toUtc(), original.updatedAt?.toUtc());
    });

    test('fromJson fills defaults for missing fields', () {
      final u = User.fromJson({});
      expect(u.id, '');
      expect(u.email, '');
      expect(u.language, 'en');
      expect(u.isAdmin, false);
    });
  });
}
