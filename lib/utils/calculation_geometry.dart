import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';

class AtNotationMeasurement {
  final int count;
  final int spacingMm;

  const AtNotationMeasurement({
    required this.count,
    required this.spacingMm,
  });
}

class SetsNotationMeasurement {
  final int setCount;
  final int tilesPerSet;
  final int spacingMm;

  const SetsNotationMeasurement({
    required this.setCount,
    required this.tilesPerSet,
    required this.spacingMm,
  });
}

AtNotationMeasurement? parseAtNotation(String? value) {
  if (value == null || value.isEmpty || value == 'N/A') {
    return null;
  }

  final parts = value.split('@');
  if (parts.length < 2) {
    final spacing = int.tryParse(value.trim());
    if (spacing == null) return null;
    return AtNotationMeasurement(count: 1, spacingMm: spacing);
  }

  final count = int.tryParse(parts[0].trim());
  final spacingPart = parts[1].trim();
  final numericPart =
      spacingPart.contains('mm') ? spacingPart.split('mm')[0].trim() : spacingPart;
  final spacing = int.tryParse(numericPart);
  if (count == null || spacing == null) return null;

  return AtNotationMeasurement(count: count, spacingMm: spacing);
}

SetsNotationMeasurement? parseSetsNotation(String? value) {
  if (value == null || value.isEmpty || value == 'N/A') {
    return null;
  }

  final setsMatch =
      RegExp(r'(\d+)\s+sets?\s+of\s+(\d+)\s+@\s+(\d+)').firstMatch(value);
  if (setsMatch == null) return null;

  final setCount = int.tryParse(setsMatch.group(1)!);
  final tilesPerSet = int.tryParse(setsMatch.group(2)!);
  final spacing = int.tryParse(setsMatch.group(3)!);
  if (setCount == null || tilesPerSet == null || spacing == null) {
    return null;
  }

  return SetsNotationMeasurement(
    setCount: setCount,
    tilesPerSet: tilesPerSet,
    spacingMm: spacing,
  );
}

int resolveVerticalGaugeSpacingMm(VerticalCalculationResult result) {
  final primary = parseAtNotation(result.splitGauge ?? result.gauge);
  return primary?.spacingMm ?? 0;
}

int resolveHorizontalMarksSpacingMm(HorizontalCalculationResult result) {
  final structured = parseSetsNotation(result.splitMarks ?? result.marks);
  if (structured != null) {
    return structured.spacingMm;
  }

  final fallback = parseAtNotation(result.splitMarks ?? result.marks);
  return fallback?.spacingMm ?? 0;
}