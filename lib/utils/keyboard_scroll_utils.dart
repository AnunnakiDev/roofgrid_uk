import 'package:flutter/material.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';

/// Scrolls a focused field into view above the on-screen keyboard.
void ensureFieldVisible(
  BuildContext context, {
  double? alignment,
  double keyboardPadding = 12,
}) {
  void scroll({Duration delay = Duration.zero}) {
    Future.delayed(delay, () {
      if (!context.mounted) return;

      final keyboardInset = View.of(context).viewInsets.bottom;
      final narrow = isNarrowLayout(context);
      final effectiveAlignment = alignment ??
          (keyboardInset > 0
              ? (narrow ? 0.02 : 0.08)
              : (narrow ? 0.15 : 0.2));

      Scrollable.ensureVisible(
        context,
        alignment: effectiveAlignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    scroll();
    // Safari keyboard animation may finish after the first frame.
    scroll(delay: const Duration(milliseconds: 280));
  });
}