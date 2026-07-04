import 'dart:math';

import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/width_calculation_detail.dart';
import 'package:roofgrid_uk/utils/calculation_geometry.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';

const int kWetVergeTargetOverhangMm = 50;
const int kWetVergeMinOverhangMm = 25;
const int kWetVergeMaxOverhangMm = 75;
const int kDryVergeOverhangMm = 40;
const int kDryVergeMinOverhangMm = 20;
const int kDryVergeMaxOverhangMm = 40;

class InitialOverhangs {
  final int left;
  final int right;
  final int widthReduction;
  final int minOverhang;
  final int maxOverhang;

  const InitialOverhangs({
    required this.left,
    required this.right,
    required this.widthReduction,
    required this.minOverhang,
    required this.maxOverhang,
  });
}

InitialOverhangs resolveInitialOverhangs({
  required String useDryVerge,
  required String abutmentSide,
}) {
  final isDry = useDryVerge == 'YES';
  var left = isDry ? kDryVergeOverhangMm : kWetVergeTargetOverhangMm;
  var right = left;
  var widthReduction = 0;

  switch (abutmentSide) {
    case 'LEFT':
      left = 0;
      widthReduction = 5;
    case 'RIGHT':
      right = 0;
      widthReduction = 5;
    case 'BOTH':
      left = 0;
      right = 0;
      widthReduction = 10;
  }

  return InitialOverhangs(
    left: left,
    right: right,
    widthReduction: widthReduction,
    minOverhang: isDry ? kDryVergeMinOverhangMm : kWetVergeMinOverhangMm,
    maxOverhang: isDry ? kDryVergeMaxOverhangMm : kWetVergeMaxOverhangMm,
  );
}

int expectedDesignWidth({
  required int inputWidth,
  required InitialOverhangs overhangs,
}) {
  return inputWidth + overhangs.left + overhangs.right - overhangs.widthReduction;
}

int? adjustedWidthFromOverhangs({
  required int inputWidth,
  int? lhOverhang,
  int? rhOverhang,
}) {
  if (lhOverhang == null || rhOverhang == null) return null;
  return inputWidth + lhOverhang + rhOverhang;
}

int? adjustedWidthForDetail(WidthCalculationDetail detail) {
  return adjustedWidthFromOverhangs(
    inputWidth: detail.inputWidth,
    lhOverhang: detail.lhOverhang,
    rhOverhang: detail.rhOverhang,
  );
}

int? adjustedWidthFromResult(HorizontalCalculationResult result) {
  return adjustedWidthFromOverhangs(
    inputWidth: result.width,
    lhOverhang: result.lhOverhang,
    rhOverhang: result.rhOverhang,
  );
}

int? inferTilesWideFromMarks({
  required String marks,
  required int setSize,
  required int adjustedWidth,
  required double tileCoverWidth,
  required int spacing,
  required bool useLhTile,
  required int lhTileWidth,
}) {
  final parsed = parseSetsNotation(marks);
  if (parsed == null) return null;

  final unitWidth = tileCoverWidth.round() + spacing;
  final minTiles = parsed.setCount * parsed.tilesPerSet + 1;
  final maxTiles = (parsed.setCount + 1) * parsed.tilesPerSet;

  for (var tilesWide = minTiles; tilesWide <= maxTiles; tilesWide++) {
    final regularTiles = tilesWide - (useLhTile ? 1 : 0);
    if (regularTiles <= 0) continue;

    final tiledWidth = regularTiles * unitWidth +
        (useLhTile ? lhTileWidth : 0);
    if (tiledWidth == adjustedWidth) return tilesWide;
  }
  return null;
}

int reconstructCutTiledRunLength({
  required int tilesWide,
  required HorizontalCalculationInput input,
  required int spacing,
  required int cutTileWidth,
}) {
  return (tilesWide > 1
          ? (tilesWide - 1) * (input.tileCoverWidth.round() + spacing)
          : 0) +
      (input.useLHTile == 'YES'
          ? input.lhTileWidth.round()
          : input.tileCoverWidth.round()) +
      cutTileWidth;
}

