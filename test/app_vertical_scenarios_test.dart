import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/vertical_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/vertical_result_formatting.dart';

Future<VerticalCalculationInput> _input(List<double> heights) async {
  return VerticalCalculationInput(
    rafterHeights: heights,
    gutterOverhang: 50,
    useDryRidge: 'NO',
  );
}

void main() {
  group('app vertical manual scenarios', () {
    test('scenario 1 plain tile 5000 even job', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: await _input([5000]),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        minGauge: 85,
        maxGauge: 115,
      );

      expect(result.solution, 'Even Courses');
      final rows = verticalSummaryRows(
        result: result,
        materialType: 'Plain Tile',
      );
      expect(rows.singleWhere((r) => r.label == 'Eave batten').value, '150');
      expect(
        rows.singleWhere((r) => r.label == 'First gauge batten').value,
        '200',
      );
      expect(
        rows.singleWhere((r) => r.label == 'Gauge').value,
        '43 @ 111',
      );
      expect(rows.singleWhere((r) => r.label == 'Battens').value, '43');
    });

    test('scenario 2 fibre cement under-eave', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: await _input([5000]),
        materialType: 'Fibre Cement Slate',
        slateTileHeight: 600,
        minGauge: 235,
        maxGauge: 255,
      );

      expect(result.underEaveBatten, 220);
      expect(result.firstBatten, 575);
    });

    test('scenario 5 invalid rafter 250', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: await _input([250]),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        minGauge: 85,
        maxGauge: 115,
      );

      expect(result.solution, 'Invalid');
      final rows = verticalSummaryRows(
        result: result,
        materialType: 'Plain Tile',
      );
      expect(rows, hasLength(2));
      expect(findLabel(rows, 'Gauge'), isNull);
    });

    test('scenario 3 multi-rafter varies by position', () async {
      final result = await VerticalCalculationService.calculateVertical(
        input: await _input([5000, 5010, 4990]),
        materialType: 'Plain Tile',
        slateTileHeight: 265,
        minGauge: 85,
        maxGauge: 115,
      );

      expect(result.solution, 'Even Courses');
      expect(gaugeSummaryValue(result), isNot(contains('Varies')));
      expect(ridgeOffsetSummaryValue(result), 'Varies by position (see details)');

      final hero = verticalHeroRows(
        result: result,
        materialType: 'Plain Tile',
        slopes: const [
          SlopeInputEntry(label: 'Rafter 1', value: 5000),
          SlopeInputEntry(label: 'Rafter 2', value: 5010),
          SlopeInputEntry(label: 'Rafter 3', value: 4990),
        ],
      );
      final gaugeTiles = hero
          .where((row) => !{
                'Eave batten',
                'First gauge batten',
                'Battens',
                'Under-eave batten',
                'Cut course',
              }.contains(row.label))
          .toList();
      expect(gaugeTiles, hasLength(3));
      expect(gaugeTiles.every((row) => row.value.contains('@')), isTrue);
    });
  });
}

String? findLabel(List<ResultDisplayRow> rows, String label) {
  for (final row in rows) {
    if (row.label == label) return row.value;
  }
  return null;
}