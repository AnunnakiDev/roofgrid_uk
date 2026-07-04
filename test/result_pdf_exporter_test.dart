import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/services/result_pdf_exporter.dart';

SavedResult _sampleVerticalResult() {
  final now = DateTime(2026, 3, 15, 10, 30);
  return SavedResult(
    id: 'result-1',
    userId: 'user-1',
    projectName: 'Test Roof',
    type: CalculationType.vertical,
    timestamp: now,
    inputs: {
      'vertical_inputs': {
        'gutterOverhang': 50.0,
        'useDryRidge': 'NO',
        'rafterHeights': [
          {'label': 'Rafter 1', 'value': 5000.0},
        ],
      },
    },
    outputs: {
      'inputRafter': 5000,
      'totalCourses': 24,
      'solution': 'Even Courses',
      'ridgeOffset': 50,
      'firstBatten': 100,
      'gauge': '30 @ 190',
    },
    tile: {
      'name': 'Test Pantile',
      'materialType': 'pantile',
      'tileCoverWidth': 250,
      'slateTileHeight': 300,
    },
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('ResultPdfExporter generates non-empty PDF bytes', () async {
    final bytes = await ResultPdfExporter.generateBytes(_sampleVerticalResult());

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}