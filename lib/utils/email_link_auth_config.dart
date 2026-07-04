import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Hosting + native deep link configuration for email link auth.
///
/// Uses [linkDomain] (not deprecated dynamicLinkDomain).
class EmailLinkAuthConfig {
  static const firebaseProjectId = 'roofgriduk-f2f56';

  /// Custom Firebase Hosting domain for mobile auth links.
  static const linkDomain = 'roofgrid.uk';

  /// Continue URL shown in the email; must be an authorized Auth domain.
  static const continueUrl = 'https://roofgrid.uk/auth/email-link';

  static const androidPackageName = 'com.example.roofgrid_uk';
  static const iosBundleId = 'com.example.roofgrid_uk';

  static const pendingEmailStorageKey = 'email_link_pending_email';

  static const firebaseAppAuthLinksHost =
      '$firebaseProjectId.firebaseapp.com';

  static bool isEmailAuthLink(Uri uri) {
    final host = uri.host.toLowerCase();
    final isSupportedHost =
        host == linkDomain || host == firebaseAppAuthLinksHost;
    return isSupportedHost && uri.path.startsWith('/__/auth/links');
  }

  static ActionCodeSettings buildEmailLinkActionCodeSettings() {
    return ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      linkDomain: linkDomain,
      androidPackageName: androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: iosBundleId,
    );
  }

  /// Password reset uses the default Firebase Hosting domain only.
  /// Do not set [linkDomain] here — that is for mobile email-link sign-in.
  static ActionCodeSettings buildPasswordResetActionCodeSettings() {
    return ActionCodeSettings(
      url: 'https://$firebaseAppAuthLinksHost',
      handleCodeInApp: false,
    );
  }
}