import 'package:roofgrid_uk/models/calculator/rafter_calculation_detail.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/calculation_geometry.dart';

String formatGaugeSentence({
  required int battens,
  required int gaugeMm,
}) {
  return '$battens battens @ $gaugeMm mm';
}

String formatSplitGaugeSentence({
  required int n1,
  required int g1,
  required int n2,
  required int g2,
}) {
  return '${formatGaugeSentence(battens: n1, gaugeMm: g1)} + '
      '${formatGaugeSentence(battens: n2, gaugeMm: g2)}';
}

String formatCutGaugeSentence({
  required int fullBattens,
  required int gaugeMm,
  required int? cutCourseMm,
}) {
  final base = '$fullBattens full battens @ $gaugeMm mm';
  if (cutCourseMm != null && cutCourseMm > 0) {
    return '$base + cut course ${cutCourseMm} mm above eave';
  }
  return base;
}

int? _positiveGauge(int gauge) => gauge > 0 ? gauge : null;

bool _hasVaryingPositionGauges(List<RafterCalculationDetail> details) {
  final gauges =
      details.map((d) => _positiveGauge(d.gauge)).whereType<int>().toSet();
  return gauges.length > 1;
}

String gaugeSummaryValue(VerticalCalculationResult result) {
  final details = result.rafterDetails;
  if (details != null &&
      details.isNotEmpty &&
      _hasVaryingPositionGauges(details)) {
    return 'Varies by position (see details)';
  }

  switch (result.solution) {
    case 'Split Courses':
      final lower = parseAtNotation(result.splitGauge);
      final upper = parseAtNotation(result.gauge);
      if (lower != null && upper != null) {
        return formatSplitGaugeSentence(
          n1: lower.count,
          g1: lower.spacingMm,
          n2: upper.count,
          g2: upper.spacingMm,
        );
      }
      break;
    case 'Cut Course':
      final full = parseAtNotation(result.gauge);
      if (full != null) {
        return formatCutGaugeSentence(
          fullBattens: full.count,
          gaugeMm: full.spacingMm,
          cutCourseMm: summaryCutCourseMm(result),
        );
      }
      break;
    default:
      final even = parseAtNotation(result.gauge);
      if (even != null) {
        return formatGaugeSentence(
          battens: even.count,
          gaugeMm: even.spacingMm,
        );
      }
  }

  return result.gauge;
}

String detailGaugeValue({
  required VerticalCalculationResult result,
  required RafterCalculationDetail? detail,
}) {
  if (detail?.gauge1 != null && detail?.gauge2 != null) {
    final lower = parseAtNotation(result.splitGauge);
    final upper = parseAtNotation(result.gauge);
    if (lower != null && upper != null) {
      return formatSplitGaugeSentence(
        n1: lower.count,
        g1: detail!.gauge1!,
        n2: upper.count,
        g2: detail.gauge2!,
      );
    }
    return '${detail!.gauge1} / ${detail.gauge2} mm';
  }

  final gaugeMm = _positiveGauge(detail?.gauge ?? 0);
  if (gaugeMm != null) {
    if (result.solution == 'Cut Course') {
      final full = parseAtNotation(result.gauge);
      return formatCutGaugeSentence(
        fullBattens: full?.count ?? (result.totalCourses - 1),
        gaugeMm: gaugeMm,
        cutCourseMm: detail?.cutCourse ?? result.cutCourse,
      );
    }
    final battens = result.totalCourses - 1;
    return formatGaugeSentence(battens: battens, gaugeMm: gaugeMm);
  }

  return gaugeSummaryValue(result);
}

int? summaryCutCourseMm(VerticalCalculationResult result) {
  if (result.cutCourse != null && result.cutCourse! > 0) {
    return result.cutCourse;
  }
  final details = result.rafterDetails;
  if (details == null) return null;
  for (final detail in details) {
    if (detail.cutCourse != null && detail.cutCourse! > 0) {
      return detail.cutCourse;
    }
  }
  return null;
}

bool hasCutCourseInResult(VerticalCalculationResult result) {
  return summaryCutCourseMm(result) != null;
}

class HeroGaugeTile {
  final String label;
  final String value;

  const HeroGaugeTile({
    required this.label,
    required this.value,
  });
}

RafterCalculationDetail? _rafterDetailAt(
  VerticalCalculationResult result,
  int index,
) {
  final details = result.rafterDetails;
  if (details == null || details.isEmpty || index >= details.length) {
    return null;
  }
  return details[index];
}

