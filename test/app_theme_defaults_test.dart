import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/providers/theme_provider.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/utils/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('default colour scheme is Slate Professional', () {
      expect(AppTheme.defaultColorScheme, AppColorSchemeId.slateProfessional);
    });

    test('Slate Professional light tokens use slate primary and terracotta accent',
        () {
      final tokens = AppColorSchemes.tokensFor(
        AppColorSchemeId.slateProfessional,
        Brightness.light,
      );

      expect(tokens.primary, const Color(0xFF1E3A5F));
      expect(tokens.accent, const Color(0xFFBC4A2F));
      expect(tokens.background, const Color(0xFFF8F9FA));
    });

    test('Slate Professional dark tokens use elevated palette', () {
      final tokens = AppColorSchemes.tokensFor(
        AppColorSchemeId.slateProfessional,
        Brightness.dark,
      );

      expect(tokens.primary, const Color(0xFF2A4F7A));
      expect(tokens.accent, const Color(0xFFD45A3F));
    });
  });

  group('ThemeState', () {
    test('tokensFor reflects stored colour scheme', () {
      final state = ThemeState(
        themeMode: ThemeMode.system,
        colorSchemeId: AppColorSchemeId.heritageClassic,
        isInitialized: true,
      );

      final tokens = state.tokensFor(Brightness.light);
      expect(tokens.primary, const Color(0xFF0F2B5B));
      expect(tokens.accent, const Color(0xFF9C3A1B));
    });

    test('defaults to Slate Professional scheme', () {
      final state = ThemeState(themeMode: ThemeMode.system);
      expect(state.colorSchemeId, AppColorSchemeId.slateProfessional);
    });
  });
}