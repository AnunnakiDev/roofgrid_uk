import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';

SavedResult _sampleResult({
  required CalculationType type,
  required Map<String, dynamic> inputs,
}) {
  final now = DateTime(2026, 1, 1);
  return SavedResult(
    id: 'r1',
    userId: 'u1',
    projectName: 'Test',
    type: type,
    timestamp: now,
    inputs: inputs,
    outputs: const {},
    tile: const {'name': 'Plain tile'},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('normalizeSavedResultInputsMap', () {
    test('wraps flat vertical inputs', () {
      final normalized = normalizeSavedResultInputsMap(
        CalculationType.vertical,
        {
          'rafterHeights': [
            {'label': 'Rafter 1', 'value': 5000.0},
          ],
          'gutterOverhang': 50.0,
          'useDryRidge': 'NO',
        },
      );

      expect(normalized['vertical_inputs'], isA<Map<String, dynamic>>());
      expect(
        (normalized['vertical_inputs'] as Map)['rafterHeights'],
        isNotEmpty,
      );
      expect(normalized.containsKey('rafterHeights'), isFalse);
    });

    test('wraps flat horizontal inputs', () {
      final normalized = normalizeSavedResultInputsMap(
        CalculationType.horizontal,
        {
          'widths': [
            {'label': 'Width 1', 'value': 4200.0},
          ],
          'useDryVerge': 'NO',
        },
      );

      expect(normalized['horizontal_inputs'], isA<Map<String, dynamic>>());
      expect(normalized.containsKey('widths'), isFalse);
    });

    test('leaves combined nested inputs unchanged', () {
      final inputs = {
        'vertical_inputs': {'gutterOverhang': 50.0},
        'horizontal_inputs': {'useDryVerge': 'NO'},
      };
      final normalized = normalizeSavedResultInputsMap(
        CalculationType.combined,
        inputs,
      );
      expect(normalized, inputs);
    });

    test('wraps flat combined inputs into nested maps', () {
      final normalized = normalizeSavedResultInputsMap(
        CalculationType.combined,
        {
          'rafterHeights': [
            {'label': 'Rafter 1', 'value': 5000.0},
          ],
          'gutterOverhang': 30.0,
          'useDryRidge': 'YES',
          'widths': [
            {'label': 'Width 1', 'value': 4200.0},
          ],
          'useDryVerge': 'YES',
          'abutmentSide': 'LEFT',
          'useLHTile': 'NO',
          'crossBonded': 'NO',
        },
      );

      expect(normalized['vertical_inputs'], isA<Map<String, dynamic>>());
      expect(normalized['horizontal_inputs'], isA<Map<String, dynamic>>());
      expect(
        (normalized['vertical_inputs'] as Map)['gutterOverhang'],
        30.0,
      );
      expect(normalized.containsKey('rafterHeights'), isFalse);
      expect(normalized.containsKey('widths'), isFalse);
    });
  });

  group('normalizeSavedResult', () {
    test('returns new instance when legacy flat inputs are normalized', () {
      final result = _sampleResult(
        type: CalculationType.vertical,
        inputs: {
          'rafterHeights': [
            {'label': 'Rafter 1', 'value': 5000.0},
          ],
          'gutterOverhang': 50.0,
        },
      );

      final normalized = normalizeSavedResult(result);
      expect(normalized.inputs['vertical_inputs'], isNotNull);
      expect(identical(result, normalized), isFalse);
    });
  });
}