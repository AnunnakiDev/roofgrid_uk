import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/rafter_calculation_detail.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/width_calculation_detail.dart';
import 'package:roofgrid_uk/utils/horizontal_result_fields.dart';
import 'package:roofgrid_uk/utils/horizontal_result_validation.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';
import 'package:roofgrid_uk/utils/vertical_result_formatting.dart';

class ResultDisplayRow {
  final String label;
  final String value;

  const ResultDisplayRow({
    required this.label,
    required this.value,
  });
}

class SlopeInputEntry {
  final String label;
  final num value;

  const SlopeInputEntry({
    required this.label,
    required this.value,
  });
}

class WidthInputEntry {
  final String label;
  final num value;

  const WidthInputEntry({
    required this.label,
    required this.value,
  });
}

class JobWorkingsSection {
  final String title;
  final List<ResultDisplayRow> rows;

  const JobWorkingsSection({
    required this.title,
    required this.rows,
  });
}

enum CalculatorWorkingsScope {
  vertical,
  horizontal,
  combined,
}

class JobWorkingsData {
  final List<ResultDisplayRow> tileRows;
  final List<ResultDisplayRow> verticalInputRows;
  final List<ResultDisplayRow> horizontalInputRows;
  final List<JobWorkingsSection> verticalWorkings;
  final List<JobWorkingsSection> horizontalWorkings;
  final CalculatorWorkingsScope scope;

  const JobWorkingsData({
    this.tileRows = const [],
    this.verticalInputRows = const [],
    this.horizontalInputRows = const [],
    this.verticalWorkings = const [],
    this.horizontalWorkings = const [],
    this.scope = CalculatorWorkingsScope.combined,
  });

  String get verticalInputsTitle =>
      scope == CalculatorWorkingsScope.vertical ? 'Inputs' : 'Vertical inputs';

  String get horizontalInputsTitle => scope == CalculatorWorkingsScope.horizontal
      ? 'Inputs'
      : 'Horizontal inputs';

  String get verticalWorkingsTitle => scope == CalculatorWorkingsScope.vertical
      ? 'Workings'
      : 'Vertical workings';

  String get horizontalWorkingsTitle => scope == CalculatorWorkingsScope.horizontal
      ? 'Workings'
      : 'Horizontal workings';

  bool get isEmpty =>
      tileRows.isEmpty &&
      verticalInputRows.isEmpty &&
      horizontalInputRows.isEmpty &&
      verticalWorkings.isEmpty &&
      horizontalWorkings.isEmpty;
}

List<SlopeInputEntry> slopeEntriesFromMaps(
  List<Map<String, dynamic>> slopes,
) {
  return slopes.asMap().entries.map((entry) {
    final slope = entry.value;
    return SlopeInputEntry(
      label: slope['label'] as String? ?? 'Rafter ${entry.key + 1}',
      value: (slope['value'] as num?) ?? 0,
    );
  }).toList();
}

List<WidthInputEntry> widthEntriesFromMaps(
  List<Map<String, dynamic>> widths,
) {
  return widths.asMap().entries.map((entry) {
    final width = entry.value;
    return WidthInputEntry(
      label: width['label'] as String? ?? 'Width ${entry.key + 1}',
      value: (width['value'] as num?) ?? 0,
    );
  }).toList();
}

List<SlopeInputEntry> slopeEntriesFromSavedInputs(
  List<dynamic> rafters,
) {
  return slopeEntriesFromMaps(
    rafters.cast<Map<String, dynamic>>(),
  );
}

List<WidthInputEntry> widthEntriesFromSavedInputs(
  List<dynamic> widths,
) {
  return widthEntriesFromMaps(
    widths.cast<Map<String, dynamic>>(),
  );
}

RafterCalculationDetail? rafterDetailAt(
  VerticalCalculationResult result,
  int index,
) {
  final details = result.rafterDetails;
  if (details == null || details.isEmpty || index >= details.length) {
    return null;
  }
  return details[index];
}

