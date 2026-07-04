import 'package:flutter/material.dart';

/// Scrolls a focused field into view above the on-screen keyboard.
void ensureFieldVisible(
  BuildContext context, {
  double alignment = 0.2,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      alignment: alignment,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  });
}