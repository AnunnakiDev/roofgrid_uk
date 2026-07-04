import 'package:roofgrid_uk/app/calculator/services/horizontal_calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';

String dumpHorizontalCalculation({
  required HorizontalCalculationInput input,
  HorizontalCalculationResult? result,
  String label = 'horizontal',
}) {
  final computed =
      result ?? HorizontalCalculationService.calculateHorizontal(input);
  final setSize = resolveHorizontalSetSize(
    materialType: input.materialType,
    tileCoverWidth: input.tileCoverWidth,
  );
  final overhangs = resolveInitialOverhangs(
    useDryVerge: input.useDryVerge,
    abutmentSide: input.abutmentSide,
  );
  final adjusted = adjustedWidthFromResult(computed);
  final tiledRun = reconstructTiledRunLength(
    result: computed,
    input: input,
    setSize: setSize,
    adjustedWidth: adjusted,
  );
  final issues =
      validateHorizontalReconciles(input: input, result: computed);
  final hero = horizontalHeroRows(computed);

  final buffer = StringBuffer()
    ..writeln('=== $label ===')
    ..writeln('Material: ${input.materialType}')
    ..writeln('Input width(s): ${input.widths.map((w) => w.round()).join(', ')}')
    ..writeln('Tile cover: ${input.tileCoverWidth.round()} mm')
    ..writeln('Spacing range: ${input.minSpacing.round()}-${input.maxSpacing.round()} mm')
    ..writeln('Dry verge: ${input.useDryVerge}  Abutment: ${input.abutmentSide}')
    ..writeln('LH tile: ${input.useLHTile}  Cross bonded: ${input.crossBonded}')
    ..writeln('Set size: $setSize')
    ..writeln('Initial overhangs: LH ${overhangs.left} / RH ${overhangs.right}')
    ..writeln('--- result ---')
    ..writeln('Solution: ${computed.solution}')
    ..writeln('Design width (newWidth): ${computed.newWidth}')
    ..writeln('Adjusted width: $adjusted')
    ..writeln('LH verge: ${computed.lhOverhang}  RH verge: ${computed.rhOverhang}')
    ..writeln('Spacing: ${computed.actualSpacing}')
    ..writeln('Marks: ${computed.marks}')
    ..writeln('First mark: ${computed.firstMark}')
    ..writeln('Second mark: ${computed.secondMark}')
    ..writeln('Split marks: ${computed.splitMarks}')
    ..writeln('Cut tile: ${computed.cutTile}')
    ..writeln('Tiled run length: $tiledRun')
    ..writeln('Warning: ${computed.warning ?? 'none'}')
    ..writeln('--- hero rows ---');
  for (final row in hero) {
    buffer.writeln('  ${row.label}: ${row.value}');
  }
  if (computed.widthDetails != null && computed.widthDetails!.isNotEmpty) {
    buffer.writeln('--- width details ---');
    for (final detail in computed.widthDetails!) {
      buffer.writeln(
        '  input ${detail.inputWidth}: design ${detail.totalWidth}, '
        'adjusted ${adjustedWidthForDetail(detail)}, '
        'LH/RH ${detail.lhOverhang}/${detail.rhOverhang}, '
        'marks ${detail.firstMark}/${detail.secondMark}',
      );
    }
  }
  buffer.writeln('--- validation ---');
  if (issues.isEmpty) {
    buffer.writeln('  OK (no issues)');
  } else {
    for (final issue in issues) {
      buffer.writeln('  ISSUE: ${issue.message}');
    }
  }
  return buffer.toString();
}