String ridgeOffsetSummaryValue(VerticalCalculationResult result) {
  final details = result.rafterDetails;
  if (details == null || details.isEmpty) {
    return '${result.ridgeOffset} mm';
  }
  final offsets = details.map((detail) => detail.ridgeOffset).toSet();
  if (offsets.length == 1) {
    return '${offsets.first} mm';
  }
  return 'Varies by position (see details)';
}

List<String> horizontalPositionMarkChips({
  required HorizontalCalculationResult result,
  required List<WidthInputEntry> widths,
}) {
  if (result.solution == 'Invalid' || widths.length <= 1) {
    return const [];
  }

  final chips = <String>[];
  for (var index = 0; index < widths.length; index++) {
    final firstMark = widthDetailFirstMark(result, index);
    chips.add('${widths[index].label}: $firstMark mm');
  }

  final uniqueMarks =
      chips.map((chip) => chip.split(':').last.trim()).toSet();
  return uniqueMarks.length > 1 ? chips : const [];
}

List<String> verticalPositionGaugeChips({
  required VerticalCalculationResult result,
  required List<SlopeInputEntry> slopes,
}) {
  if (result.solution == 'Invalid' || slopes.length <= 1) {
    return const [];
  }

  final chips = <String>[];
  for (var index = 0; index < slopes.length; index++) {
    final detail = rafterDetailAt(result, index);
    final gauge = detail?.gauge;
    if (gauge != null && gauge > 0) {
      chips.add('${slopes[index].label}: ${gauge} mm');
    }
  }

  final unique = chips.toSet();
  return unique.length > 1 ? chips : const [];
}

List<ResultDisplayRow> verticalHeroRows({
  required VerticalCalculationResult result,
  required String? materialType,
  List<SlopeInputEntry> slopes = const [],
}) {
  if (result.solution == 'Invalid') {
    return [
      ResultDisplayRow(
        label: 'No valid solution',
        value: result.warning ?? 'Unable to calculate',
      ),
    ];
  }

  final rows = <ResultDisplayRow>[];

  if (shouldShowEaveBatten(result)) {
    rows.add(
      ResultDisplayRow(
        label: 'Eave batten',
        value: '${result.eaveBatten}',
      ),
    );
  }
  if (shouldShowDistinctFirstGaugeBatten(result)) {
    rows.add(
      ResultDisplayRow(
        label: 'First gauge batten',
        value: '${result.firstBatten}',
      ),
    );
  }
  if (shouldShowUnderEaveBatten(
    materialType: materialType,
    result: result,
  )) {
    rows.add(
      ResultDisplayRow(
        label: 'Under-eave batten',
        value: '${result.underEaveBatten}',
      ),
    );
  }

  for (final gaugeTile in heroGaugeTiles(
    result,
    slopeLabels: slopes.map((slope) => slope.label).toList(),
  )) {
    rows.add(
      ResultDisplayRow(
        label: gaugeTile.label,
        value: gaugeTile.value,
      ),
    );
  }
  rows.add(
    ResultDisplayRow(
      label: 'Battens',
      value: '${heroBattenCount(result)}',
    ),
  );

  final cutCourse = summaryCutCourseMm(result);
  if (result.solution == 'Cut Course' &&
      cutCourse != null &&
      cutCourse > 0) {
    rows.add(
      ResultDisplayRow(
        label: 'Cut course',
        value: '$cutCourse',
      ),
    );
  }

  return rows;
}

List<ResultDisplayRow> verticalSecondaryRows({
  required VerticalCalculationResult result,
  required String? materialType,
}) {
  if (result.solution == 'Invalid') {
    return const [];
  }

  return [
    ResultDisplayRow(label: 'Solution', value: result.solution),
    ResultDisplayRow(
      label: 'Courses (inc. eave)',
      value: result.totalCourses.toString(),
    ),
    ResultDisplayRow(
      label: 'Gauge (full)',
      value: gaugeSummaryValue(result),
    ),
    ResultDisplayRow(
      label: 'Ridge offset (full)',
      value: ridgeOffsetSummaryValue(result),
    ),
  ];
}

