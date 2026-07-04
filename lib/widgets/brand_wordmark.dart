import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Text-based RoofGrid branding used in place of image logos.
class BrandWordmark extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final double letterSpacing;
  final TextAlign textAlign;

  const BrandWordmark({
    super.key,
    this.fontSize = 32,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.letterSpacing = 4,
    this.textAlign = TextAlign.center,
  });

  const BrandWordmark.compact({
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.letterSpacing = 3,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: 'RoofGrid wordmark',
      child: Text(
        'ROOFGRID',
        textAlign: textAlign,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
          color: effectiveColor,
        ),
      ),
    );
  }
}