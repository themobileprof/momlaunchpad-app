import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:momlaunchpad_mobile/main.dart';
import 'package:momlaunchpad_mobile/providers/auth_provider.dart';

import 'support/logged_out_test_auth_notifier.dart';

void main() {
  testWidgets('MomLaunchpadApp loads login shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(LoggedOutTestAuthNotifier.new),
        ],
        child: const MomLaunchpadApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(MomLaunchpadApp), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
