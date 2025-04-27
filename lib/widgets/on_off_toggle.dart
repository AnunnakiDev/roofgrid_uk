import 'package:flutter/material.dart';

class OnOffToggle extends StatefulWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final double fontSize;

  const OnOffToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.fontSize,
  });

  @override
  State<OnOffToggle> createState() => _OnOffToggleState();
}

class _OnOffToggleState extends State<OnOffToggle> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: GestureDetector(
        onTap: () {
          widget.onChanged(!widget.value);
        },
        child: Container(
          width: 40, // Reduced width to match original size
          height: 20, // Reduced height to match original size
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(10), // Adjusted for smaller size
            color: widget.value ? Colors.green : Colors.red,
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment:
                    widget.value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16, // Scaled down thumb
                  height: 16,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 2), // Adjusted margin
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
