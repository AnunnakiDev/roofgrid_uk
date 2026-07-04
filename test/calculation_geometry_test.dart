import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/calculation_geometry.dart';

void main() {
  group('calculation_geometry', () {
    test('parses at notation gauge strings', () {
      expect(parseAtNotation('23 @ 95')?.spacingMm, 95);
      expect(parseAtNotation('23 @ 95mm')?.count, 23);
    });

    test('parses sets notation mark strings', () {
      final parsed = parseSetsNotation('12 sets of 3 @ 516');
      expect(parsed?.setCount, 12);
      expect(parsed?.tilesPerSet, 3);
      expect(parsed?.spacingMm, 516);
    });

    test('resolves vertical and horizontal spacing from result models', () {
      const verticalResult = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 24,
        solution: 'Even Courses',
        ridgeOffset: 50,
        firstBatten: 100,
        gauge: '23 @ 95',
        splitGauge: '5 @ 100',
      );
      const horizontalResult = HorizontalCalculationResult(
        width: 6000,
        solution: 'Even Sets',
        newWidth: 6100,
        firstMark: 100,
        marks: '12 sets of 3 @ 516',
        splitMarks: '4 sets of 3 @ 500',
      );

      expect(resolveVerticalGaugeSpacingMm(verticalResult), 100);
      expect(resolveHorizontalMarksSpacingMm(horizontalResult), 500);
    });
  });
}