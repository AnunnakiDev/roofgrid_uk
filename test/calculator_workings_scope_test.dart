import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';

void main() {
  test('vertical-only workings exclude horizontal input rows', () {
    final data = buildJobWorkingsData(
      gutterOverhang: 50,
      useDryRidge: 'NO',
      rafterHeights: [
        {'label': 'Rafter 1', 'value': 5000.0},
      ],
      useDryVerge: 'NO',
      abutmentSide: 'NONE',
      useLHTile: 'NO',
      crossBonded: 'NO',
      scope: CalculatorWorkingsScope.vertical,
    );

    expect(data.verticalInputRows, isNotEmpty);
    expect(data.horizontalInputRows, isEmpty);
    expect(data.horizontalWorkings, isEmpty);
    expect(data.verticalInputsTitle, 'Inputs');
    expect(data.horizontalInputsTitle, 'Horizontal inputs');
  });
}