import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

/// High-contrast mm measurement field for calculator tabs.
class CalculatorMeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String semanticsLabel;
  final Color? accentColor;
  final ValueChanged<String>? onChanged;

  const CalculatorMeasurementField({
    super.key,
    required this.controller,
    required this.semanticsLabel,
    this.labelText,
    this.accentColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = accentColor ?? colorScheme.secondary;
    final parsed = double.tryParse(controller.text);
    final hasError = controller.text.isNotEmpty && (parsed == null || parsed <= 0);

    return Semantics(
      label: semanticsLabel,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: 'e.g. 4000',
          suffixText: 'mm',
          errorText: hasError ? 'Enter a positive value' : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
            borderSide: BorderSide(
              color: accent.withValues(alpha: 0.35),
              width: accentColor != null ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}