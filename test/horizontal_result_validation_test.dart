import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';
import 'support/golden_job_fixtures.dart';

HorizontalCalculationInput _plainInput({
  List<double> widths = const [6000],
  String useDryVerge = 'NO',
  String abutmentSide = 'NONE',
  String useLHTile = 'NO',
}) {
  return HorizontalCalculationInput(
    widths: widths,
    tileCoverWidth: 165,
    minSpacing: 1,
    maxSpacing: 7,
    useDryVerge: useDryVerge,
    abutmentSide: abutmentSide,
    useLHTile: useLHTile,
    lhTileWidth: 165,
    crossBonded: 'YES',
    materialType: 'Plain Tile',
  );
}

void main() {
  group('horizontal_result_validation', () {
    test('plain tile 6000 wet verge reconciles to 6084 adjusted width', () {
      final input = _plainInput();
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.solution, 'Even Sets');
      expect(result.newWidth, 6100);
      expect(result.lhOverhang, 42);
      expect(result.rhOverhang, 42);
      expect(adjustedWidthFromResult(result), 6084);

      final issues = validateHorizontalReconciles(input: input, result: result);
      expect(issues, isEmpty, reason: issues.map((i) => i.message).join('; '));
    });

    test('dry verge reconciles within dry overhang bounds', () {
      final input = _plainInput(useDryVerge: 'YES');
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.solution, isNot('Invalid'));
      expect(result.newWidth, 6080);
      expect(result.lhOverhang, inInclusiveRange(20, 40));
      expect(result.rhOverhang, inInclusiveRange(20, 40));
      expect(
        adjustedWidthFromResult(result),
        result.width + result.lhOverhang! + result.rhOverhang!,
      );

      final issues = validateHorizontalReconciles(input: input, result: result);
      expect(issues, isEmpty, reason: issues.map((i) => i.message).join('; '));
    });

    test('golden fixtures reconcile without issues', () {
      for (final fixture in kGoldenJobFixtures) {
        final tile = tileModelFromGoldenFixture(fixture);
        final input = HorizontalCalculationInput(
          widths: [kGoldenRoofWidthMm],
          tileCoverWidth: fixture.tileCoverWidth,
          minSpacing: fixture.minSpacing,
          maxSpacing: fixture.maxSpacing,
          lhTileWidth: fixture.tileCoverWidth,
          useDryVerge: 'NO',
          abutmentSide: 'NONE',
          useLHTile: 'NO',
          crossBonded: tile.defaultCrossBonded ? 'YES' : 'NO',
          materialType: fixture.materialType,
        );
        final result = HorizontalCalculationService.calculateHorizontal(input);
        final issues =
            validateHorizontalReconciles(input: input, result: result);

        expect(
          issues,
          isEmpty,
          reason: '${fixture.id}: ${issues.map((i) => i.message).join('; ')}',
        );
      }
    });

    test('multi-width plain tile rows reconcile individually', () {
      final input = _plainInput(widths: [6000, 6200, 5800]);
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.widthDetails, hasLength(3));
      final issues = validateHorizontalReconciles(input: input, result: result);
      expect(issues, isEmpty, reason: issues.map((i) => i.message).join('; '));
    });

    test('left abutment hides overhangs but design width reduces', () {
      final input = _plainInput(abutmentSide: 'LEFT');
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.lhOverhang, isNull);
      expect(result.newWidth, 6000 + 50 - 5);

      final issues = validateHorizontalReconciles(input: input, result: result);
      expect(issues, isEmpty, reason: issues.map((i) => i.message).join('; '));
    });
  });

  group('horizontal scenario fixtures', () {
    test('split sets plain tile produces valid split marks', () {
      int? splitWidth;
      for (var width = 500; width <= 9000; width += 1) {
        final result = HorizontalCalculationService.calculateHorizontal(
          _plainInput(widths: [width.toDouble()]),
        );
        if (result.solution == 'Split Sets') {
          splitWidth = width;
          expect(result.splitMarks, isNotNull);
          final issues = validateHorizontalReconciles(
            input: _plainInput(widths: [width.toDouble()]),
            result: result,
          );
          expect(
            issues,
            isEmpty,
            reason: issues.map((i) => i.message).join('; '),
          );
          break;
        }
      }
      expect(splitWidth, isNotNull, reason: 'no split sets width found');
    });

    test('cut tile narrow slate produces cut width', () {
      final input = HorizontalCalculationInput(
        widths: [501],
        tileCoverWidth: 250,
        minSpacing: 1,
        maxSpacing: 5,
        useDryVerge: 'NO',
        abutmentSide: 'NONE',
        useLHTile: 'NO',
        lhTileWidth: 250,
        crossBonded: 'YES',
        materialType: 'Slate',
      );
      final result = HorizontalCalculationService.calculateHorizontal(input);

      expect(result.solution, 'Cut Tile');
      expect(result.cutTile, isNotNull);
      expect(result.newWidth, 601);
      expect(adjustedWidthFromResult(result), isNotNull);
    });
  });
}