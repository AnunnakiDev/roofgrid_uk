import 'dart:math';
import '../../../models/calculator/horizontal_calculation_input.dart';
import '../../../models/calculator/horizontal_calculation_result.dart';

/// Calculates the horizontal spacing for roof tiles based on input measurements
/// and tile specifications.
class HorizontalCalculationService {
  /// Performs the horizontal tile spacing calculation
  static HorizontalCalculationResult calculateHorizontal(
      HorizontalCalculationInput inputs) {
    // Validate inputs
    if (inputs.widths.isEmpty || inputs.widths.any((w) => w < 500)) {
      throw Exception(
          'Width values must be at least 500mm to calculate a valid horizontal solution.');
    }

    // Step 1: Initialize
    int overhangLeft = inputs.useDryVerge == 'YES' ? 40 : 50;
    int overhangRight = inputs.useDryVerge == 'YES' ? 40 : 50;
    final int minOverhang = inputs.useDryVerge == 'YES' ? 20 : 25;
    final int maxOverhang = inputs.useDryVerge == 'YES' ? 40 : 75;

    int widthReduction = 0;
    var useDryVerge = inputs.useDryVerge;
    var useLHTile = inputs.useLHTile;

    if (inputs.abutmentSide == 'LEFT') {
      overhangLeft = 0;
      widthReduction = 5;
    } else if (inputs.abutmentSide == 'RIGHT') {
      overhangRight = 0;
      widthReduction = 5;
    } else if (inputs.abutmentSide == 'BOTH') {
      overhangLeft = 0;
      overhangRight = 0;
      widthReduction = 10;
    }

    if (inputs.abutmentSide != 'NONE') {
      useDryVerge = 'NO';
      useLHTile = 'NO';
    }

    final int setSize = inputs.tileCoverWidth > 300 ? 2 : 3;

    // Step 2: Calculate desired total width
    final List<int> desiredTotalWidths = inputs.widths
        .map((width) =>
            (width + overhangLeft + overhangRight - widthReduction).round())
        .toList();
    final int maxDesiredTotalWidth = desiredTotalWidths.reduce(max);

    // Step 3: Adjust for LH tile
    final int remainingWidth = useLHTile == 'YES'
        ? maxDesiredTotalWidth - inputs.lhTileWidth.round()
        : maxDesiredTotalWidth;

    // Step 4: Find min and max tile counts
    final double maxCoverWidth = inputs.tileCoverWidth + inputs.maxSpacing;
    final double minCoverWidth = inputs.tileCoverWidth + inputs.minSpacing;

    int minTileCount = (remainingWidth / maxCoverWidth).floor();
    int maxTileCount = (remainingWidth / minCoverWidth).floor();

    if (useLHTile == 'YES') {
      minTileCount += 1;
      maxTileCount += 1;
    }

    // Step 5: Test each tile count for full tiles
    dynamic solution;
    int tilesWide = 0;

    for (int tileCount = minTileCount; tileCount <= maxTileCount; tileCount++) {
      tilesWide = tileCount;
      final int regularTiles = tilesWide - (useLHTile == 'YES' ? 1 : 0);

      if (regularTiles <= 0) continue;

      final double actualCoverWidth = remainingWidth / regularTiles;
      final int roundedCoverWidth = actualCoverWidth.floor();
      final int actualSpacing =
          (roundedCoverWidth - inputs.tileCoverWidth).round();

      if (actualSpacing < inputs.minSpacing ||
          actualSpacing > inputs.maxSpacing) {
        continue;
      }

      final int tiledWidth = regularTiles * roundedCoverWidth +
          (useLHTile == 'YES' ? inputs.lhTileWidth.round() : 0);

      final List<Map<String, dynamic>> widthResults = [];
      bool validResult = true;

      for (int index = 0; index < desiredTotalWidths.length; index++) {
        final int desiredTotalWidth = desiredTotalWidths[index];
        final int remainingWidth = desiredTotalWidth - tiledWidth;
        final int overhangAdjustment = (remainingWidth / 2).round();

        int newOverhangLeft = overhangLeft - overhangAdjustment;
        int newOverhangRight = overhangRight - overhangAdjustment;

        newOverhangLeft = min(max(newOverhangLeft, minOverhang), maxOverhang);
        newOverhangRight = min(max(newOverhangRight, minOverhang), maxOverhang);

        // Respect abutment sides by enforcing 0 overhang
        if (inputs.abutmentSide == 'LEFT' || inputs.abutmentSide == 'BOTH') {
          newOverhangLeft = 0;
        }
        if (inputs.abutmentSide == 'RIGHT' || inputs.abutmentSide == 'BOTH') {
          newOverhangRight = 0;
        }

        if ((inputs.abutmentSide != 'LEFT' &&
                inputs.abutmentSide != 'BOTH' &&
                (newOverhangLeft < minOverhang ||
                    newOverhangLeft > maxOverhang)) ||
            (inputs.abutmentSide != 'RIGHT' &&
                inputs.abutmentSide != 'BOTH' &&
                (newOverhangRight < minOverhang ||
                    newOverhangRight > maxOverhang))) {
          validResult = false;
          break;
        }

        final int firstMark = (inputs.lhTileWidth +
                (inputs.tileCoverWidth + actualSpacing) * (setSize - 1) -
                (overhangLeft - newOverhangLeft))
            .round();
        final int? secondMark = inputs.crossBonded == 'YES'
            ? (firstMark + ((inputs.tileCoverWidth + actualSpacing) / 2))
                .round()
            : null;

        final int totalSets =
            tilesWide > 1 ? ((tilesWide - 1) / setSize).floor() : 0;
        final int baseIncrementMarks =
            (setSize * (inputs.tileCoverWidth + actualSpacing)).round();
        final int minMarks =
            (setSize * (inputs.tileCoverWidth + inputs.minSpacing)).round();
        final int maxMarks =
            (setSize * (inputs.tileCoverWidth + inputs.maxSpacing)).round();

        final int adjustedMarks =
            min(max(baseIncrementMarks, minMarks), maxMarks);

        widthResults.add({
          'totalWidth': desiredTotalWidth,
          'overhangLeft': newOverhangLeft,
          'overhangRight': newOverhangRight,
          'firstMark': firstMark,
          'secondMark': secondMark,
          'totalSets': totalSets,
          'adjustedMarks': adjustedMarks,
          'actualSpacing': actualSpacing,
        });
      }

      if (!validResult) {
        continue;
      }

      solution = {'type': 'full', 'widthResults': widthResults};
      break;
    }

    // Step 6: Split Sets (if full tiles fail)
    if (solution == null) {
      for (int n1 = 1; n1 <= tilesWide - 2; n1++) {
        final int n2 = (tilesWide - 1) - n1;
        if (n2 <= 0) continue;

        final List<Map<String, dynamic>> widthResultsSplit = [];
        bool validResult = true;

        for (int index = 0; index < desiredTotalWidths.length; index++) {
          final int desiredTotalWidth = desiredTotalWidths[index];

          int spacing1 = inputs.maxSpacing.round();
          double spacing2 = (desiredTotalWidth -
                  ((tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
                          inputs.tileCoverWidth +
                      (useLHTile == 'YES' ? inputs.lhTileWidth : 0) +
                      n1 * spacing1)) /
              n2;

          spacing2 = min(max(spacing2, inputs.minSpacing), inputs.maxSpacing);
          int roundedSpacing2 = spacing2.round();

          if (roundedSpacing2 < (inputs.minSpacing + inputs.maxSpacing) / 2) {
            final double totalSpacing = (desiredTotalWidth -
                    ((tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
                            inputs.tileCoverWidth +
                        (useLHTile == 'YES' ? inputs.lhTileWidth : 0))) /
                (tilesWide - 1);

            spacing1 =
                min(max(totalSpacing, inputs.minSpacing), inputs.maxSpacing)
                    .round();
            roundedSpacing2 = spacing1;
          }

          final int tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
                  inputs.tileCoverWidth.round() +
              (useLHTile == 'YES' ? inputs.lhTileWidth.round() : 0) +
              n1 * spacing1 +
              n2 * roundedSpacing2;

          int newOverhangLeft = overhangLeft;
          int newOverhangRight = overhangRight;

          final int remainingWidth = desiredTotalWidth - tiledWidth;
          final int overhangAdjustment = (remainingWidth / 2).round();

          newOverhangLeft -= overhangAdjustment;
          newOverhangRight -= overhangAdjustment;

          newOverhangLeft = min(max(newOverhangLeft, minOverhang), maxOverhang);
          newOverhangRight =
              min(max(newOverhangRight, minOverhang), maxOverhang);

          // Respect abutment sides by enforcing 0 overhang
          if (inputs.abutmentSide == 'LEFT' || inputs.abutmentSide == 'BOTH') {
            newOverhangLeft = 0;
          }
          if (inputs.abutmentSide == 'RIGHT' || inputs.abutmentSide == 'BOTH') {
            newOverhangRight = 0;
          }

          if ((inputs.abutmentSide != 'LEFT' &&
                  inputs.abutmentSide != 'BOTH' &&
                  (newOverhangLeft < minOverhang ||
                      newOverhangLeft > maxOverhang)) ||
              (inputs.abutmentSide != 'RIGHT' &&
                  inputs.abutmentSide != 'BOTH' &&
                  (newOverhangRight < minOverhang ||
                      newOverhangRight > maxOverhang))) {
            validResult = false;
            break;
          }

          final int firstMark = (inputs.lhTileWidth +
                  (inputs.tileCoverWidth + spacing1) * (setSize - 1) -
                  (overhangLeft - newOverhangLeft))
              .round();
          final int? secondMark = inputs.crossBonded == 'YES'
              ? (firstMark + ((inputs.tileCoverWidth + spacing1) / 2)).round()
              : null;

          final int sets1 = (n1 / setSize).floor();
          final int sets2 = (n2 / setSize).floor();

          final int baseIncrementMarks1 =
              (setSize * (inputs.tileCoverWidth + spacing1)).round();
          final int baseIncrementMarks2 =
              (setSize * (inputs.tileCoverWidth + roundedSpacing2)).round();
          final int minMarks =
              (setSize * (inputs.tileCoverWidth + inputs.minSpacing)).round();
          final int maxMarks =
              (setSize * (inputs.tileCoverWidth + inputs.maxSpacing)).round();

          final int adjustedMarks1 =
              min(max(baseIncrementMarks1, minMarks), maxMarks);
          final int adjustedMarks2 =
              min(max(baseIncrementMarks2, minMarks), maxMarks);

          widthResultsSplit.add({
            'totalWidth': desiredTotalWidth,
            'overhangLeft': newOverhangLeft,
            'overhangRight': newOverhangRight,
            'firstMark': firstMark,
            'secondMark': secondMark,
            'sets1': sets1,
            'sets2': sets2,
            'adjustedMarks1': adjustedMarks1,
            'adjustedMarks2': adjustedMarks2,
            'spacing1': spacing1,
            'spacing2': roundedSpacing2,
          });
        }

        if (!validResult) {
          continue;
        }

        solution = {'type': 'split', 'widthResults': widthResultsSplit};
        break;
      }
    }

    // Step 7: Cut Tile (if split sets fail)
    if (solution == null) {
      final int maxTotalWidth = desiredTotalWidths.reduce(max);
      int actualSpacing = inputs.maxSpacing.round();

      int tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
              inputs.tileCoverWidth.round() +
          (useLHTile == 'YES' ? inputs.lhTileWidth.round() : 0) +
          (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);

      if (tiledWidth > maxTotalWidth) {
        final int excessWidth = tiledWidth - maxTotalWidth;
        final double spacingReduction =
            excessWidth / (tilesWide > 1 ? tilesWide - 1 : 1);

        actualSpacing = (inputs.maxSpacing - spacingReduction).round();
        actualSpacing = max(actualSpacing, inputs.minSpacing.round());

        tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
                inputs.tileCoverWidth.round() +
            (useLHTile == 'YES' ? inputs.lhTileWidth.round() : 0) +
            (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);
      }

      int cutTileWidth = (maxTotalWidth -
              (tilesWide > 1
                  ? (tilesWide - 1) *
                      (inputs.tileCoverWidth.round() + actualSpacing)
                  : 0) -
              (useLHTile == 'YES'
                  ? inputs.lhTileWidth.round()
                  : inputs.tileCoverWidth.round()))
          .round();

      if (cutTileWidth < inputs.tileCoverWidth / 2 && cutTileWidth < 100) {
        final int targetCutWidth = max(inputs.tileCoverWidth / 2, 100).round();
        final int targetTiledWidth = maxTotalWidth - targetCutWidth;

        final double totalSpacing = (targetTiledWidth -
                ((tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
                        inputs.tileCoverWidth.round() +
                    (useLHTile == 'YES' ? inputs.lhTileWidth.round() : 0))) /
            (tilesWide > 1 ? tilesWide - 1 : 1);

        actualSpacing =
            min(max(totalSpacing, inputs.minSpacing), inputs.maxSpacing)
                .round();

        tiledWidth = (tilesWide - (useLHTile == 'YES' ? 1 : 0)) *
                inputs.tileCoverWidth.round() +
            (useLHTile == 'YES' ? inputs.lhTileWidth.round() : 0) +
            (tilesWide > 1 ? (tilesWide - 1) * actualSpacing : 0);

        cutTileWidth = maxTotalWidth - tiledWidth;
      }

      final List<Map<String, dynamic>> widthResultsCut = [];

      for (int index = 0; index < desiredTotalWidths.length; index++) {
        final int desiredTotalWidth = desiredTotalWidths[index];

        final int tiledWidth = (tilesWide > 1
                ? (tilesWide - 1) *
                    (inputs.tileCoverWidth.round() + actualSpacing)
                : 0) +
            (useLHTile == 'YES'
                ? inputs.lhTileWidth.round()
                : inputs.tileCoverWidth.round()) +
            cutTileWidth;

        final int remainingWidth = desiredTotalWidth - tiledWidth;

        int newOverhangLeft = overhangLeft;
        int newOverhangRight = overhangRight;

        final int overhangAdjustment = (remainingWidth / 2).round();

        newOverhangLeft -= overhangAdjustment;
        newOverhangRight -= overhangAdjustment;

        newOverhangLeft = min(max(newOverhangLeft, minOverhang), maxOverhang);
        newOverhangRight = min(max(newOverhangRight, minOverhang), maxOverhang);

        // Respect abutment sides by enforcing 0 overhang
        if (inputs.abutmentSide == 'LEFT' || inputs.abutmentSide == 'BOTH') {
          newOverhangLeft = 0;
        }
        if (inputs.abutmentSide == 'RIGHT' || inputs.abutmentSide == 'BOTH') {
          newOverhangRight = 0;
        }

        final int firstMark = (inputs.lhTileWidth +
                (inputs.tileCoverWidth + actualSpacing) * (setSize - 1) -
                (overhangLeft - newOverhangLeft))
            .round();
        final int? secondMark = inputs.crossBonded == 'YES'
            ? (firstMark + ((inputs.tileCoverWidth + actualSpacing) / 2))
                .round()
            : null;

        final int totalSets =
            tilesWide > 1 ? ((tilesWide - 1) / setSize).floor() : 0;
        final int baseIncrementMarks =
            (setSize * (inputs.tileCoverWidth + actualSpacing)).round();
        final int minMarks =
            (setSize * (inputs.tileCoverWidth + inputs.minSpacing)).round();
        final int maxMarks =
            (setSize * (inputs.tileCoverWidth + inputs.maxSpacing)).round();

        final int adjustedMarks =
            min(max(baseIncrementMarks, minMarks), maxMarks);

        widthResultsCut.add({
          'totalWidth': desiredTotalWidth,
          'overhangLeft': newOverhangLeft,
          'overhangRight': newOverhangRight,
          'firstMark': firstMark,
          'secondMark': secondMark,
          'totalSets': totalSets,
          'adjustedMarks': adjustedMarks,
          'actualSpacing': actualSpacing,
          'cutTileWidth': cutTileWidth,
        });
      }

      solution = {'type': 'cut', 'widthResults': widthResultsCut};
    }

    // Step 8: Verify solution exists
    if (solution == null) {
      throw Exception(
          'Unable to compute a horizontal solution. Please check your inputs: ensure widths are valid and tile specifications (tile cover width, min/max spacing) are appropriate.');
    }

    // Create result object
    final result = solution['widthResults'][0];
    final solutionType = solution['type'];

    return HorizontalCalculationResult(
      width: inputs.widths[0].round(),
      solution: solutionType == 'full'
          ? 'Even Sets'
          : solutionType == 'split'
              ? 'Split Sets'
              : 'Cut Course',
      newWidth: result['totalWidth'] as int,
      lhOverhang: inputs.useDryVerge == 'NO' && inputs.abutmentSide == 'NONE'
          ? result['overhangLeft'] as int
          : null,
      rhOverhang: inputs.useDryVerge == 'NO' && inputs.abutmentSide == 'NONE'
          ? result['overhangRight'] as int
          : null,
      cutTile: solutionType == 'cut' ? result['cutTileWidth'] as int : null,
      firstMark: result['firstMark'] as int,
      secondMark:
          inputs.crossBonded == 'YES' ? result['secondMark'] as int : null,
      marks: solutionType == 'split'
          ? '${result['sets2']} sets of $setSize @ ${result['adjustedMarks2']}'
          : '${result['totalSets']} sets of $setSize @ ${result['adjustedMarks']}',
      splitMarks: solutionType == 'split'
          ? '${result['sets1']} sets of $setSize @ ${result['adjustedMarks1']}'
          : null,
    );
  }
}
