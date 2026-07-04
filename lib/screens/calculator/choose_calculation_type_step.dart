import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/calculator_launch_cards.dart';
import 'package:roofgrid_uk/widgets/selected_tile_row.dart';

class ChooseCalculationTypeStep extends ConsumerWidget {
  final UserModel user;
  final bool effectiveIsPro;
  final void Function(CalculationTypeSelection type) onTypeSelected;
  final VoidCallback onBack;
  final Widget Function(TileSlateType type) placeholderImageBuilder;

  const ChooseCalculationTypeStep({
    super.key,
    required this.user,
    required this.effectiveIsPro,
    required this.onTypeSelected,
    required this.onBack,
    required this.placeholderImageBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNarrow = isNarrowLayout(context);
    final padding = isNarrow ? 12.0 : 16.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(top: padding, bottom: 8),
            child: CalculatorStepProgress(
              currentStep: CalculatorFlowStep.selectType,
              compact: isNarrow,
            ),
          ),
          Text(
            'Choose set-out type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick vertical batten gauge, horizontal marking out, or both.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: CalculatorLaunchCards(onLaunch: onTypeSelected),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              color: colorScheme.surface,
            ),
            child: SelectedTileRow(
              user: user,
              effectiveIsPro: effectiveIsPro,
              compact: true,
              placeholderImageBuilder: placeholderImageBuilder,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: padding, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text('Back to tile'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}