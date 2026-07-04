// One-off reader for emulator Hive dump. Run:
//   flutter test test/read_hive_saved_results_test.dart
@Tags(['debug'])
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';

const _hiveDumpPath = 'agent-tools/hive_dump/resultsbox_fresh.hive';
const _hiveBoxName = 'resultsBox';

void main() {
  setUpAll(() async {
    Hive
      ..init(Directory.systemTemp.path)
      ..registerAdapter(CalculationTypeAdapter())
      ..registerAdapter(SavedResultAdapter());
  });

  test('list saved results from emulator hive dump', () async {
    final source = File(_hiveDumpPath);
    expect(source.existsSync(), isTrue, reason: 'Pull resultsbox.hive first');

    final tempDir = Directory.systemTemp.createTempSync('roofgrid_hive_');
    final boxPath = '${tempDir.path}/resultsbox.hive';
    source.copySync(boxPath);

    final box = await Hive.openBox<SavedResult>(
      _hiveBoxName,
      path: tempDir.path,
    );
    final results = box.values.toList();
    // ignore: avoid_print
    print('Found ${results.length} saved result(s):');
    for (final result in results) {
      // ignore: avoid_print
      print('  - "${result.projectName}" (${result.type.name})');
    }

    final target = results.where(
      (r) => r.projectName.toLowerCase() == 'test save 3',
    );
    expect(target, isNotEmpty, reason: 'test save 3 not in hive dump');
    final saved = target.first;
    final normalized = normalizeSavedResult(saved);

    // ignore: avoid_print
    print('\n=== test save 3 ===');
    // ignore: avoid_print
    print(const JsonEncoder.withIndent('  ').convert({
      'id': normalized.id,
      'type': normalized.type.name,
      'tile': normalized.tile['name'] ?? normalized.tile['materialType'],
      'inputs': normalized.inputs,
      'outputs': normalized.outputs,
      'createdAt': normalized.createdAt.toIso8601String(),
      'updatedAt': normalized.updatedAt.toIso8601String(),
    }));

    await box.close();
    tempDir.deleteSync(recursive: true);
  });
}