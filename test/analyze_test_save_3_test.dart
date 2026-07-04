// Run: flutter test test/analyze_test_save_3_test.dart
@Tags(['debug'])
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/app/calculator/services/vertical_calculation_service.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';


import 'support/horizontal_debug_dump.dart';

const _hiveDumpPath = 'agent-tools/hive_dump/resultsbox_fresh.hive';

void main() {
  setUpAll(() async {
    Hive
      ..init(Directory.systemTemp.path)
      ..registerAdapter(CalculationTypeAdapter())
      ..registerAdapter(SavedResultAdapter());
  });

  test('analyze test save 3', () async {
    final source = File(_hiveDumpPath);
    final tempDir = Directory.systemTemp.createTempSync('roofgrid_analyze_');
    source.copySync('${tempDir.path}/resultsbox.hive');

    final box = await Hive.openBox<SavedResult>('resultsBox', path: tempDir.path);
    final saved = normalizeSavedResult(
      box.values.firstWhere((r) => r.projectName == 'test save 3'),
    );
    await box.close();
    tempDir.deleteSync(recursive: true);

    final tile = Map<String, dynamic>.from(saved.tile);
    final vIn = Map<String, dynamic>.from(
      saved.inputs['vertical_inputs'] as Map,
    );
    final hIn = Map<String, dynamic>.from(
      saved.inputs['horizontal_inputs'] as Map,
    );
    final vOut = Map<String, dynamic>.from(saved.outputs['vertical'] as Map);
    final hOut = Map<String, dynamic>.from(saved.outputs['horizontal'] as Map);

    final rafterHeights = (vIn['rafterHeights'] as List)
        .map((e) => (e as Map)['value'] as num)
        .toList();
    final widths = (hIn['widths'] as List)
        .map((e) => (e as Map)['value'] as num)
        .toList();

    final materialType = tile['materialType'] as String? ??
        (tile['TileSlateType'] as String? ?? 'Concrete Tile');

    final verticalInput = VerticalCalculationInput(
      rafterHeights: rafterHeights.map((v) => v.toDouble()).toList(),
      gutterOverhang: (vIn['gutterOverhang'] as num).toDouble(),
      useDryRidge: vIn['useDryRidge'] as String,
    );
    final horizontalInput = HorizontalCalculationInput(
      widths: widths.map((v) => v.toDouble()).toList(),
      tileCoverWidth: (tile['tileCoverWidth'] as num).toDouble(),
      minSpacing: (tile['minSpacing'] as num).toDouble(),
      maxSpacing: (tile['maxSpacing'] as num).toDouble(),
      lhTileWidth: (tile['tileCoverWidth'] as num).toDouble(),
      useDryVerge: hIn['useDryVerge'] as String,
      abutmentSide: hIn['abutmentSide'] as String,
      useLHTile: hIn['useLHTile'] as String,
      crossBonded: hIn['crossBonded'] as String,
      materialType: materialType,
    );

    final recomputedVertical = await VerticalCalculationService.calculateVertical(
      input: verticalInput,
      materialType: materialType,
      slateTileHeight: (tile['slateTileHeight'] as num).toDouble(),
      maxGauge: (tile['maxGauge'] as num).toDouble(),
      minGauge: (tile['minGauge'] as num).toDouble(),
    );
    final recomputedHorizontal =
        HorizontalCalculationService.calculateHorizontal(horizontalInput);

    final buffer = StringBuffer()
      ..writeln('=== test save 3 analysis ===')
      ..writeln('Tile: ${tile['name']} (${tile['materialType'] ?? tile['TileSlateType']})')
      ..writeln(
        'Cover ${tile['tileCoverWidth']} mm, height ${tile['slateTileHeight']} mm, '
        'gauge ${tile['minGauge']}-${tile['maxGauge']} mm, '
        'spacing ${tile['minSpacing']}-${tile['maxSpacing']} mm',
      )
      ..writeln('\n--- VERTICAL (saved) ---')
      ..writeln('Rafters: $rafterHeights')
      ..writeln('Solution: ${vOut['solution']}')
      ..writeln('Gauge: ${vOut['gauge']}')
      ..writeln('Courses: ${vOut['totalCourses']}')
      ..writeln('Eave batten: ${vOut['eaveBatten']} mm')
      ..writeln('Ridge offset: ${vOut['ridgeOffset']} mm')
      ..writeln('Warning: ${vOut['warning']}')
      ..writeln('Per-rafter: ${jsonEncode(vOut['rafterDetails'])}')
      ..writeln('\n--- VERTICAL (recomputed) ---')
      ..writeln('Solution: ${recomputedVertical.solution}')
      ..writeln('Gauge: ${recomputedVertical.gauge}')
      ..writeln('Courses: ${recomputedVertical.totalCourses}')
      ..writeln('Eave: ${recomputedVertical.eaveBatten} Ridge: ${recomputedVertical.ridgeOffset}')
      ..writeln('Warning: ${recomputedVertical.warning}')
      ..writeln('\n--- HORIZONTAL (saved) ---')
      ..writeln('Widths: $widths')
      ..writeln('Solution: ${hOut['solution']}')
      ..writeln('Design width (primary): ${hOut['newWidth']}')
      ..writeln(
        'Adjusted width (primary): '
        '${(hOut['width'] as int) + (hOut['lhOverhang'] as int) + (hOut['rhOverhang'] as int)}',
      )
      ..writeln('LH/RH verge: ${hOut['lhOverhang']}/${hOut['rhOverhang']}')
      ..writeln('Marks: ${hOut['marks']}')
      ..writeln('Split marks: ${hOut['splitMarks']}')
      ..writeln('Spacing: ${hOut['actualSpacing']}')
      ..writeln('First mark: ${hOut['firstMark']}')
      ..writeln('Width details: ${jsonEncode(hOut['widthDetails'])}')
      ..writeln('\n--- HORIZONTAL (recomputed) ---')
      ..writeln(dumpHorizontalCalculation(
        input: horizontalInput,
        result: recomputedHorizontal,
        label: 'recomputed',
      ))
      ..writeln('\n--- HORIZONTAL validation ---');
    final issues = validateHorizontalReconciles(
      input: horizontalInput,
      result: recomputedHorizontal,
    );
    if (issues.isEmpty) {
      buffer.writeln('OK');
    } else {
      for (final issue in issues) {
        buffer.writeln('ISSUE: ${issue.message}');
      }
    }

    // ignore: avoid_print
    print(buffer.toString());

    expect(recomputedVertical.solution, vOut['solution']);
    expect(recomputedHorizontal.solution, hOut['solution']);
    expect(recomputedHorizontal.marks, hOut['marks']);
  });
}