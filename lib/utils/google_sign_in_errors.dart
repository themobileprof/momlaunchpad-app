import 'package:flutter/services.dart';

/// User-facing message for Google Sign-In failures.
String googleSignInErrorMessage(Object error, {String? apiBaseUrl}) {
  if (error is PlatformException) {
    final code = error.code;
    final message = error.message ?? '';
    if (code == 'sign_in_canceled') {
      return 'Sign-in cancelled';
    }
    if (code == 'sign_in_failed' ||
        code == 'network_error' ||
        message.contains('ApiException: 10')) {
      return 'Google sign-in setup issue. Confirm the app SHA-1 and package '
          'name (com.momlaunchpad.app) are registered in Google Cloud Console, '
          'and that GOOGLE_WEB_CLIENT_ID matches your Web OAuth client.';
    }
    if (message.isNotEmpty) {
      return 'Google sign-in failed: $message';
    }
    return 'Google sign-in failed ($code). Please try again.';
  }

  final text = error.toString();
  if (text.contains('Failed to get ID token')) {
    return 'Google did not return a sign-in token. Check GOOGLE_WEB_CLIENT_ID '
        'in .env matches your Web OAuth client ID.';
  }
  if (text.contains('Failed host lookup') ||
      text.contains('Connection refused') ||
      text.contains('SocketException')) {
    final host = Uri.tryParse(apiBaseUrl ?? '')?.host ?? '';
    if (host == 'localhost' || host == '127.0.0.1') {
      return 'Cannot reach the API at localhost from this device. '
          'Use http://10.0.2.2:8080 on the Android emulator, or your '
          'computer\'s LAN IP in .env for a physical device.';
    }
    return 'Unable to connect to the server. Check your network and API URL.';
  }

  return 'Google sign-in failed. Please try again.';
}
