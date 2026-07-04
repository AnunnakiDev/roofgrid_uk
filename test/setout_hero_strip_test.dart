import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/widgets/setout_hero_strip.dart';

void main() {
  group('SetoutHeroStrip', () {
    testWidgets('metric tiles fit narrow 3-column grid without overflow',
        (tester) async {
      const result = VerticalCalculationResult(
        inputRafter: 5252,
        totalCourses: 16,
        solution: 'Even Courses',
        ridgeOffset: 32,
        eaveBatten: 345,
        firstBatten: 345,
        gauge: '15 @ 325',
      );

      final rows = verticalHeroRows(
        result: result,
        materialType: 'Concrete Tile',
        slopes: const [SlopeInputEntry(label: 'Rafter 1', value: 5252)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: SetoutHeroStrip(
                rows: rows,
                fontSize: 14,
                crossAxisCount: 3,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('metric tiles fit phone-width grid without overflow',
        (tester) async {
      const result = VerticalCalculationResult(
        inputRafter: 5252,
        totalCourses: 45,
        solution: 'Even Courses',
        ridgeOffset: 36,
        eaveBatten: 150,
        firstBatten: 200,
        gauge: '44 @ 114',
      );

      final rows = verticalHeroRows(
        result: result,
        materialType: 'Plain Tile',
        slopes: const [SlopeInputEntry(label: 'Rafter 1', value: 5252)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 301,
              child: SetoutHeroStrip(
                rows: rows,
                fontSize: 14,
                crossAxisCount: 3,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}