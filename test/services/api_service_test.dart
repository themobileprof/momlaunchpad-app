import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:momlaunchpad_mobile/services/api_service.dart';

import '../support/fake_storage_service.dart';

void main() {
  const base = 'http://localhost:8080';

  group('ApiService', () {
    test('login persists token and parses user', () async {
      final storage = FakeStorageService();
      late Uri seenUri;
      final client = MockClient((request) async {
        seenUri = request.url;
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode({
            'token': 'jwt-test',
            'user': {
              'id': 'u1',
              'email': 'a@example.com',
              'name': 'Ada',
              'language': 'en',
              'is_admin': false,
              'created_at': '2024-01-01T00:00:00.000Z',
            },
          }),
          200,
        );
      });

      final api = ApiService(
        baseUrl: base,
        storage: storage,
        httpClient: client,
      );

      final auth = await api.login(email: 'a@example.com', password: 'secret');
      expect(auth.token, 'jwt-test');
      expect(auth.user.email, 'a@example.com');
      expect(await storage.getToken(), 'jwt-test');
      expect(seenUri.toString(), '$base/api/auth/login');
    });

    test('getReminders parses list', () async {
      final storage = FakeStorageService();
      await storage.saveToken('t');
      final when = DateTime.utc(2025, 6, 15, 10);
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/reminders');
        return http.Response(
          jsonEncode([
            {
              'id': 'r1',
              'user_id': 'u1',
              'title': 'Visit',
              'reminder_time': when.toIso8601String(),
              'priority': 'high',
              'is_completed': false,
              'created_at': '2024-01-01T00:00:00.000Z',
            },
          ]),
          200,
        );
      });

      final api = ApiService(
        baseUrl: base,
        storage: storage,
        httpClient: client,
      );

      final list = await api.getReminders();
      expect(list, hasLength(1));
      expect(list.single.title, 'Visit');
      expect(list.single.priority, 'high');
    });
  });
}
