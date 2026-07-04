import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

class _TestCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState();
}

void main() {
  group('hydrateCalculatorOptionsFromInputs', () {
    test('syncs vertical and horizontal options into provider state', () {
      final container = ProviderContainer(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(calculatorProvider.notifier);
      notifier.hydrateCalculatorOptionsFromInputs(
        vertical: const VerticalInputs(
          gutterOverhang: 25.0,
          useDryRidge: 'YES',
        ),
        horizontal: const HorizontalInputs(
          useDryVerge: 'YES',
          abutmentSide: 'LEFT',
          useLHTile: 'NO',
          crossBonded: 'YES',
        ),
      );

      final state = container.read(calculatorProvider);
      expect(state.gutterOverhang, 25.0);
      expect(state.useDryRidge, 'YES');
      expect(state.useDryVerge, 'YES');
      expect(state.abutmentSide, 'LEFT');
      expect(state.useLHTile, 'NO');
      expect(state.crossBonded, 'YES');
    });
  });

  group('resetOptionsForMode', () {
    test('verticalOnly clears horizontal option fields', () {
      final container = ProviderContainer(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(calculatorProvider.notifier);
      notifier.hydrateCalculatorOptionsFromInputs(
        horizontal: const HorizontalInputs(
          useDryVerge: 'YES',
          abutmentSide: 'LEFT',
          useLHTile: 'YES',
          crossBonded: 'YES',
        ),
      );

      notifier.resetOptionsForMode(CalculationTypeSelection.verticalOnly);

      final state = container.read(calculatorProvider);
      expect(state.useDryVerge, 'NO');
      expect(state.abutmentSide, 'NONE');
      expect(state.useLHTile, 'NO');
    });

    test('both preserves vertical and horizontal option fields', () {
      final container = ProviderContainer(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(calculatorProvider.notifier);
      notifier.hydrateCalculatorOptionsFromInputs(
        vertical: const VerticalInputs(
          gutterOverhang: 25.0,
          useDryRidge: 'YES',
        ),
        horizontal: const HorizontalInputs(
          useDryVerge: 'YES',
          abutmentSide: 'LEFT',
          useLHTile: 'NO',
          crossBonded: 'YES',
        ),
      );

      notifier.resetOptionsForMode(CalculationTypeSelection.both);

      final state = container.read(calculatorProvider);
      expect(state.gutterOverhang, 25.0);
      expect(state.useDryRidge, 'YES');
      expect(state.useDryVerge, 'YES');
      expect(state.abutmentSide, 'LEFT');
      expect(state.crossBonded, 'YES');
    });

    test('horizontalOnly clears vertical option fields', () {
      final container = ProviderContainer(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(calculatorProvider.notifier);
      notifier.hydrateCalculatorOptionsFromInputs(
        vertical: const VerticalInputs(
          gutterOverhang: 25.0,
          useDryRidge: 'YES',
        ),
      );

      notifier.resetOptionsForMode(CalculationTypeSelection.horizontalOnly);

      final state = container.read(calculatorProvider);
      expect(state.gutterOverhang, 50.0);
      expect(state.useDryRidge, 'NO');
    });
  });
}