int reconstructTiledRunLength({
  required HorizontalCalculationResult result,
  required HorizontalCalculationInput input,
  required int setSize,
  int? adjustedWidth,
}) {
  final spacing = result.actualSpacing;
  if (spacing == null) return 0;

  final width = adjustedWidth ??
      adjustedWidthFromResult(result) ??
      result.width;

  if (result.solution == 'Cut Tile' && result.cutTile != null) {
    final tilesWide = inferTilesWideFromMarks(
      marks: result.marks,
      setSize: setSize,
      adjustedWidth: width,
      tileCoverWidth: input.tileCoverWidth,
      spacing: spacing,
      useLhTile: input.useLHTile == 'YES',
      lhTileWidth: input.lhTileWidth.round(),
    );
    if (tilesWide == null) return 0;
    return reconstructCutTiledRunLength(
      tilesWide: tilesWide,
      input: input,
      spacing: spacing,
      cutTileWidth: result.cutTile!,
    );
  }

  if (result.solution != 'Even Sets') {
    return 0;
  }

  final tilesWide = inferTilesWideFromMarks(
    marks: result.marks,
    setSize: setSize,
    adjustedWidth: width,
    tileCoverWidth: input.tileCoverWidth,
    spacing: spacing,
    useLhTile: input.useLHTile == 'YES',
    lhTileWidth: input.lhTileWidth.round(),
  );
  if (tilesWide == null) return 0;

  final regularTiles = tilesWide - (input.useLHTile == 'YES' ? 1 : 0);
  return regularTiles * (input.tileCoverWidth.round() + spacing) +
      (input.useLHTile == 'YES' ? input.lhTileWidth.round() : 0);
}

int expectedMarksIncrement({
  required int setSize,
  required double tileCoverWidth,
  required int spacing,
  required double minSpacing,
  required double maxSpacing,
}) {
  final base = (setSize * (tileCoverWidth + spacing)).round();
  final minMarks = (setSize * (tileCoverWidth + minSpacing)).round();
  final maxMarks = (setSize * (tileCoverWidth + maxSpacing)).round();
  return min(max(base, minMarks), maxMarks);
}

int expectedFirstMark({
  required HorizontalCalculationInput input,
  required int setSize,
  required int spacing,
  required int lhOverhang,
  required InitialOverhangs overhangs,
}) {
  return (input.lhTileWidth +
          (input.tileCoverWidth + spacing) * (setSize - 1) -
          (overhangs.left - lhOverhang))
      .round();
}

int? expectedSecondMark({
  required bool crossBonded,
  required int firstMark,
  required double tileCoverWidth,
  required int spacing,
}) {
  if (!crossBonded) return null;
  return (firstMark + ((tileCoverWidth + spacing) / 2)).round();
}

class HorizontalValidationIssue {
  final String message;

  const HorizontalValidationIssue(this.message);
}

