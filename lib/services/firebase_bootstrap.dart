import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Configures Firebase Auth/App Check for reliable emulator and debug testing.
Future<void> configureFirebaseForPlatform() async {
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
    debugPrint(
      'Firebase Auth: appVerificationDisabledForTesting enabled (debug only)',
    );
  }

  // Web requires a ReCaptchaV3/Enterprise WebProvider. Activating without one
  // throws and prevents runApp(), which surfaces as a blank hosting page.
  if (kIsWeb) {
    if (kDebugMode) {
      debugPrint(
        'Firebase App Check skipped on web (configure ReCaptcha WebProvider to enable)',
      );
    }
    return;
  }

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
  debugPrint('Firebase App Check activated');
}