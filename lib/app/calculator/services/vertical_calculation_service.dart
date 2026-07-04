import 'dart:math';
import 'package:roofgrid_uk/models/calculator/rafter_calculation_detail.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';

/// Vertical batten gauge from fascia-top → ridge; per-position gauge with stack balance.
class VerticalCalculationService {
  static Future<VerticalCalculationResult> calculateVertical({
    required VerticalCalculationInput input,
    required String materialType,
    required double slateTileHeight,
    required double maxGauge,
    required double minGauge,
  }) async {
    if (input.rafterHeights.isEmpty ||
        input.rafterHeights.any((h) => h < 500)) {
      return _invalidResult(
        input,
        'Rafter height values must be at least 500mm to calculate a valid vertical solution.',
      );
    }

    final datum = resolveVerticalBattenDatum(
      materialType: materialType,
      tileHeight: slateTileHeight,
      gutterOverhang: input.gutterOverhang,
      maxGauge: maxGauge,
    );

    final int maxInputRafter = input.rafterHeights.reduce(max).round();
    final int minGaugeInt = minGauge.round();
    final int maxGaugeInt = maxGauge.round();
    final rafterInts =
        input.rafterHeights.map((height) => height.round()).toList();
    final gaugeZones = rafterInts
        .map((rafter) => rafter - datum.gaugeZoneBottomMm)
        .toList();

    if (gaugeZones.any((zone) => zone <= 0)) {
      return _invalidResult(
        input,
        'Rafter height is too short for eave and first gauge batten placement at this gutter overhang.',
        inputRafter: maxInputRafter,
      );
    }

    final minZone = gaugeZones.reduce(min);
    var minBattens = max(1, (minZone / maxGaugeInt).ceil());
    var maxBattens = (minZone / minGaugeInt).floor();

    if (materialType == 'Fibre Cement Slate') {
      minBattens = max(minBattens, 1);
      maxBattens = max(maxBattens, 1);
    }

    if (maxBattens < minBattens) {
      return _invalidResult(
        input,
        'Cannot tile full courses from eave batten to ridge within gauge and ridge limits.',
        inputRafter: maxInputRafter,
      );
    }

    Map<String, dynamic>? solved;

    for (var battens = minBattens; battens <= maxBattens; battens++) {
      final even = _solveEven(
        rafterHeights: rafterInts,
        gaugeZones: gaugeZones,
        battens: battens,
        minGauge: minGaugeInt,
        maxGauge: maxGaugeInt,
        useDryRidge: input.useDryRidge,
        datum: datum,
      );
      if (even != null) {
        solved = even;
        break;
      }
    }

    if (solved == null) {
      for (var battens = minBattens; battens <= maxBattens; battens++) {
        final split = _solveSplit(
          rafterHeights: rafterInts,
          gaugeZones: gaugeZones,
          battens: battens,
          minGauge: minGaugeInt,
          maxGauge: maxGaugeInt,
          useDryRidge: input.useDryRidge,
          datum: datum,
        );
        if (split != null) {
          solved = split;
          break;
        }
      }
    }

    if (solved == null) {
      solved = _solveBottomCut(
        rafterHeights: rafterInts,
        gaugeZones: gaugeZones,
        minGauge: minGaugeInt,
        maxGauge: maxGaugeInt,
        useDryRidge: input.useDryRidge,
        tileHeight: slateTileHeight,
        datum: datum,
      );
    }

    if (solved == null) {
      return _invalidResult(
        input,
        'Cannot tile full courses from eave batten to ridge within gauge and ridge limits. '
        'Measurement positions may be too far apart for the same course count.',
        inputRafter: maxInputRafter,
      );
    }

    final solutionType = solved['type'] as String;
    final courses = solved['courses'] as int;
    final rafterResults =
        (solved['rafterResults'] as List).cast<Map<String, dynamic>>();
    final first = rafterResults.first;
    final rafterDetails = _buildRafterDetails(rafterResults, solutionType);

    final int? underEaveForResult = datum.underEaveBattenPositionMm;

    return VerticalCalculationResult(
      inputRafter: maxInputRafter,
      solution: solutionType == 'full'
          ? 'Even Courses'
          : solutionType == 'split'
              ? 'Split Courses'
              : 'Cut Course',
      totalCourses: courses,
      underEaveBatten: underEaveForResult,
      eaveBatten: datum.eaveBattenMm,
      firstBatten: datum.firstGaugeBattenMm,
      ridgeOffset: first['ridgeOffset'] as int,
      cutCourse: solutionType == 'cut' ? first['cutCourse'] as int? : null,
      gauge: _formatGaugeSummary(solutionType, courses, first),
      splitGauge: solutionType == 'split'
          ? '${first['courses1']} @ ${first['gauge1']}'
          : null,
      warning: _resolveNearBoundWarning(
        rafterResults: rafterResults,
        useDryRidge: input.useDryRidge,
        solutionType: solutionType,
        tileHeight: slateTileHeight,
      ),
      rafterDetails: rafterDetails,
    );
  }