String _heroGaugeValueForPosition({
  required VerticalCalculationResult result,
  required RafterCalculationDetail? detail,
}) {
  if (result.solution == 'Split Courses' &&
      detail?.gauge1 != null &&
      detail?.gauge2 != null) {
    final lower = parseAtNotation(result.splitGauge);
    final upper = parseAtNotation(result.gauge);
    if (lower != null && upper != null) {
      return '${lower.count} @ ${detail!.gauge1} + '
          '${upper.count} @ ${detail.gauge2}';
    }
    return '${detail!.gauge1} / ${detail.gauge2}';
  }

  if (result.solution == 'Cut Course') {
    final full = parseAtNotation(result.gauge);
    final gaugeMm = _positiveGauge(detail?.gauge ?? 0) ?? full?.spacingMm;
    if (full != null && gaugeMm != null) {
      return '${full.count} @ $gaugeMm';
    }
  }

  final gaugeMm = _positiveGauge(detail?.gauge ?? 0);
  if (gaugeMm != null) {
    final even = parseAtNotation(result.gauge);
    final count = even?.count ?? (result.totalCourses - 1);
    return '$count @ $gaugeMm';
  }

  return result.gauge;
}

List<HeroGaugeTile> _singlePositionGaugeTiles(VerticalCalculationResult result) {
  switch (result.solution) {
    case 'Split Courses':
      final lower = parseAtNotation(result.splitGauge);
      final upper = parseAtNotation(result.gauge);
      if (lower != null && upper != null) {
        return [
          HeroGaugeTile(
            label: 'Lower gauge',
            value: '${lower.count} @ ${lower.spacingMm}',
          ),
          HeroGaugeTile(
            label: 'Upper gauge',
            value: '${upper.count} @ ${upper.spacingMm}',
          ),
        ];
      }
      break;
    case 'Cut Course':
      final full = parseAtNotation(result.gauge);
      if (full != null) {
        return [
          HeroGaugeTile(
            label: 'Gauge',
            value: '${full.count} @ ${full.spacingMm}',
          ),
        ];
      }
      break;
    default:
      final even = parseAtNotation(result.gauge);
      if (even != null) {
        return [
          HeroGaugeTile(
            label: 'Gauge',
            value: '${even.count} @ ${even.spacingMm}',
          ),
        ];
      }
  }

  return [HeroGaugeTile(label: 'Gauge', value: result.gauge)];
}

/// Gauge tile(s) for the set-out hero strip — one per slope input when multi-rafter.
List<HeroGaugeTile> heroGaugeTiles(
  VerticalCalculationResult result, {
  List<String> slopeLabels = const [],
}) {
  final details = result.rafterDetails;
  final positionCount = slopeLabels.isNotEmpty
      ? slopeLabels.length
      : (details?.length ?? 0);

  if (positionCount > 1) {
    return [
      for (var index = 0; index < positionCount; index++)
        HeroGaugeTile(
          label: index < slopeLabels.length
              ? slopeLabels[index]
              : 'Rafter ${index + 1}',
          value: _heroGaugeValueForPosition(
            result: result,
            detail: _rafterDetailAt(result, index),
          ),
        ),
    ];
  }

  return _singlePositionGaugeTiles(result);
}

/// Total batten count for the hero strip (sum of split groups when applicable).
int heroBattenCount(VerticalCalculationResult result) {
  switch (result.solution) {
    case 'Split Courses':
      final lower = parseAtNotation(result.splitGauge);
      final upper = parseAtNotation(result.gauge);
      if (lower != null && upper != null) {
        return lower.count + upper.count;
      }
      break;
    case 'Cut Course':
      final full = parseAtNotation(result.gauge);
      if (full != null) return full.count;
      break;
    default:
      final even = parseAtNotation(result.gauge);
      if (even != null) return even.count;
  }
  return result.totalCourses > 0 ? result.totalCourses - 1 : 0;
}

/// Compact single-line gauge for saved-list snippets.
String heroGaugeValue(VerticalCalculationResult result) {
  final tiles = heroGaugeTiles(result);
  if (tiles.length == 1) {
    final value = tiles.first.value;
    return value.contains('@') ? '$value mm' : value;
  }
  return tiles.map((tile) => '${tile.value} mm').join(' + ');
}