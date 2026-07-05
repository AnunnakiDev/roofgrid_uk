import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LabourMoneyField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;

  const LabourMoneyField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
  });

  @override
  State<LabourMoneyField> createState() => _LabourMoneyFieldState();
}

class _LabourMoneyFieldState extends State<LabourMoneyField> {
  late final TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant LabourMoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFocused && oldWidget.value != widget.value) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _textFor(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Focus(
        onFocusChange: (focused) => _isFocused = focused,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            prefixText: '£ ',
            suffixText: widget.suffix,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (text) =>
              widget.onChanged(double.tryParse(text) ?? widget.value),
        ),
      ),
    );
  }
}

class LabourDecimalField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? suffix;

  const LabourDecimalField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
  });

  @override
  State<LabourDecimalField> createState() => _LabourDecimalFieldState();
}

class _LabourDecimalFieldState extends State<LabourDecimalField> {
  late final TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant LabourDecimalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFocused && oldWidget.value != widget.value) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _textFor(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Focus(
        onFocusChange: (focused) => _isFocused = focused,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixText: widget.suffix,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          onChanged: (text) =>
              widget.onChanged(double.tryParse(text) ?? widget.value),
        ),
      ),
    );
  }
}

class LabourIntField extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const LabourIntField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<LabourIntField> createState() => _LabourIntFieldState();
}

class _LabourIntFieldState extends State<LabourIntField> {
  late final TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.value));
  }

  @override
  void didUpdateWidget(covariant LabourIntField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFocused && oldWidget.value != widget.value) {
      _controller.text = _textFor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _textFor(int value) => value.toString();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Focus(
        onFocusChange: (focused) => _isFocused = focused,
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (text) =>
              widget.onChanged(int.tryParse(text) ?? widget.value),
        ),
      ),
    );
  }
}