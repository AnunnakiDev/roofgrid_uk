import 'package:flutter/material.dart';

/// Theme-aligned palette for multi-input calculator rows.
Color calculatorInputColorForIndex(int index, {Color? primary, Color? accent}) {
  final basePrimary = primary ?? const Color(0xFF1E3A5F);
  final baseAccent = accent ?? const Color(0xFFBC4A2F);

  final colors = [
    basePrimary,
    baseAccent,
    Color.lerp(basePrimary, baseAccent, 0.35)!,
    Color.lerp(basePrimary, baseAccent, 0.65)!,
    basePrimary.withValues(alpha: 0.75),
    baseAccent.withValues(alpha: 0.85),
    Color.lerp(basePrimary, Colors.teal, 0.25)!,
    Color.lerp(baseAccent, Colors.amber, 0.2)!,
  ];

  return colors[index % colors.length];
}

/// Resolves input accent from the active theme.
Color calculatorInputColorFromTheme(BuildContext context, int index) {
  final scheme = Theme.of(context).colorScheme;
  return calculatorInputColorForIndex(
    index,
    primary: scheme.primary,
    accent: scheme.secondary,
  );
}