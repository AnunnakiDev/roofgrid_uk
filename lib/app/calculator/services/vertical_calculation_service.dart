import 'dart:math';
import '../../../models/calculator/vertical_calculation_input.dart';
import '../../../models/calculator/vertical_calculation_result.dart';

/// Calculates the vertical gauge for roof battens based on input measurements
/// and material specifications.
class VerticalCalculationService {
  /// Performs the vertical batten calculation
  static VerticalCalculationResult calculateVertical({
    required VerticalCalculationInput input,
    required String materialType,
    required double slateTileHeight,
    required double maxGauge,
    required double minGauge,
  }) {
    // Validate inputs
    if (input.rafterHeights.isEmpty ||
        input.rafterHeights.any((h) => h < 500)) {
      throw Exception(
          'Rafter height values must be at least 500mm to calculate a valid vertical gauge solution.');
    }

    // Step 1: Initialize
    final int underEaveBatten = materialType == 'Fibre Cement Slate' ? 120 : 0;
    final int eaveBattenAdjustment = materialType == 'Plain Tile' ? 65 : 0;

    int firstBatten;
    if (materialType == 'Slate' || materialType == 'Fibre Cement Slate') {
      firstBatten = (slateTileHeight - input.gutterOverhang + 25).round();
    } else if (materialType == 'Plain Tile') {
      firstBatten = (slateTileHeight - input.gutterOverhang - 15).round();
    } else {
      firstBatten = (slateTileHeight - input.gutterOverhang - 25).round();
    }

    final int eaveBatten = materialType == 'Plain Tile'
        ? firstBatten - eaveBattenAdjustment
        : firstBatten - maxGauge.round();

    final int? underEaveBattenValue = materialType == 'Fibre Cement Slate'
        ? (eaveBatten - 120).round()
        : null;

    final int ridgeOffsetMin = input.useDryRidge == 'YES' ? 40 : 25;
    const int ridgeOffsetMax = 65;

    // Step 2: Calculate remaining length after first batten
    final List<double> remainingLengths = input.rafterHeights
        .map((rafterHeight) => rafterHeight - firstBatten - ridgeOffsetMin)
        .toList();

    // Step 3: Min/Max Courses
    final double maxRafterHeight = input.rafterHeights.reduce(max);
    final int minCourses =
        ((maxRafterHeight - firstBatten - ridgeOffsetMax) / maxGauge).ceil() +
            1;
    final int maxCourses =
        ((maxRafterHeight - firstBatten - ridgeOffsetMin) / minGauge).floor() +
            1;

    // Step 4: Full tiles with single gauge
    dynamic solution;
    String? warning;

    for (int n = minCourses; n <= maxCourses; n++) {
      final List<Map<String, dynamic>> rafterResults = [];

      for (final rafterHeight in input.rafterHeights) {
        final double battenGauge =
            (rafterHeight - firstBatten - ridgeOffsetMin) / (n - 1);
        final int roundedBattenGauge =
            min(max(battenGauge, minGauge), maxGauge).round();
        final int effectiveRidgeOffset =
            (rafterHeight - (firstBatten + (n - 1) * roundedBattenGauge))
                .round();

        rafterResults.add({
          'battenGauge': roundedBattenGauge,
          'effectiveRidgeOffset': effectiveRidgeOffset,
        });
      }

      bool isWithinRidgeOffset = rafterResults.every((r) =>
          (r['effectiveRidgeOffset'] as num) >= ridgeOffsetMin &&
          (r['effectiveRidgeOffset'] as num) <= ridgeOffsetMax);

      if (isWithinRidgeOffset) {
        solution = {
          'type': 'full',
          'n_spaces': n,
          'rafterResults': rafterResults
        };
        break;
      }

      // Try with max ridge offset
      final List<Map<String, dynamic>> rafterResultsMax = [];

      for (int i = 0; i < input.rafterHeights.length; i++) {
        final double battenGauge =
            (input.rafterHeights[i] - firstBatten - ridgeOffsetMax) / (n - 1);
        final int roundedBattenGauge =
            min(max(battenGauge, minGauge), maxGauge).round();
        final int effectiveRidgeOffset = (input.rafterHeights[i] -
                (firstBatten + (n - 1) * roundedBattenGauge))
            .round();

        rafterResultsMax.add({
          'battenGauge': roundedBattenGauge,
          'effectiveRidgeOffset': effectiveRidgeOffset,
        });
      }

      isWithinRidgeOffset = rafterResultsMax.every((r) =>
          (r['effectiveRidgeOffset'] as num) >= ridgeOffsetMin &&
          (r['effectiveRidgeOffset'] as num) <= ridgeOffsetMax);

      if (isWithinRidgeOffset) {
        solution = {
          'type': 'full',
          'n_spaces': n,
          'rafterResults': rafterResultsMax
        };
        break;
      }
    }

    // Step 5: Split gauges
    if (solution == null) {
      for (int n = minCourses; n <= maxCourses; n++) {
        for (int n1 = 1; n1 <= n - 2; n1++) {
          final int n2 = (n - 2) - n1;
          if (n2 <= 0) continue; // Ensure n2 is positive

          final double maxGauge1 =
              (maxRafterHeight - firstBatten - ridgeOffsetMin - maxGauge) / n1;
          final double maxGauge2 = (maxRafterHeight -
                  firstBatten -
                  ridgeOffsetMin -
                  n1 * maxGauge1) /
              n2;

          final int roundedMaxGauge1 =
              min(max(maxGauge1, minGauge), maxGauge).round();
          final int roundedMaxGauge2 =
              min(max(maxGauge2, minGauge), maxGauge).round();

          final List<Map<String, dynamic>> rafterResults = [];

          for (final rafterHeight in input.rafterHeights) {
            final double gauge1 =
                (rafterHeight - firstBatten - ridgeOffsetMin - maxGauge) / n1;
            final double gauge2 =
                (rafterHeight - firstBatten - ridgeOffsetMin - n1 * gauge1) /
                    n2;

            final int roundedGauge1 =
                min(max(gauge1, minGauge), maxGauge).round();
            final int roundedGauge2 =
                min(max(gauge2, minGauge), maxGauge).round();

            final double remainder = rafterHeight -
                firstBatten -
                ridgeOffsetMin -
                (n1 * roundedGauge1 + n2 * roundedGauge2);
            final int effectiveRidgeOffset =
                (ridgeOffsetMin + remainder).round();

            rafterResults.add({
              'gauge1': roundedGauge1,
              'gauge2': roundedGauge2,
              'effectiveRidgeOffset': effectiveRidgeOffset,
            });
          }

          bool isWithinRidgeOffset = rafterResults.every((r) =>
              (r['effectiveRidgeOffset'] as num) >= ridgeOffsetMin &&
              (r['effectiveRidgeOffset'] as num) <= ridgeOffsetMax);

          if (isWithinRidgeOffset) {
            solution = {
              'type': 'split',
              'n_spaces': n,
              'n1': n1,
              'n2': n2,
              'rafterResults': rafterResults
            };
            break;
          }
        }
        if (solution != null) break;
      }
    }

    // Step 6: Cut course
    if (solution == null) {
      final int fullCourses =
          ((maxRafterHeight - firstBatten - ridgeOffsetMin) / maxGauge).floor();
      final int nSpaces = fullCourses + 1;

      final List<Map<String, dynamic>> rafterResults = [];

      for (final rafterHeight in input.rafterHeights) {
        final double cutCourseGauge = rafterHeight -
            firstBatten -
            ridgeOffsetMin -
            fullCourses * maxGauge;
        final int roundedCutCourseGauge = cutCourseGauge.round();
        final int effectiveRidgeOffset = (rafterHeight -
                (firstBatten + roundedCutCourseGauge + fullCourses * maxGauge))
            .round();

        rafterResults.add({
          'cutCourseGauge': roundedCutCourseGauge,
          'fullCourses': fullCourses,
          'effectiveRidgeOffset': effectiveRidgeOffset,
        });
      }

      solution = {
        'type': 'cut',
        'n_spaces': nSpaces,
        'rafterResults': rafterResults
      };
    }

    // Step 7: Add warning for gauge constraints
    if (solution == null) {
      throw Exception(
          'Unable to compute a vertical solution. Please check your inputs: ensure rafter heights are valid and tile specifications (min/max gauge, slate height) are appropriate.');
    }

    bool hasInvalidGauge = false;

    for (final r in solution['rafterResults']) {
      if (solution['type'] == 'full' && (r['battenGauge'] as num) < minGauge) {
        hasInvalidGauge = true;
      } else if (solution['type'] == 'split' &&
          ((r['gauge1'] as num) < minGauge ||
              (r['gauge2'] as num) < minGauge)) {
        hasInvalidGauge = true;
      } else if (solution['type'] == 'cut' &&
          (r['cutCourseGauge'] as num) < 75) {
        hasInvalidGauge = true;
      }
    }

    if (hasInvalidGauge) {
      warning =
          'Batten gauge or cut course is below the minimum threshold (75mm) on one or more rafters. Consider adjusting rafter length or tile specifications.';
    }

    // Step 8: Verify totals
    const int tolerance = 3;
    List<String> totalWarnings = [];

    for (int index = 0; index < input.rafterHeights.length; index++) {
      final double rafterHeight = input.rafterHeights[index];
      final Map<String, dynamic> result = solution['rafterResults'][index];

      int computedTotal;

      if (solution['type'] == 'full') {
        computedTotal = firstBatten +
            ((solution['n_spaces'] as int) - 1) *
                (result['battenGauge'] as int) +
            (result['effectiveRidgeOffset'] as int);
      } else if (solution['type'] == 'split') {
        computedTotal = firstBatten +
            ((solution['n1'] as int) * (result['gauge1'] as int) +
                (solution['n2'] as int) * (result['gauge2'] as int) +
                (result['effectiveRidgeOffset'] as int));
      } else {
        computedTotal = firstBatten +
            (result['cutCourseGauge'] as int) +
            (result['fullCourses'] as int) * maxGauge.round() +
            (result['effectiveRidgeOffset'] as int);
      }

      final double difference = (rafterHeight - computedTotal).abs();

      if (difference > tolerance) {
        totalWarnings.add(
            'Computed total (${computedTotal}mm) for rafter ${index + 1} differs from rafter height (${rafterHeight.round()}mm) by ${difference.round()}mm, exceeding tolerance of ${tolerance}mm.');
      }
    }

    if (totalWarnings.isNotEmpty) {
      warning = warning != null
          ? '$warning ${totalWarnings.join(' ')}'
          : totalWarnings.join(' ');
    }

    // Create result object
    final result = solution['rafterResults'][0];

    String gauge;
    if (solution['type'] == 'cut') {
      gauge = '${result['fullCourses']} @ ${maxGauge.round()}';
    } else if (solution['type'] == 'full') {
      gauge = '${solution['n_spaces'] - 1} @ ${result['battenGauge'] as int}';
    } else {
      gauge = '${solution['n1']} @ ${result['gauge1'] as int}';
    }

    final String? splitGauge = solution['type'] == 'split'
        ? '${solution['n2']} @ ${result['gauge2'] as int}'
        : null;

    return VerticalCalculationResult(
      inputRafter: input.rafterHeights[0].round(),
      totalCourses: solution['n_spaces'] as int,
      solution: solution['type'] == 'full'
          ? 'Full Courses'
          : solution['type'] == 'split'
              ? 'Split Gauge'
              : 'Cut Course',
      ridgeOffset: result['effectiveRidgeOffset'] as int,
      underEaveBatten: underEaveBattenValue,
      eaveBatten:
          ['Slate', 'Fibre Cement Slate', 'Plain Tile'].contains(materialType)
              ? eaveBatten
              : null,
      firstBatten: firstBatten,
      cutCourse:
          solution['type'] == 'cut' ? result['cutCourseGauge'] as int : null,
      gauge: gauge,
      splitGauge: splitGauge,
      warning: warning,
    );
  }
}
