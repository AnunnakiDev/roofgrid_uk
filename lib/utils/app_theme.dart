import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

class AppTheme {
  AppTheme._();

  static const AppColorSchemeId defaultColorScheme =
      AppColorSchemes.defaultScheme;

  static ThemeData themeFor({
    required AppColorSchemeId schemeId,
    required Brightness brightness,
  }) {
    final tokens = AppColorSchemes.tokensFor(schemeId, brightness);
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.accent,
      onSecondary: tokens.onAccent,
      tertiary: tokens.accent,
      onTertiary: tokens.onAccent,
      surface: tokens.surface,
      onSurface: tokens.textPrimary,
      onSurfaceVariant: tokens.textSecondary,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.background,
      dividerTheme: DividerThemeData(
        color: tokens.textPrimary.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.accent,
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: isLight ? 0.12 : 0.35),
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColorSchemes.cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: _textTheme(tokens),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: tokens.onPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: tokens.onPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: tokens.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? tokens.accent : tokens.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.accent : tokens.textSecondary,
            size: selected ? 26 : 24,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: tokens.accent,
        unselectedItemColor: tokens.textSecondary,
        backgroundColor: tokens.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        selectedColor: tokens.primary.withValues(alpha: 0.14),
        labelStyle: GoogleFonts.poppins(
          color: tokens.textPrimary,
          fontSize: 13,
        ),
        side: BorderSide(color: tokens.primary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: tokens.onAccent,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColorSchemes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          side: BorderSide(color: tokens.primary.withValues(alpha: 0.6)),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColorSchemes.buttonRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
          borderSide: BorderSide(
            color: tokens.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
          borderSide: BorderSide(
            color: tokens.textSecondary.withValues(alpha: 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: tokens.textSecondary,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: tokens.textSecondary.withValues(alpha: 0.8),
          fontSize: 14,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        ),
      ),
    );
  }

  static TextTheme _textTheme(AppSchemeTokens tokens) {
    return TextTheme(
      titleLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: tokens.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: tokens.textPrimary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: tokens.textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: tokens.textSecondary,
      ),
    );
  }
}