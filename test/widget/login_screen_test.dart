import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:momlaunchpad_mobile/providers/auth_provider.dart';
import 'package:momlaunchpad_mobile/screens/login_screen.dart';

import '../support/logged_out_test_auth_notifier.dart';

void main() {
  testWidgets('LoginScreen shows primary fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(LoggedOutTestAuthNotifier.new),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
