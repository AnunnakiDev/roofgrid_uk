import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/widgets/calculator/schematic_preview_strip.dart';

void main() {
  testWidgets('SchematicPreviewStrip hides when no valid dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SchematicPreviewStrip(
            axis: SchematicPreviewAxis.verticalBatten,
            dimensionsMm: [0, -1],
          ),
        ),
      ),
    );

    expect(find.textContaining('Schematic'), findsNothing);
  });

  testWidgets('SchematicPreviewStrip shows caption for valid dimensions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SchematicPreviewStrip(
            axis: SchematicPreviewAxis.horizontalCourse,
            dimensionsMm: [4200],
          ),
        ),
      ),
    );

    expect(
      find.text('Schematic tile courses (not calculated)'),
      findsOneWidget,
    );
  });
}