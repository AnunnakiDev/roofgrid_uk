import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';

/// Narrow slate width that resolves via cut tile (pinned site edge case).
void main() {
  test('golden cut tile slate 501 mm width reconciles', () {
    final input = HorizontalCalculationInput(
      widths: const [501],
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
    expect(result.cutTile, 100);
    expect(result.newWidth, 601);
    expect(adjustedWidthFromResult(result), 601);

    final issues = validateHorizontalReconciles(input: input, result: result);
    expect(issues, isEmpty, reason: issues.map((i) => i.message).join('; '));
  });
}