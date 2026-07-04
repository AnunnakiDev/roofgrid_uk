import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

enum CalculationTypeSelection {
  verticalOnly,
  horizontalOnly,
  both,
}

/// Parses `?mode=` query values from calculator routes.
CalculationTypeSelection? parseCalculatorModeQuery(String? mode) {
  switch (mode?.toLowerCase()) {
    case 'vertical':
      return CalculationTypeSelection.verticalOnly;
    case 'horizontal':
      return CalculationTypeSelection.horizontalOnly;
    case 'combined':
      return CalculationTypeSelection.both;
    default:
      return null;
  }
}

String calculatorModeQueryValue(CalculationTypeSelection mode) {
  switch (mode) {
    case CalculationTypeSelection.verticalOnly:
      return 'vertical';
    case CalculationTypeSelection.horizontalOnly:
      return 'horizontal';
    case CalculationTypeSelection.both:
      return 'combined';
  }
}

CalculationTypeSelection calculationTypeFromSavedResult(CalculationType type) {
  switch (type) {
    case CalculationType.vertical:
      return CalculationTypeSelection.verticalOnly;
    case CalculationType.horizontal:
      return CalculationTypeSelection.horizontalOnly;
    case CalculationType.combined:
      return CalculationTypeSelection.both;
  }
}

bool includesVertical(CalculationTypeSelection mode) {
  return mode == CalculationTypeSelection.verticalOnly ||
      mode == CalculationTypeSelection.both;
}

bool includesHorizontal(CalculationTypeSelection mode) {
  return mode == CalculationTypeSelection.horizontalOnly ||
      mode == CalculationTypeSelection.both;
}

String measurementStepTitle(
  CalculationTypeSelection mode, {
  required bool isVerticalStep,
}) {
  if (mode == CalculationTypeSelection.verticalOnly) {
    return 'Rafter measurements';
  }
  if (mode == CalculationTypeSelection.horizontalOnly) {
    return 'Width measurements';
  }
  return isVerticalStep ? 'Vertical measurements' : 'Horizontal measurements';
}

String calculationTypeLabel(CalculationTypeSelection mode) {
  switch (mode) {
    case CalculationTypeSelection.verticalOnly:
      return 'Vertical set-out';
    case CalculationTypeSelection.horizontalOnly:
      return 'Horizontal set-out';
    case CalculationTypeSelection.both:
      return 'Combined set-out';
  }
}

String savedCalculationTypeLabel(CalculationType type) {
  return calculationTypeLabel(calculationTypeFromSavedResult(type));
}

void navigateToCalculatorMode(BuildContext context, CalculationTypeSelection mode) {
  context.go('/calculator?mode=${calculatorModeQueryValue(mode)}');
}

Future<void> showCalculatorModePicker(BuildContext context) async {
  final selected = await showModalBottomSheet<CalculationTypeSelection>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Choose calculation type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Vertical set-out'),
            subtitle: const Text('Batten gauge from rafter heights'),
            onTap: () =>
                Navigator.pop(context, CalculationTypeSelection.verticalOnly),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_mosaic),
            title: const Text('Horizontal set-out'),
            subtitle: const Text('Tile marking out from widths'),
            onTap: () =>
                Navigator.pop(context, CalculationTypeSelection.horizontalOnly),
          ),
          ListTile(
            leading: const Icon(Icons.roofing),
            title: const Text('Combined set-out'),
            subtitle: const Text('Full roof layout — vertical and horizontal'),
            onTap: () => Navigator.pop(context, CalculationTypeSelection.both),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (!context.mounted || selected == null) return;
  navigateToCalculatorMode(context, selected);
}