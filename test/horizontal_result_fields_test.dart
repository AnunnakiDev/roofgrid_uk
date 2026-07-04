import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/width_calculation_detail.dart';
import 'package:roofgrid_uk/utils/horizontal_result_fields.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';

void main() {
  group('horizontal_result_fields', () {
    test('degenerate split with zero split sets displays as even sets', () {
      const result = HorizontalCalculationResult(
        width: 6500,
        solution: 'Split Sets',
        newWidth: 6600,
        firstMark: 592,
        marks: '10 sets of 2 @ 600',
        splitMarks: '0 sets of 2 @ 600',
        actualSpacing: 5,
        lhOverhang: 47,
        rhOverhang: 47,
      );

      expect(hasActualHorizontalSplit(result), isFalse);
      expect(effectiveHorizontalSolution(result), 'Even Sets');
      expect(horizontalMarksSummaryValue(result), '10 sets of 2 @ 600');
    });

    test('true split with different mark increments is preserved', () {
      const result = HorizontalCalculationResult(
        width: 6000,
        solution: 'Split Sets',
        newWidth: 6100,
        firstMark: 500,
        marks: '4 sets of 3 @ 520',
        splitMarks: '2 sets of 3 @ 500',
        actualSpacing: 5,
      );

      expect(hasActualHorizontalSplit(result), isTrue);
      expect(effectiveHorizontalSolution(result), 'Split Sets');
      expect(
        horizontalMarksSummaryValue(result),
        '2 sets of 3 @ 500 + 4 sets of 3 @ 520',
      );
    });

    test('multi-width chips appear when first marks differ', () {
      final result = HorizontalCalculationResult(
        width: 6500,
        solution: 'Even Sets',
        newWidth: 6600,
        firstMark: 592,
        marks: '10 sets of 2 @ 600',
        widthDetails: const [
          WidthCalculationDetail(
            inputWidth: 6500,
            totalWidth: 6600,
            firstMark: 592,
            lhOverhang: 47,
            rhOverhang: 47,
          ),
          WidthCalculationDetail(
            inputWidth: 6550,
            totalWidth: 6650,
            firstMark: 570,
            lhOverhang: 25,
            rhOverhang: 25,
          ),
        ],
      );

      final chips = horizontalPositionMarkChips(
        result: result,
        widths: const [
          WidthInputEntry(label: 'Width 1', value: 6500),
          WidthInputEntry(label: 'Width 2', value: 6550),
        ],
      );

      expect(chips, ['Width 1: 592 mm', 'Width 2: 570 mm']);
    });
  });
}