List<ResultDisplayRow> verticalSummaryRows({
  required VerticalCalculationResult result,
  required String? materialType,
  List<SlopeInputEntry> slopes = const [],
}) {
  if (result.solution == 'Invalid') {
    return [
      ResultDisplayRow(label: 'Solution', value: result.solution),
      if (result.warning != null)
        ResultDisplayRow(label: 'Reason', value: result.warning!),
    ];
  }

  return [
    ...verticalHeroRows(
      result: result,
      materialType: materialType,
      slopes: slopes,
    ),
    ...verticalSecondaryRows(result: result, materialType: materialType),
  ];
}

List<ResultDisplayRow> horizontalHeroRows(
  HorizontalCalculationResult result,
) {
  if (result.solution == 'Invalid') {
    return [
      ResultDisplayRow(
        label: 'No valid solution',
        value: result.warning ?? 'Unable to calculate',
      ),
    ];
  }

  final rows = <ResultDisplayRow>[
    ResultDisplayRow(
      label: 'First mark',
      value: '${result.firstMark}',
    ),
    ResultDisplayRow(
      label: 'Adjusted width',
      value: '${adjustedWidthFromResult(result) ?? result.newWidth}',
    ),
  ];

  if (result.lhOverhang != null) {
    rows.add(
      ResultDisplayRow(
        label: 'LH verge',
        value: '${result.lhOverhang}',
      ),
    );
  }
  if (result.rhOverhang != null) {
    rows.add(
      ResultDisplayRow(
        label: 'RH verge',
        value: '${result.rhOverhang}',
      ),
    );
  }

  return rows;
}

List<ResultDisplayRow> horizontalSecondaryRows(
  HorizontalCalculationResult result,
) {
  if (result.solution == 'Invalid') {
    return [
      ResultDisplayRow(label: 'Solution', value: result.solution),
      if (result.warning != null)
        ResultDisplayRow(label: 'Reason', value: result.warning!),
    ];
  }

  final rows = <ResultDisplayRow>[
    ResultDisplayRow(
      label: 'Solution',
      value: effectiveHorizontalSolution(result),
    ),
    ResultDisplayRow(
      label: 'Input width',
      value: '${result.width} mm',
    ),
    ResultDisplayRow(
      label: 'First mark (full)',
      value: horizontalFirstMarkSummaryValue(result),
    ),
    ResultDisplayRow(
      label: 'Marks (full)',
      value: horizontalMarksSummaryValue(result),
    ),
  ];

  if (hasActualHorizontalSplit(result) && result.splitMarks != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Split marks',
        value: formatMarksDisplay(result.splitMarks!),
      ),
    );
    rows.add(
      ResultDisplayRow(
        label: 'Even marks',
        value: formatMarksDisplay(result.marks),
      ),
    );
  }
  if (result.secondMark != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Second mark',
        value: '${result.secondMark} mm',
      ),
    );
  }
  if (result.cutTile != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Cut tile',
        value: '${result.cutTile} mm',
      ),
    );
  }
  if (result.actualSpacing != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Spacing',
        value: '${result.actualSpacing} mm',
      ),
    );
  }

  return rows;
}

List<ResultDisplayRow> horizontalSummaryRows(
  HorizontalCalculationResult result,
) {
  if (result.solution == 'Invalid') {
    return horizontalSecondaryRows(result);
  }

  return [
    ...horizontalHeroRows(result),
    ...horizontalSecondaryRows(result),
  ];
}

List<List<ResultDisplayRow>> verticalDetailSections({
  required VerticalCalculationResult result,
  required List<SlopeInputEntry> slopes,
}) {
  if (result.solution == 'Invalid') {
    return const [];
  }

  final sections = <List<ResultDisplayRow>>[];

  for (var index = 0; index < slopes.length; index++) {
    final slope = slopes[index];
    final detail = rafterDetailAt(result, index);
    final rows = <ResultDisplayRow>[
      ResultDisplayRow(
        label: 'Rafter height',
        value: '${detail?.rafterHeight ?? slope.value} mm',
      ),
      ResultDisplayRow(
        label: 'Gauge',
        value: detailGaugeValue(result: result, detail: detail),
      ),
      ResultDisplayRow(
        label: 'Ridge offset',
        value: '${detail?.ridgeOffset ?? result.ridgeOffset} mm',
      ),
    ];

    final cutCourse = detail?.cutCourse ?? result.cutCourse;
    if (cutCourse != null && cutCourse > 0) {
      rows.add(
        ResultDisplayRow(
          label: 'Cut course',
          value: '$cutCourse mm',
        ),
      );
    }

    sections.add(rows);
  }

  return sections;
}

