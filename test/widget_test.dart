// Basic widget test for MomLaunchpad

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:momlaunchpad_mobile/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MomLaunchpadApp(),
      ),
    );

    // Verify the app loads without errors
    expect(find.byType(MomLaunchpadApp), findsOneWidget);
  });
}
