import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';

void main() {
  group('shouldShowDistinctFirstGaugeBatten', () {
    test('returns true when eave and first gauge differ (plain tile)', () {
      const result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 40,
        solution: 'Even Courses',
        ridgeOffset: 27,
        eaveBatten: 150,
        firstBatten: 200,
        gauge: '39 @ 113',
      );

      expect(shouldShowDistinctFirstGaugeBatten(result), isTrue);
    });

    test('returns false when eave equals first gauge (interlocking)', () {
      const result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 40,
        solution: 'Even Courses',
        ridgeOffset: 27,
        eaveBatten: 175,
        firstBatten: 175,
        gauge: '39 @ 113',
      );

      expect(shouldShowDistinctFirstGaugeBatten(result), isFalse);
    });

    test('returns false when eave batten is null', () {
      const result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 40,
        solution: 'Even Courses',
        ridgeOffset: 27,
        firstBatten: 200,
        gauge: '39 @ 113',
      );

      expect(shouldShowDistinctFirstGaugeBatten(result), isFalse);
    });
  });
}