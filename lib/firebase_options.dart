// Generated from android/app/google-services.json (project: momlaunchpad-88223).
// Re-run `flutterfire configure` after installing Firebase CLI to refresh or add iOS.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const bool enabled = true;

  static FirebaseOptions get currentPlatform {
    if (!enabled) {
      throw StateError('Firebase is not enabled.');
    }
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Firebase is not supported on this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4yngouuPJM9KTNM8HFkfb9W0---RrLIM',
    appId: '1:690783621588:android:f80829f89d07d411170641',
    messagingSenderId: '690783621588',
    projectId: 'momlaunchpad-88223',
    storageBucket: 'momlaunchpad-88223.firebasestorage.app',
  );

  /// Add iOS app in Firebase Console + run `flutterfire configure` for real values.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4yngouuPJM9KTNM8HFkfb9W0---RrLIM',
    appId: '1:690783621588:android:f80829f89d07d411170641',
    messagingSenderId: '690783621588',
    projectId: 'momlaunchpad-88223',
    storageBucket: 'momlaunchpad-88223.firebasestorage.app',
    iosBundleId: 'com.momlaunchpad.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4yngouuPJM9KTNM8HFkfb9W0---RrLIM',
    appId: '1:690783621588:android:f80829f89d07d411170641',
    messagingSenderId: '690783621588',
    projectId: 'momlaunchpad-88223',
    authDomain: 'momlaunchpad-88223.firebaseapp.com',
    storageBucket: 'momlaunchpad-88223.firebasestorage.app',
  );
}
