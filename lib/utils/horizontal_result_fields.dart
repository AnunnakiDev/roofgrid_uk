import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/width_calculation_detail.dart';
import 'package:roofgrid_uk/utils/calculation_geometry.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';

/// Marks notation already includes spacing context — do not append units.
String formatMarksDisplay(String marks) {
  final trimmed = marks.trim();
  if (trimmed.isEmpty || trimmed == 'N/A') {
    return trimmed.isEmpty ? 'N/A' : trimmed;
  }
  if (trimmed.endsWith('mm')) {
    return trimmed;
  }
  return trimmed;
}

WidthCalculationDetail? widthDetailAt(
  HorizontalCalculationResult result,
  int index,
) {
  final details = result.widthDetails;
  if (details == null || details.isEmpty || index >= details.length) {
    return null;
  }
  return details[index];
}

int widthDetailFirstMark(
  HorizontalCalculationResult result,
  int index,
) {
  return widthDetailAt(result, index)?.firstMark ?? result.firstMark;
}

int? widthDetailSecondMark(
  HorizontalCalculationResult result,
  int index,
) {
  return widthDetailAt(result, index)?.secondMark ?? result.secondMark;
}

/// Split-set solutions with zero split groups or identical mark increments
/// are presented as even sets to the roofer.
bool hasActualHorizontalSplit(HorizontalCalculationResult result) {
  if (result.solution != 'Split Sets') return false;

  final split = parseSetsNotation(result.splitMarks);
  if (split == null || split.setCount <= 0) return false;

  final primary = parseSetsNotation(result.marks);
  if (primary != null && primary.spacingMm == split.spacingMm) {
    return false;
  }

  return true;
}

String effectiveHorizontalSolution(HorizontalCalculationResult result) {
  if (result.solution == 'Split Sets' && !hasActualHorizontalSplit(result)) {
    return 'Even Sets';
  }
  return result.solution;
}

String horizontalMarksSummaryValue(HorizontalCalculationResult result) {
  if (hasActualHorizontalSplit(result) &&
      result.splitMarks != null &&
      result.splitMarks!.isNotEmpty) {
    return '${formatMarksDisplay(result.splitMarks!)} + '
        '${formatMarksDisplay(result.marks)}';
  }
  return formatMarksDisplay(result.marks);
}

String horizontalFirstMarkSummaryValue(HorizontalCalculationResult result) {
  final details = result.widthDetails;
  if (details == null || details.length <= 1) {
    return '${result.firstMark} mm';
  }

  final marks = details.map((detail) => detail.firstMark).toSet();
  if (marks.length == 1) {
    return '${marks.first} mm';
  }
  return 'Varies by width (see details)';
}