import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/test_env.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  loadTestEnv();
  await testMain();
}