List<List<ResultDisplayRow>> horizontalDetailSections({
  required HorizontalCalculationResult result,
  required List<WidthInputEntry> widths,
}) {
  final sections = <List<ResultDisplayRow>>[];

  for (var index = 0; index < widths.length; index++) {
    final width = widths[index];
    final detail = widthDetailAt(result, index);
    final rows = <ResultDisplayRow>[
      ResultDisplayRow(
        label: 'Input width',
        value: '${detail?.inputWidth ?? width.value} mm',
      ),
    ];

    if (detail != null) {
      rows.add(
        ResultDisplayRow(
          label: 'Adjusted width',
          value:
              '${adjustedWidthForDetail(detail) ?? detail.totalWidth} mm',
        ),
      );
    }

    final lhOverhang = detail?.lhOverhang ?? result.lhOverhang;
    if (lhOverhang != null) {
      rows.add(ResultDisplayRow(label: 'LH verge', value: '$lhOverhang mm'));
    }

    final rhOverhang = detail?.rhOverhang ?? result.rhOverhang;
    if (rhOverhang != null) {
      rows.add(ResultDisplayRow(label: 'RH verge', value: '$rhOverhang mm'));
    }

    final cutTile = detail?.cutTile ?? result.cutTile;
    if (cutTile != null) {
      rows.add(ResultDisplayRow(label: 'Cut tile', value: '$cutTile mm'));
    }

    rows.add(
      ResultDisplayRow(
        label: 'First mark',
        value: '${widthDetailFirstMark(result, index)} mm',
      ),
    );

    final secondMark = widthDetailSecondMark(result, index);
    if (secondMark != null) {
      rows.add(
        ResultDisplayRow(label: 'Second mark', value: '$secondMark mm'),
      );
    }

    final spacing = detail?.actualSpacing ?? result.actualSpacing;
    if (spacing != null) {
      rows.add(
        ResultDisplayRow(label: 'Spacing', value: '$spacing mm'),
      );
    }

    sections.add(rows);
  }

  return sections;
}

List<ResultDisplayRow> buildTileInputRows({
  String? tileName,
  String? materialType,
  num? coverWidth,
  num? tileHeight,
}) {
  final rows = <ResultDisplayRow>[
    ResultDisplayRow(label: 'Tile name', value: tileName ?? 'N/A'),
    ResultDisplayRow(label: 'Material', value: materialType ?? 'N/A'),
  ];
  if (coverWidth != null) {
    rows.add(ResultDisplayRow(label: 'Cover width', value: '$coverWidth mm'));
  }
  if (tileHeight != null) {
    rows.add(ResultDisplayRow(label: 'Height', value: '$tileHeight mm'));
  }
  return rows;
}

List<ResultDisplayRow> buildVerticalInputRows({
  double? gutterOverhang,
  String? useDryRidge,
  List<Map<String, dynamic>>? rafterHeights,
}) {
  if (gutterOverhang == null && useDryRidge == null && rafterHeights == null) {
    return const [];
  }

  final rows = <ResultDisplayRow>[];
  if (gutterOverhang != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Gutter overhang',
        value: '$gutterOverhang mm',
      ),
    );
  }
  if (useDryRidge != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Dry ridge',
        value: useDryRidge == 'YES' ? 'Yes' : 'No',
      ),
    );
  }
  if (rafterHeights != null) {
    for (var i = 0; i < rafterHeights.length; i++) {
      final rafter = rafterHeights[i];
      rows.add(
        ResultDisplayRow(
          label: rafter['label'] as String? ?? 'Rafter ${i + 1}',
          value: '${rafter['value']} mm',
        ),
      );
    }
  }
  return rows;
}

