import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/app/calculator/services/vertical_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/utils/horizontal_result_fields.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';

/// Sandtoft-style concrete pantile profile (295 mm cover, 6000 mm width).
void main() {
  test('concrete pantile 6000 wet verge reconciles and displays even sets', () async {
    const materialType = 'Concrete Tile';
    const tileCoverWidth = 295.0;
    const minSpacing = 1.0;
    const maxSpacing = 5.0;
    const minGauge = 300.0;
    const maxGauge = 345.0;
    const slateTileHeight = 420.0;

    final horizontalInput = HorizontalCalculationInput(
      widths: const [6000],
      tileCoverWidth: tileCoverWidth,
      minSpacing: minSpacing,
      maxSpacing: maxSpacing,
      lhTileWidth: tileCoverWidth,
      useDryVerge: 'NO',
      abutmentSide: 'NONE',
      useLHTile: 'NO',
      crossBonded: 'NO',
      materialType: materialType,
    );

    final vertical = await VerticalCalculationService.calculateVertical(
      input: VerticalCalculationInput(
        rafterHeights: const [5252],
        gutterOverhang: 50,
        useDryRidge: 'NO',
      ),
      materialType: materialType,
      slateTileHeight: slateTileHeight,
      maxGauge: maxGauge,
      minGauge: minGauge,
    );

    final horizontal = HorizontalCalculationService.calculateHorizontal(horizontalInput);

    expect(vertical.solution, 'Even Courses');
    expect(horizontal.solution, isNot('Invalid'));
    expect(horizontal.newWidth, 6100);
    expect(adjustedWidthFromResult(horizontal), 6050);
    expect(horizontal.lhOverhang, 25);
    expect(horizontal.rhOverhang, 25);
    expect(effectiveHorizontalSolution(horizontal), 'Even Sets');

    final issues = validateHorizontalReconciles(
      input: horizontalInput,
      result: horizontal,
    );
    expect(issues, isEmpty, reason: issues.map((i) => i.message).join('; '));
  });
}