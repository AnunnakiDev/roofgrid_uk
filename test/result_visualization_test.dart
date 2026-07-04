import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/widgets/result_visualization.dart';

void main() {
  group('ensureMinimumLabeledEntries', () {
    test('pads a single rafter with a ghost entry', () {
      final result = ensureMinimumLabeledEntries(
        entries: [
          {'label': 'Front Slope', 'value': 5000},
        ],
        minimum: 2,
        labelPrefix: 'Rafter',
        defaultValue: 5000,
      );

      expect(result, hasLength(2));
      expect(result[0]['label'], 'Front Slope');
      expect(result[1]['label'], 'Rafter 2');
      expect(result[1]['value'], 5000);
    });

    test('creates default entries when list is empty', () {
      final result = ensureMinimumLabeledEntries(
        entries: const [],
        minimum: 2,
        labelPrefix: 'Width',
        defaultValue: 4200,
      );

      expect(result, hasLength(2));
      expect(result[0]['label'], 'Width 1');
      expect(result[1]['label'], 'Width 2');
    });
  });

  group('ResultVisualization', () {
    testWidgets('renders with non-zero layout for inline preview',
        (tester) async {
      const verticalResult = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 24,
        solution: 'Valid',
        ridgeOffset: 50,
        firstBatten: 100,
        gauge: '30 @ 190',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: ResultVisualization(
                verticalResult: verticalResult,
                gutterOverhang: 50,
                rafterHeights: const [
                  {'label': 'Front Slope', 'value': 5000},
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No results to visualize'), findsNothing);

      final aspectRatio =
          tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, kVisualizationA3AspectRatio);
    });

    testWidgets('thumbnail fills the provided bounds', (tester) async {
      const verticalResult = VerticalCalculationResult(
        inputRafter: 5000,
        totalCourses: 24,
        solution: 'Valid',
        ridgeOffset: 50,
        firstBatten: 100,
        gauge: '30 @ 190',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60,
              height: 60,
              child: ResultVisualization(
                verticalResult: verticalResult,
                gutterOverhang: 50,
                isThumbnail: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AspectRatio), findsNothing);
      expect(find.byType(ResultVisualization), findsOneWidget);
    });
  });
}