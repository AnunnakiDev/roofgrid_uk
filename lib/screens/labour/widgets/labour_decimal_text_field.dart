import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roofgrid_uk/utils/decimal_input_utils.dart';

class LabourDecimalTextField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final bool isDense;
  final int? maxDecimalPlaces;
  final String? prefixText;

  const LabourDecimalTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.isDense = false,
    this.maxDecimalPlaces,
    this.prefixText,
  });

  @override
  State<LabourDecimalTextField> createState() => _LabourDecimalTextFieldState();
}

class _LabourDecimalTextFieldState extends State<LabourDecimalTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(
      text: decimalInputDisplayText(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant LabourDecimalTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = decimalInputDisplayText(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pattern = widget.maxDecimalPlaces != null
        ? RegExp('^\\d*\\.?\\d{0,${widget.maxDecimalPlaces}}')
        : RegExp(r'^\d*\.?\d*');

    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: widget.isDense,
        prefixText: widget.prefixText,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(pattern)],
      onChanged: (text) => applyDecimalInputChange(text, widget.onChanged),
    );
  }
}