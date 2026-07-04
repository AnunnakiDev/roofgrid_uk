import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';

HorizontalCalculationInput _plainTileInput({
  List<double> widths = const [6000],
  String abutmentSide = 'NONE',
  String useLHTile = 'NO',
}) {
  return HorizontalCalculationInput(
    widths: widths,
    tileCoverWidth: 165,
    minSpacing: 1,
    maxSpacing: 7,
    useDryVerge: 'NO',
    abutmentSide: abutmentSide,
    useLHTile: useLHTile,
    lhTileWidth: 165,
    crossBonded: 'YES',
  );
}

void main() {
  group('HorizontalCalculationService', () {
    test('returns Invalid when widths are below minimum', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(widths: [400]),
      );

      expect(result.solution, 'Invalid');
      expect(result.warning, isNotNull);
      expect(result.firstMark, 0);
    });

    test('returns Invalid when widths list is empty', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(widths: []),
      );

      expect(result.solution, 'Invalid');
      expect(result.warning, isNotNull);
    });

    test('computes a valid even-sets solution for a typical roof width', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(),
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.warning, isNull);
      expect(result.newWidth, 6100);
      expect(adjustedWidthFromResult(result), 6084);
      expect(result.firstMark, greaterThan(0));
      expect(
        validateHorizontalReconciles(input: _plainTileInput(), result: result),
        isEmpty,
      );
      expect(result.actualSpacing, inInclusiveRange(1, 7));
      expect(result.lhOverhang, isNotNull);
      expect(result.rhOverhang, isNotNull);
      expect(result.marks, isNot('N/A'));
    });

    test('includes second mark when cross bonded', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(),
      );

      expect(result.secondMark, isNotNull);
      expect(result.secondMark, greaterThan(result.firstMark));
    });

    test('omits overhangs when left abutment is set', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(abutmentSide: 'LEFT'),
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.lhOverhang, isNull);
      expect(result.rhOverhang, isNull);
    });

    test('populates per-width details for multiple widths', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(widths: [6000, 6200, 5800]),
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.widthDetails, isNotNull);
      expect(result.widthDetails, hasLength(3));
      expect(
        result.widthDetails!.map((detail) => detail.inputWidth),
        [6000, 6200, 5800],
      );
      expect(
        result.widthDetails!.map((detail) => detail.firstMark).toSet(),
        hasLength(greaterThan(0)),
      );
    });

    test('round-trips widthDetails through json', () {
      final result = HorizontalCalculationService.calculateHorizontal(
        _plainTileInput(widths: [6000, 6100]),
      );

      final restored = HorizontalCalculationResult.fromJson(result.toJson());
      expect(restored.widthDetails, hasLength(2));
      expect(restored.widthDetails!.first.inputWidth, 6000);
    });
  });
}