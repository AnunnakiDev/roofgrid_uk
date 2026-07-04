import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';
import 'package:roofgrid_uk/utils/keyboard_scroll_utils.dart';

/// High-contrast mm measurement field for calculator tabs.
class CalculatorMeasurementField extends StatefulWidget {
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
  State<CalculatorMeasurementField> createState() =>
      _CalculatorMeasurementFieldState();
}

class _CalculatorMeasurementFieldState extends State<CalculatorMeasurementField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      ensureFieldVisible(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? colorScheme.secondary;
    final parsed = double.tryParse(widget.controller.text);
    final hasError =
        widget.controller.text.isNotEmpty && (parsed == null || parsed <= 0);

    return Semantics(
      label: widget.semanticsLabel,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
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
          labelText: widget.labelText,
          hintText: 'e.g. 4000',
          suffixText: 'mm',
          errorText: hasError ? 'Enter a positive value' : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
            borderSide: BorderSide(
              color: accent.withValues(alpha: 0.35),
              width: widget.accentColor != null ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        onTap: () => ensureFieldVisible(context),
        onChanged: widget.onChanged,
      ),
    );
  }
}