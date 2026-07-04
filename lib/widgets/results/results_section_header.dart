import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact section title with terracotta accent stripe for results panels.
class ResultsSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final double fontSize;

  const ResultsSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: fontSize + 6,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Subtle divider between hero metrics, breakdown, and actions.
class ResultsSectionDivider extends StatelessWidget {
  const ResultsSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
      ),
    );
  }
}