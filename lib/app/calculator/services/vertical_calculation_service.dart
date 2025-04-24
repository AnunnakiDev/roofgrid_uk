import 'dart:math';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';

/// Calculates the vertical batten gauge for roof tiles based on input measurements
/// and tile specifications.
class VerticalCalculationService {
  /// Performs the vertical batten gauge calculation
  static Future<VerticalCalculationResult> calculateVertical({
    required VerticalCalculationInput input,
    required String materialType,
    required double slateTileHeight,
    required double maxGauge,
    required double minGauge,
  }) async {
    // Step 1: Validate inputs
    if (input.rafterHeights.isEmpty ||
        input.rafterHeights.any((h) => h < 500)) {
      return VerticalCalculationResult(
        inputRafter:
            input.rafterHeights.isNotEmpty ? input.rafterHeights[0].round() : 0,
        solution: 'Invalid',
        totalCourses: 0,
        firstBatten: 0,
        ridgeOffset: 0, // Provide default value
        gauge: 'N/A',
        warning:
            'Rafter height values must be at least 500mm to calculate a valid vertical solution.',
      );
    }

    // Step 2: Initialize constants based on material type
    final int maxCourses = materialType == 'Fibre Cement Slate' ? 2 : 3;
    final int underBatten = materialType == 'Fibre Cement Slate' ? 75 : 38;
    final int eaveAdjustment = materialType == 'Fibre Cement Slate' ? 50 : 0;

    // Step 3: Calculate initial measurements
    final int maxInputRafter =
        input.rafterHeights.reduce(max).round(); // Convert double to int
    int remainingLength = (maxInputRafter - input.gutterOverhang).round();
    int ridgeOffset = input.useDryRidge == 'YES' ? 61 : 71;
    remainingLength -= ridgeOffset;

    if (remainingLength < 500) {
      return VerticalCalculationResult(
        inputRafter: maxInputRafter,
        solution: 'Invalid',
        totalCourses: 0,
        firstBatten: 0,
        ridgeOffset: 0, // Provide default value
        gauge: 'N/A',
        warning:
            'Remaining length after gutter overhang and ridge offset must be at least 500mm.',
      );
    }

    // Step 4: Compute eave batten and first batten
    int eaveBatten = (slateTileHeight / 2 + eaveAdjustment).round();
    remainingLength -= eaveBatten;
    int firstBatten = (eaveBatten + underBatten).round();

    // Step 5: Find min and max courses
    int minCourses = (remainingLength / maxGauge).floor();
    int maxCoursesPossible = (remainingLength / minGauge).floor();

    if (materialType == 'Fibre Cement Slate') {
      minCourses = max(minCourses, 2);
      maxCoursesPossible = max(maxCoursesPossible, 2);
    }

    // Step 6: Test each course count for full courses
    dynamic solution;
    int courses = 0;

    for (int courseCount = minCourses;
        courseCount <= maxCoursesPossible;
        courseCount++) {
      courses = courseCount + 1; // Include the eave course
      final int battens = courses - 1;
      if (battens <= 0) continue;

      final double actualGauge = remainingLength / battens;
      final int roundedGauge = actualGauge.floor();

      if (roundedGauge < minGauge || roundedGauge > maxGauge) {
        continue;
      }

      final List<Map<String, dynamic>> rafterResults = [];
      bool validResult = true;

      for (int index = 0; index < input.rafterHeights.length; index++) {
        final int rafterHeight = input.rafterHeights[index].round();
        int adjustedRemainingLength =
            (rafterHeight - input.gutterOverhang - ridgeOffset).round();
        adjustedRemainingLength -= eaveBatten;

        final int tiledHeight = battens * roundedGauge;
        final int remainingHeight = adjustedRemainingLength - tiledHeight;
        int adjustedRidgeOffset = ridgeOffset + remainingHeight;

        if (adjustedRidgeOffset < 0) {
          validResult = false;
          break;
        }

        rafterResults.add({
          'rafterHeight': rafterHeight,
          'ridgeOffset': adjustedRidgeOffset,
          'gauge': roundedGauge,
        });
      }

      if (!validResult) {
        continue;
      }

      solution = {'type': 'full', 'rafterResults': rafterResults};
      break;
    }

    // Step 7: Split courses (if full courses fail)
    if (solution == null) {
      for (int n1 = 1; n1 <= courses - 2; n1++) {
        final int n2 = (courses - 1) - n1;
        if (n2 <= 0) continue;

        final List<Map<String, dynamic>> rafterResultsSplit = [];
        bool validResult = true;

        for (int index = 0; index < input.rafterHeights.length; index++) {
          final int rafterHeight = input.rafterHeights[index].round();
          int adjustedRemainingLength =
              (rafterHeight - input.gutterOverhang - ridgeOffset).round();
          adjustedRemainingLength -= eaveBatten;

          int gauge1 = maxGauge.round();
          double gauge2 = (adjustedRemainingLength - n1 * gauge1) / n2;

          gauge2 = min(max(gauge2, minGauge), maxGauge);
          int roundedGauge2 = gauge2.round();

          if (roundedGauge2 < (minGauge + maxGauge) / 2) {
            final double totalGauge = adjustedRemainingLength / (courses - 1);
            gauge1 = min(max(totalGauge, minGauge), maxGauge).round();
            roundedGauge2 = gauge1;
          }

          final int tiledHeight = n1 * gauge1 + n2 * roundedGauge2;
          final int remainingHeight = adjustedRemainingLength - tiledHeight;
          int adjustedRidgeOffset = ridgeOffset + remainingHeight;

          if (adjustedRidgeOffset < 0) {
            validResult = false;
            break;
          }

          rafterResultsSplit.add({
            'rafterHeight': rafterHeight,
            'ridgeOffset': adjustedRidgeOffset,
            'gauge1': gauge1,
            'gauge2': roundedGauge2,
            'courses1': n1,
            'courses2': n2,
          });
        }

        if (!validResult) {
          continue;
        }

        solution = {'type': 'split', 'rafterResults': rafterResultsSplit};
        break;
      }
    }

    // Step 8: Cut course (if split courses fail)
    if (solution == null) {
      final int maxRafterHeight =
          input.rafterHeights.reduce(max).round(); // Convert double to int
      int adjustedRemainingLength =
          (maxRafterHeight - input.gutterOverhang - ridgeOffset).round();
      adjustedRemainingLength -= eaveBatten;

      int actualGauge = maxGauge.round();
      int tiledHeight = (courses - 1) * actualGauge;

      if (tiledHeight > adjustedRemainingLength) {
        final int excessHeight = tiledHeight - adjustedRemainingLength;
        final double gaugeReduction = excessHeight / (courses - 1);
        actualGauge = (maxGauge - gaugeReduction).round();
        actualGauge = max(actualGauge, minGauge.round());
      }

      int cutCourse =
          (adjustedRemainingLength - (courses - 2) * actualGauge).round();

      if (cutCourse < slateTileHeight / 2 && cutCourse < 100) {
        final int targetCutHeight = max(slateTileHeight / 2, 100).round();
        final int targetTiledHeight = adjustedRemainingLength - targetCutHeight;

        final double totalGauge =
            targetTiledHeight / (courses > 1 ? courses - 2 : 1);
        actualGauge = min(max(totalGauge, minGauge), maxGauge).round();

        cutCourse = adjustedRemainingLength - (courses - 2) * actualGauge;
      }

      final List<Map<String, dynamic>> rafterResultsCut = [];

      for (int index = 0; index < input.rafterHeights.length; index++) {
        final int rafterHeight = input.rafterHeights[index].round();
        adjustedRemainingLength =
            (rafterHeight - input.gutterOverhang - ridgeOffset).round();
        adjustedRemainingLength -= eaveBatten;

        final int adjustedTiledHeight = (courses - 2) * actualGauge + cutCourse;
        final int remainingHeight =
            adjustedRemainingLength - adjustedTiledHeight;
        int adjustedRidgeOffset = ridgeOffset + remainingHeight;

        rafterResultsCut.add({
          'rafterHeight': rafterHeight,
          'ridgeOffset': adjustedRidgeOffset,
          'gauge': actualGauge,
          'cutCourse': cutCourse,
        });
      }

      solution = {'type': 'cut', 'rafterResults': rafterResultsCut};
    }

    // Step 9: Verify solution exists
    if (solution == null) {
      return VerticalCalculationResult(
        inputRafter: maxInputRafter,
        solution: 'Invalid',
        totalCourses: 0,
        firstBatten: 0,
        ridgeOffset: 0, // Provide default value
        gauge: 'N/A',
        warning:
            'Unable to find a solution. Please check your inputs: ensure rafter heights are valid and tile specifications (max/min gauge) are appropriate.',
      );
    }

    // Create result object
    final result = solution['rafterResults'][0];
    final solutionType = solution['type'];

    return VerticalCalculationResult(
      inputRafter: maxInputRafter,
      solution: solutionType == 'full'
          ? 'Even Courses'
          : solutionType == 'split'
              ? 'Split Courses'
              : 'Cut Course',
      totalCourses: courses,
      eaveBatten: eaveBatten,
      firstBatten: firstBatten,
      ridgeOffset: result['ridgeOffset'] as int,
      cutCourse: solutionType == 'cut' ? result['cutCourse'] as int : null,
      gauge: solutionType == 'split'
          ? '${result['courses2']} @ ${result['gauge2']}'
          : '${courses - 1} @ ${result['gauge']}',
      splitGauge: solutionType == 'split'
          ? '${result['courses1']} @ ${result['gauge1']}'
          : null,
      warning: null,
    );
  }
}
