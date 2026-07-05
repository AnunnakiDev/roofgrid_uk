import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/saved_result_labour_adapter.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

bool hasQuoteQuantities(LabourQuoteInput input) {
  if (input.roofAreaSqm > 0) return true;
  if (input.linearMetres.values.any((m) => m > 0)) return true;
  if (input.ancillaryCounts.values.any((c) => c > 0)) return true;
  return false;
}

SavedResult _combinedJob() {
  final now = DateTime(2026, 1, 1);
  return SavedResult(
    id: 'job-1',
    userId: 'u1',
    projectName: 'Imported roof',
    type: CalculationType.combined,
    timestamp: now,
    inputs: {
      'vertical_inputs': {
        'rafterHeights': [
          {'label': 'Rafter 1', 'value': 5000.0},
        ],
      },
      'horizontal_inputs': {
        'widths': [
          {'label': 'Width 1', 'value': 6000.0},
        ],
      },
    },
    outputs: const {},
    tile: const {'materialType': 'pantile'},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('labour quote quantity guard', () {
    test('empty input has no quantities', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
      );
      expect(hasQuoteQuantities(input), isFalse);
    });

    test('area alone is enough to quote', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 25,
      );
      expect(hasQuoteQuantities(input), isTrue);
    });

    test('linear metres alone is enough to quote', () {
      const input = LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
        linearMetres: {LabourLinearItem.ridge: 8},
      );
      expect(hasQuoteQuantities(input), isTrue);
    });
  });

  group('import to calculate flow', () {
    test('imported saved job produces a quotable result', () {
      final input = SavedResultLabourAdapter.inputFromSavedResult(_combinedJob());
      expect(input, isNotNull);
      expect(hasQuoteQuantities(input!), isTrue);

      final result = LabourPricingEngine.calculate(
        input: input,
        rates: LabourDefaults.starterRates,
        config: const LabourQuoteConfig(),
      );

      expect(result.quoteTotalGbp, greaterThan(0));
      expect(result.profitableDayRatePerManGbp, greaterThan(0));
    });
  });
}