  static String? _resolveNearBoundWarning({
    required List<Map<String, dynamic>> rafterResults,
    required String useDryRidge,
    required String solutionType,
    required double tileHeight,
  }) {
    final messages = <String>[];
    final maxRidge = ridgeOffsetMaxMm(useDryRidge);
    final ridges =
        rafterResults.map((entry) => entry['ridgeOffset'] as int).toList();

    if (ridges.any((ridge) => ridge >= maxRidge - 5)) {
      messages.add(
        'Ridge offset is within 5 mm of the $maxRidge mm limit at one or more positions.',
      );
    }
    if (ridges.any((ridge) => ridge <= kRidgeOffsetMinMm + 1)) {
      messages.add(
        'Ridge offset is at the ${kRidgeOffsetMinMm} mm minimum at one or more positions.',
      );
    }

    if (ridges.length > 1) {
      final spread = ridges.reduce(max) - ridges.reduce(min);
      if (spread > 40) {
        messages.add(
          'Ridge offsets vary by $spread mm across positions — check squaring on site.',
        );
      }
    }

    if (solutionType == 'cut') {
      final minCut = max(tileHeight / 2, 100).round();
      for (final entry in rafterResults) {
        final cut = entry['cutCourse'] as int? ?? 0;
        if (cut > 0 && cut <= minCut + 10) {
          messages.add(
            'Cut course gauge is near the minimum tile size ($minCut mm) above eave.',
          );
          break;
        }
      }
    }

    if (messages.isEmpty) return null;
    return messages.join(' ');
  }

  static String _formatGaugeSummary(
    String solutionType,
    int courses,
    Map<String, dynamic> first,
  ) {
    switch (solutionType) {
      case 'split':
        return '${first['courses2']} @ ${first['gauge2']}';
      case 'cut':
        return '${first['fullBattens']} @ ${first['gauge']}';
      default:
        return '${courses - 1} @ ${first['gauge']}';
    }
  }

  static Map<String, dynamic>? _solveEven({
    required List<int> rafterHeights,
    required List<int> gaugeZones,
    required int battens,
    required int minGauge,
    required int maxGauge,
    required String useDryRidge,
    required VerticalBattenDatum datum,
  }) {
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < gaugeZones.length; i++) {
      final gauge = _resolveIntegerGauge(
        gaugeZone: gaugeZones[i],
        battens: battens,
        minGauge: minGauge,
        maxGauge: maxGauge,
        useDryRidge: useDryRidge,
      );
      if (gauge == null) {
        return null;
      }
      final ridgeOffset = gaugeZones[i] - battens * gauge;
      results.add({
        'rafterHeight': rafterHeights[i],
        'ridgeOffset': ridgeOffset,
        'gauge': gauge,
      });
    }

    if (!_validateStackBalance(
      results: results,
      datum: datum,
      tiledHeightFor: (entry) => battens * (entry['gauge'] as int),
    )) {
      return null;
    }