List<HorizontalValidationIssue> validateHorizontalReconciles({
  required HorizontalCalculationInput input,
  required HorizontalCalculationResult result,
  int toleranceMm = 2,
}) {
  if (result.solution == 'Invalid') {
    return const [];
  }

  final issues = <HorizontalValidationIssue>[];
  final overhangs = resolveInitialOverhangs(
    useDryVerge: input.useDryVerge,
    abutmentSide: input.abutmentSide,
  );
  final setSize = resolveHorizontalSetSize(
    materialType: input.materialType,
    tileCoverWidth: input.tileCoverWidth,
  );
  final spacing = result.actualSpacing;
  final details = result.widthDetails;
  final rows = details != null && details.isNotEmpty
      ? details
      : [
          WidthCalculationDetail(
            inputWidth: result.width,
            totalWidth: result.newWidth,
            lhOverhang: result.lhOverhang,
            rhOverhang: result.rhOverhang,
            firstMark: result.firstMark,
            secondMark: result.secondMark,
            cutTile: result.cutTile,
            actualSpacing: spacing,
          ),
        ];

  if (spacing != null &&
      (spacing < input.minSpacing.round() || spacing > input.maxSpacing.round())) {
    issues.add(HorizontalValidationIssue(
      'Spacing $spacing outside ${input.minSpacing}-${input.maxSpacing} mm',
    ));
  }

  if (result.solution == 'Even Sets' && spacing != null) {
    final parsed = parseSetsNotation(result.marks);
    if (parsed != null) {
      final expectedIncrement = expectedMarksIncrement(
        setSize: setSize,
        tileCoverWidth: input.tileCoverWidth,
        spacing: spacing,
        minSpacing: input.minSpacing,
        maxSpacing: input.maxSpacing,
      );
      if (parsed.spacingMm != expectedIncrement) {
        issues.add(HorizontalValidationIssue(
          'Marks increment ${parsed.spacingMm} != expected $expectedIncrement',
        ));
      }
    }
  }

  final primaryInputWidth = input.widths.map((w) => w.round()).reduce(max);

  for (final detail in rows) {
    final designWidth = expectedDesignWidth(
      inputWidth: detail.inputWidth,
      overhangs: overhangs,
    );
    if (detail.totalWidth != designWidth) {
      issues.add(HorizontalValidationIssue(
        'Design width ${detail.totalWidth} != expected $designWidth '
        'for input ${detail.inputWidth}',
      ));
    }

    final adjusted = adjustedWidthForDetail(detail);
    if (adjusted != null) {
      if (detail.lhOverhang! < overhangs.minOverhang ||
          detail.lhOverhang! > overhangs.maxOverhang ||
          detail.rhOverhang! < overhangs.minOverhang ||
          detail.rhOverhang! > overhangs.maxOverhang) {
        issues.add(HorizontalValidationIssue(
          'Overhangs ${detail.lhOverhang}/${detail.rhOverhang} outside '
          '${overhangs.minOverhang}-${overhangs.maxOverhang} mm',
        ));
      }

      final tiledRun = reconstructTiledRunLength(
        result: result,
        input: input,
        setSize: setSize,
        adjustedWidth: adjusted,
      );
      final isPrimaryWidth = detail.inputWidth == primaryInputWidth;
      if (result.solution == 'Even Sets' &&
          isPrimaryWidth &&
          tiledRun > 0 &&
          (adjusted - tiledRun).abs() > toleranceMm) {
        issues.add(HorizontalValidationIssue(
          'Adjusted width $adjusted != tiled run $tiledRun '
          '(input ${detail.inputWidth})',
        ));
      }

      if (spacing != null && result.solution == 'Even Sets') {
        final expectedMark = expectedFirstMark(
          input: input,
          setSize: setSize,
          spacing: spacing,
          lhOverhang: detail.lhOverhang!,
          overhangs: overhangs,
        );
        if ((detail.firstMark - expectedMark).abs() > toleranceMm) {
          issues.add(HorizontalValidationIssue(
            'First mark ${detail.firstMark} != expected $expectedMark',
          ));
        }

        final expectedSecond = expectedSecondMark(
          crossBonded: input.crossBonded == 'YES',
          firstMark: detail.firstMark,
          tileCoverWidth: input.tileCoverWidth,
          spacing: spacing,
        );
        if (input.crossBonded == 'YES') {
          if (detail.secondMark == null) {
            issues.add(const HorizontalValidationIssue(
              'Missing second mark for cross-bonded tile',
            ));
          } else if (expectedSecond != null &&
              (detail.secondMark! - expectedSecond).abs() > toleranceMm) {
            issues.add(HorizontalValidationIssue(
              'Second mark ${detail.secondMark} != expected $expectedSecond',
            ));
          }
        } else if (detail.secondMark != null) {
          issues.add(const HorizontalValidationIssue(
            'Unexpected second mark for non cross-bonded tile',
          ));
        }
      }
    }
  }

  return issues;
}