import 'package:flutter/material.dart';

/// Preset colour schemes for RoofGrid UK.
enum AppColorSchemeId {
  slateProfessional,
  heritageClassic,
  modernDarkFirst,
}

extension AppColorSchemeIdStorage on AppColorSchemeId {
  String get storageKey => switch (this) {
        AppColorSchemeId.slateProfessional => 'slate_professional',
        AppColorSchemeId.heritageClassic => 'heritage_classic',
        AppColorSchemeId.modernDarkFirst => 'modern_dark_first',
      };

  String get displayName => switch (this) {
        AppColorSchemeId.slateProfessional => 'Slate Professional',
        AppColorSchemeId.heritageClassic => 'Heritage Classic',
        AppColorSchemeId.modernDarkFirst => 'Modern Dark-First',
      };

  String get description => switch (this) {
        AppColorSchemeId.slateProfessional =>
          'Modern, trustworthy, field-ready',
        AppColorSchemeId.heritageClassic =>
          'Traditional warmth with premium heritage tones',
        AppColorSchemeId.modernDarkFirst =>
          'Vibrant contrast optimised for dark mode on site',
      };
}

AppColorSchemeId appColorSchemeIdFromStorage(String? value) {
  switch (value) {
    case 'heritage_classic':
      return AppColorSchemeId.heritageClassic;
    case 'modern_dark_first':
      return AppColorSchemeId.modernDarkFirst;
    case 'slate_professional':
    default:
      return AppColorSchemeId.slateProfessional;
  }
}

/// Resolved palette tokens for a scheme at a given brightness.
class AppSchemeTokens {
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const AppSchemeTokens({
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  Color get onPrimary =>
      primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  Color get onAccent =>
      accent.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}

class AppColorSchemes {
  AppColorSchemes._();

  static const AppColorSchemeId defaultScheme =
      AppColorSchemeId.slateProfessional;

  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;

  static AppSchemeTokens tokensFor(
    AppColorSchemeId schemeId,
    Brightness brightness,
  ) {
    if (schemeId == AppColorSchemeId.modernDarkFirst &&
        brightness == Brightness.light) {
      return _slateProfessionalLight;
    }

    return switch (schemeId) {
      AppColorSchemeId.slateProfessional =>
        brightness == Brightness.light
            ? _slateProfessionalLight
            : _slateProfessionalDark,
      AppColorSchemeId.heritageClassic =>
        brightness == Brightness.light
            ? _heritageClassicLight
            : _heritageClassicDark,
      AppColorSchemeId.modernDarkFirst => _modernDarkFirstDark,
    };
  }

  static const _slateProfessionalLight = AppSchemeTokens(
    primary: Color(0xFF1E3A5F),
    accent: Color(0xFFBC4A2F),
    background: Color(0xFFF8F9FA),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1C2526),
    textSecondary: Color(0xFF5C6B6E),
  );

  static const _slateProfessionalDark = AppSchemeTokens(
    primary: Color(0xFF2A4F7A),
    accent: Color(0xFFD45A3F),
    background: Color(0xFF121820),
    surface: Color(0xFF1C2430),
    textPrimary: Color(0xFFF0F2F4),
    textSecondary: Color(0xFFA8B4B8),
  );

  static const _heritageClassicLight = AppSchemeTokens(
    primary: Color(0xFF0F2B5B),
    accent: Color(0xFF9C3A1B),
    background: Color(0xFFFDF9F2),
    surface: Color(0xFFFFFCF7),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF5A5248),
  );

  static const _heritageClassicDark = AppSchemeTokens(
    primary: Color(0xFF1A3D72),
    accent: Color(0xFFB84A2A),
    background: Color(0xFF141210),
    surface: Color(0xFF221E1A),
    textPrimary: Color(0xFFF5F0E8),
    textSecondary: Color(0xFFB8AFA0),
  );

  static const _modernDarkFirstDark = AppSchemeTokens(
    primary: Color(0xFF4A90E2),
    accent: Color(0xFFEF6C4A),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
  );
}