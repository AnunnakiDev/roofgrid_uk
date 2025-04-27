import 'package:flutter/material.dart';

class ToggleOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  final double fontSize;

  const ToggleOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: '$label $value',
          child: Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
        ),
        Text(value, style: TextStyle(fontSize: fontSize)),
      ],
    );
  }
}
