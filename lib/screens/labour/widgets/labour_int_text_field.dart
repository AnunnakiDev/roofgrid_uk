import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roofgrid_uk/utils/decimal_input_utils.dart';

class LabourIntTextField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;

  const LabourIntTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<LabourIntTextField> createState() => _LabourIntTextFieldState();
}

class _LabourIntTextFieldState extends State<LabourIntTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(
      text: intInputDisplayText(widget.value),
    );
  }

  @override
  void didUpdateWidget(covariant LabourIntTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = intInputDisplayText(widget.value);
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
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (text) => applyIntInputChange(text, widget.onChanged),
    );
  }
}