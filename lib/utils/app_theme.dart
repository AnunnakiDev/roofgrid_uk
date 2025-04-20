import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color defaultPrimaryColor = Color(0xFF1976D2);
  static const Color defaultAccentColor = Color(0xFF2196F3);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  static ThemeData lightTheme({Color? primaryColor}) {
    final effectivePrimaryColor = primaryColor ?? defaultPrimaryColor;
    return ThemeData(
      primaryColor: effectivePrimaryColor,
      colorScheme: ColorScheme.light(
        primary: effectivePrimaryColor,
        secondary: defaultAccentColor,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.black,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.black,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      appBarTheme: AppBarTheme(
        color: effectivePrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: effectivePrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectivePrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: effectivePrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  static ThemeData darkTheme({Color? primaryColor}) {
    final effectivePrimaryColor = primaryColor ?? Colors.blueAccent;
    return ThemeData(
      primaryColor: effectivePrimaryColor,
      colorScheme: ColorScheme.dark(
        primary: effectivePrimaryColor,
        secondary: const Color(0xFF42A5F5),
        surface: const Color(0xFF424242),
      ),
      scaffoldBackgroundColor: const Color(0xFF212121),
      textTheme: TextTheme(
        titleLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.white70,
        ),
      ),
      appBarTheme: AppBarTheme(
        color: effectivePrimaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: effectivePrimaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectivePrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: effectivePrimaryColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF424242),
      ),
    );
  }
}
