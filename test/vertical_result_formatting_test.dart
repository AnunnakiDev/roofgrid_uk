import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/rafter_calculation_detail.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/vertical_result_formatting.dart';

void main() {
  group('vertical_result_formatting', () {
    test('formatGaugeSentence uses full battens notation', () {
      expect(
        formatGaugeSentence(battens: 43, gaugeMm: 111),
        '43 battens @ 111 mm',
      );
    });

    test('heroGaugeTiles returns one tile per slope input', () {
      final result = VerticalCalculationResult(
        inputRafter: 5200,
        totalCourses: 40,
        solution: 'Even Courses',
        ridgeOffset: 27,
        firstBatten: 200,
        eaveBatten: 150,
        gauge: '39 @ 113',
        rafterDetails: const [
          RafterCalculationDetail(rafterHeight: 5000, gauge: 111, ridgeOffset: 98),
          RafterCalculationDetail(rafterHeight: 5200, gauge: 112, ridgeOffset: 298),
          RafterCalculationDetail(rafterHeight: 4990, gauge: 113, ridgeOffset: 88),
        ],
      );

      final tiles = heroGaugeTiles(
        result,
        slopeLabels: const ['Rafter A', 'Rafter B', 'Rafter C'],
      );

      expect(tiles, hasLength(3));
      expect(tiles[0].label, 'Rafter A');
      expect(tiles[0].value, '39 @ 111');
      expect(tiles[1].value, '39 @ 112');
      expect(tiles[2].value, '39 @ 113');
    });

    test('heroGaugeTiles returns two tiles for split courses', () {
      const result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 40,
        solution: 'Split Courses',
        ridgeOffset: 27,
        firstBatten: 200,
        eaveBatten: 150,
        gauge: '20 @ 111',
        splitGauge: '19 @ 110',
      );

      final tiles = heroGaugeTiles(result);
      expect(tiles, hasLength(2));
      expect(tiles[0].value, '19 @ 110');
      expect(tiles[1].value, '20 @ 111');
      expect(heroBattenCount(result), 39);
    });

    test('heroGaugeValue uses compact notation', () {
      const result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 44,
        solution: 'Even Courses',
        ridgeOffset: 27,
        firstBatten: 200,
        eaveBatten: 150,
        gauge: '43 @ 111',
      );

      expect(heroGaugeValue(result), '43 @ 111 mm');
    });

    test('gaugeSummaryValue formats even courses from at notation', () {
      const result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 44,
        solution: 'Even Courses',
        ridgeOffset: 27,
        firstBatten: 200,
        eaveBatten: 150,
        gauge: '43 @ 111',
      );

      expect(gaugeSummaryValue(result), '43 battens @ 111 mm');
    });

    test('gaugeSummaryValue notes varying per-position gauges', () {
      final result = VerticalCalculationResult(
        inputRafter: 5200,
        totalCourses: 44,
        solution: 'Even Courses',
        ridgeOffset: 27,
        firstBatten: 200,
        gauge: '43 @ 111',
        rafterDetails: const [
          RafterCalculationDetail(rafterHeight: 5000, gauge: 111, ridgeOffset: 40),
          RafterCalculationDetail(rafterHeight: 5200, gauge: 112, ridgeOffset: 30),
        ],
      );

      expect(gaugeSummaryValue(result), 'Varies by position (see details)');
    });

    test('summaryCutCourseMm reads from rafter details', () {
      final result = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 10,
        solution: 'Cut Course',
        ridgeOffset: 25,
        firstBatten: 200,
        gauge: '8 @ 115',
        rafterDetails: const [
          RafterCalculationDetail(
            rafterHeight: 5000,
            gauge: 115,
            ridgeOffset: 25,
            cutCourse: 108,
          ),
        ],
      );

      expect(summaryCutCourseMm(result), 108);
    });
  });
}