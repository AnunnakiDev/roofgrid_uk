import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';
import 'golden_job_fixtures.dart';

bool isSingleSlopeRidgeOffsetInPlanningBounds(
  int ridgeOffsetMm, {
  String useDryRidge = 'NO',
}) {
  return isRidgeOffsetInBounds(ridgeOffsetMm, useDryRidge);
}

void expectValidVerticalGoldenResult({
  required VerticalCalculationResult result,
  required String materialType,
  required int expectedEaveBatten,
  required int? expectedUnderEaveBatten,
  required int expectedRidgeOffset,
  required bool assertRidgePlanningBounds,
}) {
  if (result.solution == 'Invalid') {
    throw StateError('Expected valid vertical solution');
  }

  expectBattenSequence(
    result: result,
    materialType: materialType,
    expectedEaveBatten: expectedEaveBatten,
    expectedUnderEaveBatten: expectedUnderEaveBatten,
  );

  if (result.ridgeOffset != expectedRidgeOffset) {
    throw StateError(
      'Ridge offset ${result.ridgeOffset} != expected $expectedRidgeOffset',
    );
  }

  if (assertRidgePlanningBounds &&
      !isSingleSlopeRidgeOffsetInPlanningBounds(
        result.ridgeOffset,
        useDryRidge: 'NO',
      )) {
    throw StateError(
      'Ridge offset ${result.ridgeOffset} outside '
      '$kRidgeOffsetMinMm–${ridgeOffsetMaxMm('NO')} mm wet-ridge bounds',
    );
  }
}

void expectBattenSequence({
  required VerticalCalculationResult result,
  required String materialType,
  required int expectedEaveBatten,
  required int? expectedUnderEaveBatten,
}) {
  if (result.eaveBatten != expectedEaveBatten) {
    throw StateError(
      'Eave batten ${result.eaveBatten} != expected $expectedEaveBatten',
    );
  }
  if (result.underEaveBatten != expectedUnderEaveBatten) {
    throw StateError(
      'Under-eave batten ${result.underEaveBatten} != '
      'expected $expectedUnderEaveBatten',
    );
  }

  final gaugeStart = gaugeBattenStartMm(result, materialType: materialType);
  if (result.firstBatten != gaugeStart) {
    throw StateError(
      'Deprecated firstBatten ${result.firstBatten} != gauge start $gaugeStart',
    );
  }

  if (expectedUnderEaveBatten == null &&
      showsUnderEaveBattenForMaterial(materialType)) {
    throw StateError('Expected under-eave batten for $materialType');
  }
  if (expectedUnderEaveBatten != null &&
      !showsUnderEaveBattenForMaterial(materialType)) {
    throw StateError('Unexpected under-eave batten for $materialType');
  }
}

void expectHorizontalGoldenWidths({
  required HorizontalCalculationResult result,
  required GoldenHorizontalExpectation expected,
}) {
  if (result.newWidth != expected.designWidth) {
    throw StateError(
      'Design width ${result.newWidth} != expected ${expected.designWidth}',
    );
  }

  final adjusted = adjustedWidthFromResult(result);
  if (adjusted != expected.adjustedWidth) {
    throw StateError(
      'Adjusted width $adjusted != expected ${expected.adjustedWidth}',
    );
  }

  if (result.lhOverhang != expected.lhOverhang) {
    throw StateError(
      'LH overhang ${result.lhOverhang} != expected ${expected.lhOverhang}',
    );
  }
  if (result.rhOverhang != expected.rhOverhang) {
    throw StateError(
      'RH overhang ${result.rhOverhang} != expected ${expected.rhOverhang}',
    );
  }
}

void expectHorizontalReconciles({
  required HorizontalCalculationInput input,
  required HorizontalCalculationResult result,
}) {
  final issues = validateHorizontalReconciles(input: input, result: result);
  if (issues.isNotEmpty) {
    throw StateError(issues.map((issue) => issue.message).join('; '));
  }
}

void expectValidHorizontalGoldenResult({
  required HorizontalCalculationResult result,
  required bool defaultCrossBonded,
  required int? expectedSecondMark,
}) {
  if (result.solution == 'Invalid') {
    throw StateError('Expected valid horizontal solution');
  }

  if (defaultCrossBonded) {
    if (result.secondMark == null) {
      throw StateError('Cross-bonded tile should produce a second mark');
    }
    if (result.secondMark! <= result.firstMark) {
      throw StateError('Second mark must be greater than first mark');
    }
    if (expectedSecondMark != null && result.secondMark != expectedSecondMark) {
      throw StateError(
        'Second mark ${result.secondMark} != expected $expectedSecondMark',
      );
    }
  } else {
    if (result.secondMark != null) {
      throw StateError('Non cross-bonded tile should not produce second mark');
    }
    if (expectedSecondMark != null) {
      throw StateError('Expected no second mark');
    }
  }
}