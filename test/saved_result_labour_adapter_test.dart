import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/saved_result_labour_adapter.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

SavedResult _multiBayResult() {
  final now = DateTime(2026, 1, 1);
  return SavedResult(
    id: 'job-multi',
    userId: 'u1',
    projectName: 'Multi-bay site',
    type: CalculationType.combined,
    timestamp: now,
    inputs: {
      'vertical_inputs': {
        'rafterHeights': [
          {'label': 'Rafter 1', 'value': 5000.0},
          {'label': 'Rafter 2', 'value': 4000.0},
        ],
      },
      'horizontal_inputs': {
        'widths': [
          {'label': 'Width 1', 'value': 6000.0},
          {'label': 'Width 2', 'value': 5000.0},
        ],
      },
    },
    outputs: const {},
    tile: const {'materialType': 'pantile'},
    createdAt: now,
    updatedAt: now,
  );
}

SavedResult _combinedResult({
  required String materialType,
  double rafterMm = 5000,
  double widthMm = 6000,
  String useDryRidge = 'NO',
  String useDryVerge = 'NO',
}) {
  final now = DateTime(2026, 1, 1);
  return SavedResult(
    id: 'job-1',
    userId: 'u1',
    projectName: 'Site job',
    type: CalculationType.combined,
    timestamp: now,
    inputs: {
      'vertical_inputs': {
        'rafterHeights': [
          {'label': 'Rafter 1', 'value': rafterMm},
        ],
        'gutterOverhang': 50.0,
        'useDryRidge': useDryRidge,
      },
      'horizontal_inputs': {
        'widths': [
          {'label': 'Width 1', 'value': widthMm},
        ],
        'useDryVerge': useDryVerge,
      },
    },
    outputs: const {},
    tile: {'materialType': materialType, 'name': 'Test tile'},
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('SavedResultLabourAdapter', () {
    test('maps slate tile to slate roof type', () {
      expect(
        SavedResultLabourAdapter.roofTypeFromTile({'materialType': 'Slate'}),
        LabourRoofType.naturalSlate,
      );
    });

    test('derives area and linear quantities from combined saved job', () {
      final measurements = SavedResultLabourAdapter.measurementsFromSavedResult(
        _combinedResult(materialType: 'pantile'),
      );

      expect(measurements.roofAreaSqm, closeTo(30, 0.01));
      expect(measurements.ridgeMetres, closeTo(6, 0.01));
      expect(measurements.vergeMetres, closeTo(10, 0.01));
    });

    test('maps dry ridge flag to dry ridge linear item', () {
      final input = SavedResultLabourAdapter.inputFromSavedResult(
        _combinedResult(
          materialType: 'pantile',
          useDryRidge: 'YES',
        ),
      );

      expect(input, isNotNull);
      expect(input!.linearMetres[LabourLinearItem.dryRidge], closeTo(6, 0.01));
      expect(input.linearMetres[LabourLinearItem.ridge], isNull);
    });

    test('inputFromSavedResult builds labour quote input', () {
      final input = SavedResultLabourAdapter.inputFromSavedResult(
        _combinedResult(materialType: 'plainTile'),
      );

      expect(input, isNotNull);
      expect(input!.roofType, LabourRoofType.plainTile);
      expect(input.roofAreaSqm, closeTo(30, 0.01));
      expect(input.linearMetres[LabourLinearItem.ridge], closeTo(6, 0.01));
      expect(input.linearMetres[LabourLinearItem.verge], closeTo(10, 0.01));
      expect(input.includeStrip, isTrue);
    });

    test('projectFromSavedResult creates one section per bay', () {
      final project = SavedResultLabourAdapter.projectFromSavedResult(
        _multiBayResult(),
      );

      expect(project, isNotNull);
      expect(project!.sections, hasLength(2));
      expect(project.sections[0].label, 'Rafter 1 / Width 1');
      expect(project.sections[1].label, 'Rafter 2 / Width 2');
      expect(project.sections[0].input.roofAreaSqm, closeTo(30, 0.01));
      expect(project.sections[1].input.roofAreaSqm, closeTo(20, 0.01));
      expect(
        project.sections[0].input.linearMetres[LabourLinearItem.ridge],
        closeTo(6, 0.01),
      );
      expect(
        project.sections[0].input.linearMetres[LabourLinearItem.verge],
        closeTo(10, 0.01),
      );
      expect(project.customerName, 'Multi-bay site');
    });

    test('returns null when tile material is missing', () {
      final now = DateTime(2026, 1, 1);
      final result = SavedResult(
        id: 'x',
        userId: 'u1',
        projectName: 'No tile',
        type: CalculationType.vertical,
        timestamp: now,
        inputs: const {},
        outputs: const {},
        tile: const {},
        createdAt: now,
        updatedAt: now,
      );

      expect(SavedResultLabourAdapter.inputFromSavedResult(result), isNull);
    });
  });
}