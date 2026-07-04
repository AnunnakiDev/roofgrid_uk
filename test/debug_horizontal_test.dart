// Run with:
//   flutter test test/debug_horizontal_test.dart --plain-name "debug"
//
// Do NOT use `dart run` — this project imports Flutter/Firestore transitively.
@Tags(['debug'])
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';

import 'support/golden_job_fixtures.dart';
import 'support/horizontal_debug_dump.dart';

HorizontalCalculationInput _plainInput({
  List<double> widths = const [6000],
  String useDryVerge = 'NO',
}) {
  return HorizontalCalculationInput(
    widths: widths,
    tileCoverWidth: 165,
    minSpacing: 1,
    maxSpacing: 7,
    useDryVerge: useDryVerge,
    abutmentSide: 'NONE',
    useLHTile: 'NO',
    lhTileWidth: 165,
    crossBonded: 'YES',
    materialType: 'Plain Tile',
  );
}

void main() {
  test('debug plain tile 6000 wet verge', () {
    // ignore: avoid_print
    print(dumpHorizontalCalculation(
      input: _plainInput(),
      label: 'plain tile 6000 wet verge',
    ));
  });

  test('debug plain tile 6000 dry verge', () {
    // ignore: avoid_print
    print(dumpHorizontalCalculation(
      input: _plainInput(useDryVerge: 'YES'),
      label: 'plain tile 6000 dry verge',
    ));
  });

  test('debug golden fixtures', () {
    for (final fixture in kGoldenJobFixtures) {
      final input = HorizontalCalculationInput(
        widths: [kGoldenRoofWidthMm],
        tileCoverWidth: fixture.tileCoverWidth,
        minSpacing: fixture.minSpacing,
        maxSpacing: fixture.maxSpacing,
        lhTileWidth: fixture.tileCoverWidth,
        useDryVerge: 'NO',
        abutmentSide: 'NONE',
        useLHTile: 'NO',
        crossBonded: fixture.defaultCrossBonded ? 'YES' : 'NO',
        materialType: fixture.materialType,
      );
      // ignore: avoid_print
      print(dumpHorizontalCalculation(
        input: input,
        label: 'golden ${fixture.id}',
      ));
    }
  });
}