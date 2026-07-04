import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

void main() {
  group('appColorSchemeIdFromStorage', () {
    test('maps known storage keys', () {
      expect(
        appColorSchemeIdFromStorage('slate_professional'),
        AppColorSchemeId.slateProfessional,
      );
      expect(
        appColorSchemeIdFromStorage('heritage_classic'),
        AppColorSchemeId.heritageClassic,
      );
      expect(
        appColorSchemeIdFromStorage('modern_dark_first'),
        AppColorSchemeId.modernDarkFirst,
      );
    });

    test('falls back to Slate Professional for unknown values', () {
      expect(
        appColorSchemeIdFromStorage('unknown'),
        AppColorSchemeId.slateProfessional,
      );
      expect(
        appColorSchemeIdFromStorage(null),
        AppColorSchemeId.slateProfessional,
      );
    });
  });

  group('AppColorSchemeId display metadata', () {
    test('storage keys round-trip', () {
      for (final scheme in AppColorSchemeId.values) {
        expect(
          appColorSchemeIdFromStorage(scheme.storageKey),
          scheme,
        );
      }
    });

    test('each scheme has a non-empty display name and description', () {
      for (final scheme in AppColorSchemeId.values) {
        expect(scheme.displayName, isNotEmpty);
        expect(scheme.description, isNotEmpty);
      }
    });
  });

  group('AppColorSchemes.tokensFor', () {
    test('modern dark-first uses slate tokens in light mode', () {
      final tokens = AppColorSchemes.tokensFor(
        AppColorSchemeId.modernDarkFirst,
        Brightness.light,
      );

      expect(tokens.primary, const Color(0xFF1E3A5F));
      expect(tokens.accent, const Color(0xFFBC4A2F));
    });

    test('modern dark-first uses vibrant palette in dark mode', () {
      final tokens = AppColorSchemes.tokensFor(
        AppColorSchemeId.modernDarkFirst,
        Brightness.dark,
      );

      expect(tokens.primary, const Color(0xFF4A90E2));
      expect(tokens.background, const Color(0xFF0F172A));
    });

    test('onPrimary and onAccent provide readable contrast', () {
      final tokens = AppColorSchemes.tokensFor(
        AppColorSchemeId.slateProfessional,
        Brightness.light,
      );

      expect(tokens.onPrimary, Colors.white);
      expect(tokens.onAccent, Colors.white);
    });
  });
}