import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/utils/user_theme_settings.dart';

void main() {
  group('colorSchemeIdFromUserData', () {
    test('returns null when data is null', () {
      expect(colorSchemeIdFromUserData(null), isNull);
    });

    test('returns null when settings is missing', () {
      expect(colorSchemeIdFromUserData({'email': 'a@b.com'}), isNull);
    });

    test('returns scheme id from settings map', () {
      expect(
        colorSchemeIdFromUserData({
          'settings': {'colorSchemeId': 'heritage_classic'},
        }),
        AppColorSchemeId.heritageClassic,
      );
    });

    test('returns null when colour scheme id is absent', () {
      expect(
        colorSchemeIdFromUserData({
          'settings': {'themeMode': 'dark'},
        }),
        isNull,
      );
    });
  });

  group('primaryColorFromUserData', () {
    test('returns null when data is null', () {
      expect(primaryColorFromUserData(null), isNull);
    });

    test('returns null when settings is missing', () {
      expect(primaryColorFromUserData({'email': 'a@b.com'}), isNull);
    });

    test('returns int primary colour from settings map', () {
      expect(
        primaryColorFromUserData({
          'settings': {'primaryColor': 0xFFE53935},
        }),
        0xFFE53935,
      );
    });

    test('returns null when primary colour is absent', () {
      expect(
        primaryColorFromUserData({
          'settings': {'themeMode': 'dark'},
        }),
        isNull,
      );
    });
  });
}