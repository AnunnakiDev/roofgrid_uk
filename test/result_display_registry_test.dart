import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/rafter_calculation_detail.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/width_calculation_detail.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/vertical_result_formatting.dart';

VerticalCalculationResult _verticalResult({
  List<RafterCalculationDetail>? rafterDetails,
  int ridgeOffset = 50,
  String solution = 'Even Courses',
  String gauge = '39 @ 113',
}) {
  return VerticalCalculationResult(
    inputRafter: 5200,
    totalCourses: 40,
    solution: solution,
    ridgeOffset: ridgeOffset,
    eaveBatten: 150,
    firstBatten: 200,
    gauge: gauge,
    rafterDetails: rafterDetails,
  );
}

HorizontalCalculationResult _horizontalResult({
  List<WidthCalculationDetail>? widthDetails,
}) {
  return HorizontalCalculationResult(
    width: 6000,
    solution: 'Split Sets',
    newWidth: 6100,
    firstMark: 500,
    secondMark: 650,
    marks: '4 sets of 3 @ 520',
    splitMarks: '2 sets of 3 @ 500',
    actualSpacing: 6,
    widthDetails: widthDetails,
  );
}

void main() {
  group('result_display_registry', () {
    test('vertical summary includes batten datums and full-sentence gauge',
        () {
      final rows = verticalSummaryRows(
        result: _verticalResult(),
        materialType: 'Plain Tile',
      );
      final labels = rows.map((row) => row.label).toList();

      expect(labels, contains('Eave batten'));
      expect(labels, contains('First gauge batten'));
      expect(labels, contains('Battens'));
      expect(labels, contains('Ridge offset (full)'));
      expect(labels, contains('Courses (inc. eave)'));
      expect(
        rows.singleWhere((row) => row.label == 'Gauge (full)').value,
        '39 battens @ 113 mm',
      );
      expect(labels, isNot(contains('Split Gauge')));
    });

    test('invalid summary shows only solution and reason', () {
      final rows = verticalSummaryRows(
        result: const VerticalCalculationResult(
          inputRafter: 400,
          totalCourses: 0,
          solution: 'Invalid',
          ridgeOffset: 0,
          firstBatten: 0,
          gauge: 'N/A',
          warning: 'Rafter height too short.',
        ),
        materialType: 'Plain Tile',
      );

      expect(rows, hasLength(2));
      expect(rows.first.label, 'Solution');
      expect(rows.last.value, 'Rafter height too short.');
    });

    test('ridge offset summary notes variation across positions', () {
      final result = _verticalResult(
        rafterDetails: const [
          RafterCalculationDetail(rafterHeight: 5000, gauge: 111, ridgeOffset: 98),
          RafterCalculationDetail(rafterHeight: 5200, gauge: 111, ridgeOffset: 298),
        ],
      );

      expect(ridgeOffsetSummaryValue(result), 'Varies by position (see details)');
    });

    test('cut course appears in summary when details are present', () {
      final rows = verticalSummaryRows(
        result: VerticalCalculationResult(
          inputRafter: 5000,
          totalCourses: 10,
          solution: 'Cut Course',
          ridgeOffset: 25,
          firstBatten: 200,
          eaveBatten: 150,
          gauge: '8 @ 115',
          rafterDetails: const [
            RafterCalculationDetail(
              rafterHeight: 5000,
              gauge: 115,
              ridgeOffset: 25,
              cutCourse: 108,
            ),
          ],
        ),
        materialType: 'Plain Tile',
      );

      expect(
        rows.singleWhere((row) => row.label == 'Cut course').value,
        '108',
      );
    });

    test('vertical hero omits duplicate first gauge for interlocking profile',
        () {
      final rows = verticalHeroRows(
        result: const VerticalCalculationResult(
          inputRafter: 5000,
          totalCourses: 40,
          solution: 'Even Courses',
          ridgeOffset: 27,
          eaveBatten: 175,
          firstBatten: 175,
          gauge: '39 @ 113',
        ),
        materialType: 'Interlocking Tile',
      );
      final labels = rows.map((row) => row.label).toList();

      expect(labels, contains('Eave batten'));
      expect(labels, isNot(contains('First gauge batten')));
    });

    test('vertical hero shows both battens for plain tile', () {
      final rows = verticalHeroRows(
        result: _verticalResult(),
        materialType: 'Plain Tile',
      );
      final labels = rows.map((row) => row.label).toList();

      expect(labels, contains('Eave batten'));
      expect(labels, contains('First gauge batten'));
    });

    test('split gauge hero shows two gauge tiles and battens not ridge offset',
        () {
      final rows = verticalHeroRows(
        result: VerticalCalculationResult(
          inputRafter: 5000,
          totalCourses: 40,
          solution: 'Split Courses',
          ridgeOffset: 27,
          eaveBatten: 150,
          firstBatten: 200,
          gauge: '20 @ 111',
          splitGauge: '19 @ 110',
        ),
        materialType: 'Plain Tile',
      );
      final labels = rows.map((row) => row.label).toList();

      expect(labels, contains('Lower gauge'));
      expect(labels, contains('Upper gauge'));
      expect(labels, contains('Battens'));
      expect(labels, isNot(contains('Ridge offset')));
      expect(
        rows.singleWhere((row) => row.label == 'Lower gauge').value,
        '19 @ 110',
      );
      expect(
        rows.singleWhere((row) => row.label == 'Upper gauge').value,
        '20 @ 111',
      );
      expect(rows.singleWhere((row) => row.label == 'Battens').value, '39');
    });

    test('horizontal hero includes verge overhangs when present', () {
      final rows = horizontalHeroRows(
        HorizontalCalculationResult(
          width: 6000,
          solution: 'Even Sets',
          newWidth: 6100,
          firstMark: 500,
          marks: '6 sets of 3 @ 513',
          lhOverhang: 40,
          rhOverhang: 45,
        ),
      );
      final labels = rows.map((row) => row.label).toList();

      expect(labels, contains('LH verge'));
      expect(labels, contains('RH verge'));
      expect(
        rows.singleWhere((row) => row.label == 'Adjusted width').value,
        '6085',
      );
    });

    test('vertical detail sections use formatted gauge per position', () {
      final result = _verticalResult(
        rafterDetails: const [
          RafterCalculationDetail(rafterHeight: 5000, gauge: 111, ridgeOffset: 98),
          RafterCalculationDetail(
            rafterHeight: 5200,
            gauge: 111,
            ridgeOffset: 298,
            cutCourse: 120,
          ),
        ],
      );

      final sections = verticalDetailSections(
        result: result,
        slopes: const [
          SlopeInputEntry(label: 'Rafter A', value: 5000),
          SlopeInputEntry(label: 'Rafter B', value: 5200),
        ],
      );

      expect(
        sections[0].singleWhere((row) => row.label == 'Gauge').value,
        '39 battens @ 111 mm',
      );
      expect(
        sections[1].singleWhere((row) => row.label == 'Cut course').value,
        '120 mm',
      );
    });

    test('legacy vertical json loads without firstBatten', () {
      final restored = VerticalCalculationResult.fromJson({
        'inputRafter': 5000,
        'totalCourses': 40,
        'solution': 'Even Courses',
        'ridgeOffset': 27,
        'eaveBatten': 150,
        'gauge': '39 @ 113',
        'rafterDetails': [
          {
            'rafterHeight': 5000,
            'ridgeOffset': 27,
          },
        ],
      });

      expect(restored.firstBatten, 150);
      expect(restored.rafterDetails!.first.gauge, 0);
      expect(
        gaugeSummaryValue(restored),
        '39 battens @ 113 mm',
      );
    });

    test('horizontal summary keeps marks notation without extra units', () {
      final rows = horizontalSummaryRows(_horizontalResult());

      expect(
        rows.singleWhere((row) => row.label == 'Marks (full)').value,
        '2 sets of 3 @ 500 + 4 sets of 3 @ 520',
      );
      expect(
        rows.singleWhere((row) => row.label == 'Split marks').value,
        '2 sets of 3 @ 500',
      );
      expect(
        rows.singleWhere((row) => row.label == 'Even marks').value,
        '4 sets of 3 @ 520',
      );
    });

    test('degenerate split sets summary shows even sets solution', () {
      final rows = horizontalSummaryRows(
        const HorizontalCalculationResult(
          width: 6500,
          solution: 'Split Sets',
          newWidth: 6600,
          firstMark: 592,
          marks: '10 sets of 2 @ 600',
          splitMarks: '0 sets of 2 @ 600',
          actualSpacing: 5,
        ),
      );

      expect(
        rows.singleWhere((row) => row.label == 'Solution').value,
        'Even Sets',
      );
      expect(
        rows.any((row) => row.label == 'Split marks'),
        isFalse,
      );
      expect(
        rows.singleWhere((row) => row.label == 'Marks (full)').value,
        '10 sets of 2 @ 600',
      );
    });

    test('horizontal detail sections use widthDetails per width', () {
      final result = _horizontalResult(
        widthDetails: const [
          WidthCalculationDetail(
            inputWidth: 6000,
            totalWidth: 6100,
            firstMark: 500,
            secondMark: 650,
            lhOverhang: 40,
            rhOverhang: 45,
          ),
          WidthCalculationDetail(
            inputWidth: 5800,
            totalWidth: 5900,
            firstMark: 480,
            secondMark: 630,
            cutTile: 90,
          ),
        ],
      );

      final sections = horizontalDetailSections(
        result: result,
        widths: const [
          WidthInputEntry(label: 'Front', value: 6000),
          WidthInputEntry(label: 'Rear', value: 5800),
        ],
      );

      expect(
        sections[0].singleWhere((row) => row.label == 'First mark').value,
        '500 mm',
      );
      expect(
        sections[1].singleWhere((row) => row.label == 'Cut tile').value,
        '90 mm',
      );
      expect(
        sections[1].singleWhere((row) => row.label == 'First mark').value,
        '480 mm',
      );
    });
  });
}