import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/theme/app_color_schemes.dart';

/// Groups related calculator inputs inside a themed card.
class CalculatorInputSection extends StatelessWidget {
  final String title;
  final String? helperText;
  final Widget? trailing;
  final Widget child;
  final bool dense;

  const CalculatorInputSection({
    super.key,
    required this.title,
    this.helperText,
    this.trailing,
    required this.child,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardPadding = dense ? 10.0 : 16.0;
    final titleSize = dense ? 14.0 : 16.0;
    final helperSize = dense ? 12.0 : 13.0;
    final childGap = dense ? 8.0 : 14.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (helperText != null) ...[
                        SizedBox(height: dense ? 2 : 4),
                        Text(
                          helperText!,
                          maxLines: dense ? 1 : null,
                          overflow:
                              dense ? TextOverflow.ellipsis : TextOverflow.visible,
                          style: GoogleFonts.poppins(
                            fontSize: helperSize,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: childGap),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bordered option tile for toggles and compact controls.
class CalculatorOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const CalculatorOptionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(AppColorSchemes.inputRadius),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}