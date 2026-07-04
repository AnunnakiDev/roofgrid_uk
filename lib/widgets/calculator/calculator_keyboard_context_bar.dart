import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

/// Compact sticky context shown while the on-screen keyboard is open.
class CalculatorKeyboardContextBar extends ConsumerWidget {
  final CalculationTypeSelection calculationType;

  const CalculatorKeyboardContextBar({
    super.key,
    required this.calculationType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));
    final tileName = selectedTile?.name ?? 'No tile selected';

    return Material(
      elevation: 1,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.straighten,
              size: 16,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tileName,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              calculationTypeLabel(calculationType),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}