List<ResultDisplayRow> buildHorizontalInputRows({
  List<Map<String, dynamic>>? widths,
  String? useDryVerge,
  String? abutmentSide,
  String? useLHTile,
}) {
  if (widths == null &&
      useDryVerge == null &&
      abutmentSide == null &&
      useLHTile == null) {
    return const [];
  }

  final rows = <ResultDisplayRow>[];
  if (widths != null) {
    for (var i = 0; i < widths.length; i++) {
      final width = widths[i];
      rows.add(
        ResultDisplayRow(
          label: width['label'] as String? ?? 'Width ${i + 1}',
          value: '${width['value']} mm',
        ),
      );
    }
  }
  if (useDryVerge != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Dry verge',
        value: useDryVerge == 'YES' ? 'Yes' : 'No',
      ),
    );
  }
  if (abutmentSide != null) {
    rows.add(ResultDisplayRow(label: 'Abutment side', value: abutmentSide));
  }
  if (useLHTile != null) {
    rows.add(
      ResultDisplayRow(
        label: 'Left hand tile',
        value: useLHTile == 'YES' ? 'Yes' : 'No',
      ),
    );
  }
  return rows;
}

JobWorkingsData buildJobWorkingsData({
  String? tileName,
  String? materialType,
  num? coverWidth,
  num? tileHeight,
  double? gutterOverhang,
  String? useDryRidge,
  List<Map<String, dynamic>>? rafterHeights,
  List<Map<String, dynamic>>? widths,
  String? useDryVerge,
  String? abutmentSide,
  String? useLHTile,
  VerticalCalculationResult? verticalResult,
  HorizontalCalculationResult? horizontalResult,
  CalculatorWorkingsScope scope = CalculatorWorkingsScope.combined,
}) {
  final includeVertical = scope == CalculatorWorkingsScope.vertical ||
      scope == CalculatorWorkingsScope.combined;
  final includeHorizontal = scope == CalculatorWorkingsScope.horizontal ||
      scope == CalculatorWorkingsScope.combined;

  final slopes = !includeVertical || rafterHeights == null
      ? const <SlopeInputEntry>[]
      : slopeEntriesFromMaps(rafterHeights);
  final widthEntries = !includeHorizontal || widths == null
      ? const <WidthInputEntry>[]
      : widthEntriesFromMaps(widths);

  final verticalSections = !includeVertical || verticalResult == null
      ? const <List<ResultDisplayRow>>[]
      : verticalDetailSections(result: verticalResult, slopes: slopes);
  final horizontalSections = !includeHorizontal || horizontalResult == null
      ? const <List<ResultDisplayRow>>[]
      : horizontalDetailSections(result: horizontalResult, widths: widthEntries);

  return JobWorkingsData(
    scope: scope,
    tileRows: buildTileInputRows(
      tileName: tileName,
      materialType: materialType,
      coverWidth: coverWidth,
      tileHeight: tileHeight,
    ),
    verticalInputRows: includeVertical
        ? buildVerticalInputRows(
            gutterOverhang: gutterOverhang,
            useDryRidge: useDryRidge,
            rafterHeights: rafterHeights,
          )
        : const [],
    horizontalInputRows: includeHorizontal
        ? buildHorizontalInputRows(
            widths: widths,
            useDryVerge: useDryVerge,
            abutmentSide: abutmentSide,
            useLHTile: useLHTile,
          )
        : const [],
    verticalWorkings: [
      for (var i = 0; i < verticalSections.length; i++)
        JobWorkingsSection(
          title: slopes.length > i ? slopes[i].label : 'Rafter ${i + 1}',
          rows: verticalSections[i],
        ),
    ],
    horizontalWorkings: [
      for (var i = 0; i < horizontalSections.length; i++)
        JobWorkingsSection(
          title: widthEntries.length > i ? widthEntries[i].label : 'Width ${i + 1}',
          rows: horizontalSections[i],
        ),
    ],
  );
}

