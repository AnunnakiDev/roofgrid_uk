import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
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
    final padding = MediaQuery.of(context).size.width >= 600 ? 16.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(top: padding, bottom: 8),
            child: const CalculatorStepProgress(
              currentStep: CalculatorFlowStep.selectType,
            ),
          ),
          SelectedTileRow(
            user: user,
            effectiveIsPro: effectiveIsPro,
            placeholderImageBuilder: placeholderImageBuilder,
          ),
          const SizedBox(height: 8),
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: CalculatorLaunchCards(onLaunch: onTypeSelected),
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