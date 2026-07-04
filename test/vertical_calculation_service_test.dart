import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/vertical_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';

VerticalCalculationInput _plainTileInput({
  List<double> rafterHeights = const [5000],
  double gutterOverhang = 50,
  String useDryRidge = 'NO',
}) {
  return VerticalCalculationInput(
    rafterHeights: rafterHeights,
    gutterOverhang: gutterOverhang,
    useDryRidge: useDryRidge,
  );
}

void main() {
  group('VerticalCalculationService', () {
    test('returns Invalid when rafter heights are below minimum', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(rafterHeights: [400]),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      expect(result.solution, 'Invalid');
      expect(result.warning, isNotNull);
      expect(result.totalCourses, 0);
    });

    test('returns Invalid when rafter is too short for gauge zone', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(
          rafterHeights: [250],
          gutterOverhang: 50,
        ),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      expect(result.solution, 'Invalid');
      expect(result.warning, isNotNull);
    });

    test('computes a valid solution for a typical rafter height', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.warning, isNull);
      expect(result.totalCourses, greaterThan(0));
      expect(result.firstBatten, 200);
      expect(result.eaveBatten, 150);
      expect(result.underEaveBatten, isNull);
      expect(result.ridgeOffset, greaterThanOrEqualTo(kRidgeOffsetMinMm));
      expect(result.ridgeOffset, lessThanOrEqualTo(kRidgeOffsetWetMaxMm));
      expect(result.gauge, isNot('N/A'));
    });

    test('omits under eave batten for interlocking concrete tiles', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(),
        materialType: 'Concrete Tile',
        slateTileHeight: 420,
        maxGauge: 345,
        minGauge: 300,
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.eaveBatten, 345);
      expect(result.underEaveBatten, isNull);
      expect(result.firstBatten, result.eaveBatten);
    });

    test('populates under eave batten for fibre cement slate', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(),
        materialType: 'Fibre Cement Slate',
        slateTileHeight: 600,
        maxGauge: 345,
        minGauge: 300,
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.eaveBatten, 230);
      expect(result.firstBatten, 575);
      expect(result.underEaveBatten, 130);
    });

    test('finds valid solutions for wet and dry ridge allowances', () async {
      final withoutDryRidge = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(useDryRidge: 'NO'),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );
      final withDryRidge = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(useDryRidge: 'YES'),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      expect(withoutDryRidge.solution, isNot('Invalid'));
      expect(withDryRidge.solution, isNot('Invalid'));
      expect(
        isRidgeOffsetInBounds(withoutDryRidge.ridgeOffset, 'NO'),
        isTrue,
      );
      expect(
        isRidgeOffsetInBounds(withDryRidge.ridgeOffset, 'YES'),
        isTrue,
      );
    });

    test('finds per-position gauges for rafter height spread', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(
          rafterHeights: [5000, 5200, 4800],
        ),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.rafterDetails, hasLength(3));
      for (final detail in result.rafterDetails!) {
        expect(isRidgeOffsetInBounds(detail.ridgeOffset, 'NO'), isTrue);
        expect(
          detail.rafterHeight,
          result.firstBatten! +
              (result.totalCourses - 1) * detail.gauge +
              detail.ridgeOffset,
        );
      }
      expect(
        result.rafterDetails!.map((detail) => detail.gauge).toSet(),
        hasLength(greaterThan(1)),
      );
    });

    test('populates per-rafter details within ridge bounds for small spread',
        () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(
          rafterHeights: [5000, 5010, 4990],
        ),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      expect(result.solution, isNot('Invalid'));
      expect(result.rafterDetails, isNotNull);
      expect(result.rafterDetails, hasLength(3));
      for (final detail in result.rafterDetails!) {
        expect(isRidgeOffsetInBounds(detail.ridgeOffset, 'NO'), isTrue);
      }
      expect(
        result.rafterDetails!.map((detail) => detail.ridgeOffset).toSet(),
        hasLength(greaterThan(1)),
      );
    });

    test('round-trips rafterDetails through json', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: _plainTileInput(rafterHeights: [5000, 5010]),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        maxGauge: 115,
        minGauge: 85,
      );

      final restored = VerticalCalculationResult.fromJson(result.toJson());
      expect(restored.rafterDetails, hasLength(2));
      expect(restored.rafterDetails!.first.rafterHeight, 5000);
      expect(restored.rafterDetails!.first.gauge, greaterThan(0));
    });
  });
}