    return {
      'type': 'full',
      'courses': battens + 1,
      'rafterResults': results,
    };
  }

  static Map<String, dynamic>? _solveSplit({
    required List<int> rafterHeights,
    required List<int> gaugeZones,
    required int battens,
    required int minGauge,
    required int maxGauge,
    required String useDryRidge,
    required VerticalBattenDatum datum,
  }) {
    for (var n1 = 1; n1 <= battens - 1; n1++) {
      final n2 = battens - n1;
      final results = <Map<String, dynamic>>[];
      var valid = true;

      for (var i = 0; i < gaugeZones.length; i++) {
        final zone = gaugeZones[i];
        final split = _resolveSplitGauges(
          gaugeZone: zone,
          n1: n1,
          n2: n2,
          minGauge: minGauge,
          maxGauge: maxGauge,
          useDryRidge: useDryRidge,
        );
        if (split == null) {
          valid = false;
          break;
        }
        results.add({
          'rafterHeight': rafterHeights[i],
          'ridgeOffset': split.ridgeOffset,
          'gauge1': split.gauge1,
          'gauge2': split.gauge2,
          'courses1': n1,
          'courses2': n2,
          'gauge': split.gauge2,
        });
      }

      if (!valid) continue;

      if (!_validateStackBalance(
        results: results,
        datum: datum,
        tiledHeightFor: (entry) =>
            (entry['courses1'] as int) * (entry['gauge1'] as int) +
            (entry['courses2'] as int) * (entry['gauge2'] as int),
      )) {
        continue;
      }

      return {
        'type': 'split',
        'courses': battens + 1,
        'rafterResults': results,
      };
    }
    return null;
  }

  static Map<String, dynamic>? _solveBottomCut({
    required List<int> rafterHeights,
    required List<int> gaugeZones,
    required int minGauge,
    required int maxGauge,
    required String useDryRidge,
    required double tileHeight,
    required VerticalBattenDatum datum,
  }) {
    final ridgeStart = baseRidgeOffsetMm(useDryRidge);
    final minCut = max(tileHeight / 2, 100).round();
    final results = <Map<String, dynamic>>[];

    for (var i = 0; i < gaugeZones.length; i++) {
      final zone = gaugeZones[i];
      var fullBattens = (zone - ridgeStart) ~/ maxGauge;
      var cutCourse = zone - ridgeStart - fullBattens * maxGauge;

      while (cutCourse > 0 &&
          cutCourse < minCut &&
          fullBattens > 0) {
        fullBattens--;
        cutCourse = zone - ridgeStart - fullBattens * maxGauge;
      }

      if (cutCourse > 0 && cutCourse < minCut) {
        return null;
      }

      if (cutCourse == 0 && fullBattens == 0) {
        return null;
      }

      final ridgeOffset = ridgeStart;
      results.add({
        'rafterHeight': rafterHeights[i],
        'ridgeOffset': ridgeOffset,
        'gauge': maxGauge,
        'fullBattens': fullBattens,
        'cutCourse': cutCourse,
      });
    }

    if (!_validateStackBalance(
      results: results,
      datum: datum,
      tiledHeightFor: (entry) =>
          (entry['cutCourse'] as int) +
          (entry['fullBattens'] as int) * (entry['gauge'] as int),
    )) {
      return null;
    }

    final maxFull = results
        .map((entry) => entry['fullBattens'] as int)
        .reduce(max);
    final courses = maxFull + (results.first['cutCourse'] as int > 0 ? 2 : 1);

    return {
      'type': 'cut',
      'courses': courses,
      'rafterResults': results,
    };
  }

  static int? _resolveIntegerGauge({
    required int gaugeZone,
    required int battens,
    required int minGauge,
    required int maxGauge,
    required String useDryRidge,
  }) {
    final candidates = <int>{};
    final ideal = gaugeZone / battens;
    candidates.add(ideal.floor());
    candidates.add(ideal.ceil());
    for (var g = minGauge; g <= maxGauge; g++) {
      candidates.add(g);
    }

    final ordered = candidates.toList()
      ..sort((a, b) =>
          (a - ideal).abs().compareTo((b - ideal).abs()));

    for (final gauge in ordered) {
      if (gauge < minGauge || gauge > maxGauge) continue;
      final ridge = gaugeZone - battens * gauge;
      if (isRidgeOffsetInBounds(ridge, useDryRidge)) {
        return gauge;
      }
    }
    return null;
  }

  static _SplitGauges? _resolveSplitGauges({
    required int gaugeZone,
    required int n1,
    required int n2,
    required int minGauge,
    required int maxGauge,
    required String useDryRidge,
  }) {
    for (var g1 = maxGauge; g1 >= minGauge; g1--) {
      final remainder = gaugeZone - n1 * g1;
      if (n2 == 0) continue;
      final g2Ideal = remainder / n2;
      final g2Candidates = {g2Ideal.floor(), g2Ideal.ceil(), g1};
      for (final g2 in g2Candidates) {
        if (g2 < minGauge || g2 > maxGauge) continue;
        final ridge = gaugeZone - n1 * g1 - n2 * g2;
        if (isRidgeOffsetInBounds(ridge, useDryRidge)) {
          return _SplitGauges(gauge1: g1, gauge2: g2, ridgeOffset: ridge);
        }
      }
    }
    return null;
  }

  static bool _validateStackBalance({
    required List<Map<String, dynamic>> results,
    required VerticalBattenDatum datum,
    required int Function(Map<String, dynamic> entry) tiledHeightFor,
  }) {
    for (final entry in results) {
      final rafter = entry['rafterHeight'] as int;
      final tiled = tiledHeightFor(entry);
      final ridge = entry['ridgeOffset'] as int;
      final expected = datum.firstGaugeBattenMm + tiled + ridge;
      if (rafter != expected) {
        return false;
      }
    }
    return true;
  }

  static VerticalCalculationResult _invalidResult(
    VerticalCalculationInput input,
    String warning, {
    int inputRafter = 0,
  }) {
    return VerticalCalculationResult(
      inputRafter: input.rafterHeights.isNotEmpty
          ? input.rafterHeights.reduce(max).round()
          : inputRafter,
      solution: 'Invalid',
      totalCourses: 0,
      firstBatten: 0,
      ridgeOffset: 0,
      gauge: 'N/A',
      warning: warning,
    );
  }

  static List<RafterCalculationDetail> _buildRafterDetails(
    List<Map<String, dynamic>> rafterResults,
    String solutionType,
  ) {
    return rafterResults
        .map(
          (entry) => RafterCalculationDetail(
            rafterHeight: entry['rafterHeight'] as int,
            gauge: entry['gauge'] as int? ?? 0,
            ridgeOffset: entry['ridgeOffset'] as int,
            gauge1: solutionType == 'split' ? entry['gauge1'] as int? : null,
            gauge2: solutionType == 'split' ? entry['gauge2'] as int? : null,
            cutCourse:
                solutionType == 'cut' ? entry['cutCourse'] as int? : null,
          ),
        )
        .toList();
  }
}

class _SplitGauges {
  final int gauge1;
  final int gauge2;
  final int ridgeOffset;

  const _SplitGauges({
    required this.gauge1,
    required this.gauge2,
    required this.ridgeOffset,
  });
}