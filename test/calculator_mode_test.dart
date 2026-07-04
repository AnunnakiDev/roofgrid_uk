import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

void main() {
  group('parseCalculatorModeQuery', () {
    test('parses vertical, horizontal, and combined', () {
      expect(
        parseCalculatorModeQuery('vertical'),
        CalculationTypeSelection.verticalOnly,
      );
      expect(
        parseCalculatorModeQuery('horizontal'),
        CalculationTypeSelection.horizontalOnly,
      );
      expect(
        parseCalculatorModeQuery('combined'),
        CalculationTypeSelection.both,
      );
    });

    test('returns null for unknown mode', () {
      expect(parseCalculatorModeQuery('diagonal'), isNull);
      expect(parseCalculatorModeQuery(null), isNull);
    });
  });

  group('calculationTypeFromSavedResult', () {
    test('maps saved calculation types', () {
      expect(
        calculationTypeFromSavedResult(CalculationType.vertical),
        CalculationTypeSelection.verticalOnly,
      );
      expect(
        calculationTypeFromSavedResult(CalculationType.combined),
        CalculationTypeSelection.both,
      );
    });
  });
}