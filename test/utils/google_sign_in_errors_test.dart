import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momlaunchpad_mobile/utils/google_sign_in_errors.dart';

void main() {
  test('maps ApiException 10 to setup guidance', () {
    final error = PlatformException(
      code: 'sign_in_failed',
      message: 'com.google.android.gms.common.api.ApiException: 10:',
    );
    final msg = googleSignInErrorMessage(error);
    expect(msg, contains('SHA-1'));
    expect(msg, contains('com.momlaunchpad.app'));
  });

  test('maps localhost connection errors for physical devices', () {
    final msg = googleSignInErrorMessage(
      StateError('SocketException: Connection refused'),
      apiBaseUrl: 'http://localhost:8080',
    );
    expect(msg, contains('localhost'));
    expect(msg, contains('10.0.2.2'));
  });
}