JobWorkingsData buildJobWorkingsDataFromSavedResult(
  SavedResult result, {
  CalculatorWorkingsScope? scope,
}) {
  final normalized = normalizeSavedResult(result);
  final effectiveScope = scope ??
      switch (normalized.type) {
        CalculationType.vertical => CalculatorWorkingsScope.vertical,
        CalculationType.horizontal => CalculatorWorkingsScope.horizontal,
        CalculationType.combined => CalculatorWorkingsScope.combined,
      };
  final verticalInputs =
      normalized.inputs['vertical_inputs'] as Map<String, dynamic>?;
  final horizontalInputs =
      normalized.inputs['horizontal_inputs'] as Map<String, dynamic>?;

  VerticalCalculationResult? verticalResult;
  HorizontalCalculationResult? horizontalResult;

  if (normalized.type == CalculationType.vertical) {
    verticalResult = VerticalCalculationResult.fromJson(normalized.outputs);
  } else if (normalized.type == CalculationType.horizontal) {
    horizontalResult =
        HorizontalCalculationResult.fromJson(normalized.outputs);
  } else if (normalized.type == CalculationType.combined) {
    verticalResult =
        VerticalCalculationResult.fromJson(normalized.outputs['vertical']);
    horizontalResult =
        HorizontalCalculationResult.fromJson(normalized.outputs['horizontal']);
  }

  return buildJobWorkingsData(
    tileName: normalized.tile['name']?.toString(),
    materialType: normalized.tile['materialType']?.toString() ??
        normalized.tile['TileSlateType']?.toString(),
    coverWidth: normalized.tile['tileCoverWidth'] as num?,
    tileHeight: normalized.tile['slateTileHeight'] as num?,
    gutterOverhang: verticalInputs?['gutterOverhang'] as double?,
    useDryRidge: verticalInputs?['useDryRidge'] as String?,
    rafterHeights: (verticalInputs?['rafterHeights'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>(),
    widths: (horizontalInputs?['widths'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>(),
    useDryVerge: horizontalInputs?['useDryVerge'] as String?,
    abutmentSide: horizontalInputs?['abutmentSide'] as String?,
    useLHTile: horizontalInputs?['useLHTile'] as String?,
    verticalResult: verticalResult,
    horizontalResult: horizontalResult,
    scope: effectiveScope,
  );
}

String _formatHeroSnippet(List<ResultDisplayRow> rows) {
  return rows
      .where((row) => row.label != 'No valid solution')
      .take(3)
      .map((row) {
        final unit = row.value.contains('@') ||
                row.value == 'Varies' ||
                row.value.contains('+')
            ? ''
            : ' mm';
        return '${row.label} ${row.value}$unit';
      })
      .join(' · ');
}

String savedResultSetoutSnippet(SavedResult result) {
  final normalized = normalizeSavedResult(result);
  final parts = <String>[];

  if (normalized.type == CalculationType.vertical ||
      normalized.type == CalculationType.combined) {
    final verticalJson = normalized.type == CalculationType.combined
        ? normalized.outputs['vertical'] as Map<String, dynamic>
        : normalized.outputs;
    final verticalResult = VerticalCalculationResult.fromJson(verticalJson);
    final materialType = normalized.tile['materialType']?.toString() ??
        normalized.tile['TileSlateType']?.toString();
    final rafters = (normalized.inputs['vertical_inputs']?['rafterHeights']
            as List<dynamic>?)
        ?.cast<Map<String, dynamic>>();
    final slopes = rafters == null
        ? const <SlopeInputEntry>[]
        : slopeEntriesFromMaps(rafters);
    final snippet = _formatHeroSnippet(
      verticalHeroRows(
        result: verticalResult,
        materialType: materialType,
        slopes: slopes,
      ),
    );
    if (snippet.isNotEmpty) parts.add(snippet);
  }

  if (normalized.type == CalculationType.horizontal ||
      normalized.type == CalculationType.combined) {
    final horizontalJson = normalized.type == CalculationType.combined
        ? normalized.outputs['horizontal'] as Map<String, dynamic>
        : normalized.outputs;
    final horizontalResult = HorizontalCalculationResult.fromJson(horizontalJson);
    final snippet = _formatHeroSnippet(horizontalHeroRows(horizontalResult));
    if (snippet.isNotEmpty) parts.add(snippet);
  }

  return parts.join(' · ');
}