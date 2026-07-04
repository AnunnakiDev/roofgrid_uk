import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';

HorizontalCalculationInput _plainInput({
  List<double> widths = const [6000],
  String useDryVerge = 'NO',
}) {
  return HorizontalCalculationInput(
    widths: widths,
    tileCoverWidth: 165,
    minSpacing: 1,
    maxSpacing: 7,
    useDryVerge: useDryVerge,
    abutmentSide: 'NONE',
    useLHTile: 'NO',
    lhTileWidth: 165,
    crossBonded: 'YES',
    materialType: 'Plain Tile',
  );
}

void main() {
  group('app horizontal manual scenarios', () {
    test('scenario 1 plain tile 6000 wet verge even sets', () {
      final input = _plainInput();
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.solution, 'Even Sets');
      expect(result.newWidth, 6100);
      expect(adjustedWidthFromResult(result), 6084);
      expect(result.lhOverhang, 42);
      expect(result.rhOverhang, 42);

      final hero = horizontalHeroRows(result);
      expect(
        hero.singleWhere((row) => row.label == 'Adjusted width').value,
        '6084',
      );
      expect(
        hero.singleWhere((row) => row.label == 'LH verge').value,
        '42',
      );

      expect(validateHorizontalReconciles(input: input, result: result), isEmpty);
    });

    test('scenario 2 plain tile dry verge even sets', () {
      final input = _plainInput(useDryVerge: 'YES');
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.solution, 'Even Sets');
      expect(result.newWidth, 6080);
      expect(validateHorizontalReconciles(input: input, result: result), isEmpty);
    });
  });
}