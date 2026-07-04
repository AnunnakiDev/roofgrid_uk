import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';

void main() {
  group('CalculationService.forTesting', () {
    late CalculationService service;

    setUp(() {
      service = CalculationService.forTesting();
    });

    test('calculateVertical runs without Firebase or Hive', () async {
      final result = await service.calculateVertical(
        input: VerticalCalculationInput(
          rafterHeights: [4000],
          gutterOverhang: 50,
          useDryRidge: 'NO',
        ),
        materialType: 'pantile',
        slateTileHeight: 300,
        maxGauge: 120,
        minGauge: 100,
      );

      expect(result.solution, isNot('Invalid'));
    });

    test('calculateHorizontal runs without Firebase or Hive', () async {
      final result = await service.calculateHorizontal(
        HorizontalCalculationInput(
          widths: [4000],
          tileCoverWidth: 250,
          minSpacing: 5,
          maxSpacing: 10,
          lhTileWidth: 250,
          useDryVerge: 'NO',
          abutmentSide: 'NONE',
          useLHTile: 'NO',
          crossBonded: 'NO',
          materialType: 'pantile',
        ),
      );

      expect(result.solution, isNot('Invalid'));
    });

    test('saveCalculation throws when persistence is disabled', () async {
      expect(
        () => service.saveCalculation(
          id: 'test',
          userId: 'user',
          tileId: 'tile',
          type: 'vertical',
          inputs: const {},
          result: const {},
          tile: const {},
          success: true,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}