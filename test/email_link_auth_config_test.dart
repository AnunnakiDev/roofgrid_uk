import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/email_link_auth_config.dart';

void main() {
  group('EmailLinkAuthConfig', () {
    test('buildEmailLinkActionCodeSettings uses linkDomain not dynamic links', () {
      final settings = EmailLinkAuthConfig.buildEmailLinkActionCodeSettings();

      expect(settings.url, EmailLinkAuthConfig.continueUrl);
      expect(settings.linkDomain, EmailLinkAuthConfig.linkDomain);
      expect(settings.handleCodeInApp, isTrue);
      expect(settings.androidPackageName, EmailLinkAuthConfig.androidPackageName);
      expect(settings.iOSBundleId, EmailLinkAuthConfig.iosBundleId);
    });

    test('buildPasswordResetActionCodeSettings does not use linkDomain', () {
      final settings =
          EmailLinkAuthConfig.buildPasswordResetActionCodeSettings();

      expect(settings.linkDomain, isNull);
      expect(settings.handleCodeInApp, isFalse);
      expect(
        settings.url,
        'https://${EmailLinkAuthConfig.firebaseAppAuthLinksHost}',
      );
    });

    test('isEmailAuthLink recognizes hosting auth link paths', () {
      expect(
        EmailLinkAuthConfig.isEmailAuthLink(
          Uri.parse(
            'https://roofgrid.uk/__/auth/links?apiKey=test&oobCode=abc',
          ),
        ),
        isTrue,
      );
      expect(
        EmailLinkAuthConfig.isEmailAuthLink(
          Uri.parse('https://roofgrid.uk/auth/email-link'),
        ),
        isFalse,
      );
      expect(
        EmailLinkAuthConfig.isEmailAuthLink(
          Uri.parse('https://example.com/__/auth/links'),
        ),
        isFalse,
      );
    });

    test('action code settings serialize linkDomain', () {
      final settings = EmailLinkAuthConfig.buildEmailLinkActionCodeSettings();
      final map = settings.asMap();

      expect(map['linkDomain'], 'roofgrid.uk');
      expect(map.containsKey('dynamicLinkDomain'), isFalse);
    });
  });
}