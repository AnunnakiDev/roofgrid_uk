import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/calculation_geometry.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';

/// A3 dimensions at 72 DPI (297mm × 420mm).
const double kVisualizationA3WidthPx = 842;
const double kVisualizationA3HeightPx = 1191;
const double kVisualizationA3AspectRatio =
    kVisualizationA3WidthPx / kVisualizationA3HeightPx;

class ResultVisualization extends StatelessWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final SavedResult? savedResult;
  final List<Map<String, dynamic>>? rafterHeights;
  final List<Map<String, dynamic>>? widths;
  final double? gutterOverhang;
  final String? tileMaterialType;
  final bool isThumbnail;

  const ResultVisualization({
    super.key,
     this.verticalResult,
    this.horizontalResult,
    this.savedResult,
    this.rafterHeights,
    this.widths,
    this.gutterOverhang,
    this.tileMaterialType,
    this.isThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    VerticalCalculationResult? effectiveVerticalResult = verticalResult;
    HorizontalCalculationResult? effectiveHorizontalResult = horizontalResult;

    if (savedResult != null) {
      if (savedResult!.type == CalculationType.vertical) {
        effectiveVerticalResult =
            VerticalCalculationResult.fromJson(savedResult!.outputs);
      } else if (savedResult!.type == CalculationType.horizontal) {
        effectiveHorizontalResult =
            HorizontalCalculationResult.fromJson(savedResult!.outputs);
      } else if (savedResult!.type == CalculationType.combined) {
        effectiveVerticalResult = VerticalCalculationResult.fromJson(
            savedResult!.outputs['vertical']);
        effectiveHorizontalResult = HorizontalCalculationResult.fromJson(
            savedResult!.outputs['horizontal']);
      }
    }

    if (effectiveVerticalResult == null && effectiveHorizontalResult == null) {
      return const Center(child: Text('No results to visualize'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final diagramBackground = colorScheme.surface;

    final painter = RoofPainter(
      verticalResult: effectiveVerticalResult,
      horizontalResult: effectiveHorizontalResult,
      savedResult: savedResult,
      rafterHeights: rafterHeights,
      widths: widths,
      gutterOverhang: gutterOverhang,
      tileMaterialType: tileMaterialType ??
          materialTypeFromTileJson(savedResult?.tile),
      primaryColor: colorScheme.primary,
      accentColor: colorScheme.secondary,
      textStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: isThumbnail ? 8 : 16,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
      isThumbnail: isThumbnail,
    );

    if (isThumbnail) {
      return ColoredBox(
        color: diagramBackground,
        child: CustomPaint(
          painter: painter,
          child: const SizedBox.expand(),
        ),
      );
    }

    return ColoredBox(
      color: diagramBackground,
      child: AspectRatio(
        aspectRatio: kVisualizationA3AspectRatio,
        child: CustomPaint(
          painter: painter,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> ensureMinimumLabeledEntries({
  required List<Map<String, dynamic>> entries,
  required int minimum,
  required String labelPrefix,
  required num defaultValue,
}) {
  if (entries.isEmpty) {
    return List.generate(
      minimum,
      (index) => {
        'label': '$labelPrefix ${index + 1}',
        'value': defaultValue,
      },
    );
  }

  final result = List<Map<String, dynamic>>.from(entries);
  while (result.length < minimum) {
    final last = result.last;
    result.add({
      'label': '$labelPrefix ${result.length + 1}',
      'value': last['value'] ?? defaultValue,
    });
  }
  return result;
}

List<Map<String, dynamic>> parseLabeledEntries(dynamic raw) {
  if (raw is! List) return [];
  return raw.map((item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return Map<String, dynamic>.from(item);
    return {'label': 'Unknown', 'value': 0};
  }).toList();
}

class RoofPainter extends CustomPainter {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final SavedResult? savedResult;
  final List<Map<String, dynamic>>? rafterHeights;
  final List<Map<String, dynamic>>? widths;
  final double? gutterOverhang;
  final String? tileMaterialType;
  final Color primaryColor;
  final Color accentColor;
  final TextStyle textStyle;
  final bool isThumbnail;

  RoofPainter({
    required this.verticalResult,
    required this.horizontalResult,
    this.savedResult,
    this.rafterHeights,
    this.widths,
    this.gutterOverhang,
    this.tileMaterialType,
    required this.primaryColor,
    required this.accentColor,
    required this.textStyle,
    required this.isThumbnail,
  });

  double _resolveGaugeSpacing(VerticalCalculationResult result) {
    return resolveVerticalGaugeSpacingMm(result).toDouble();
  }

  double _resolveMarksSpacing(HorizontalCalculationResult result) {
    return resolveHorizontalMarksSpacingMm(result).toDouble();
  }

  int _resolveRidgeOffsetForIndex(int index) {
    final details = verticalResult?.rafterDetails;
    if (details != null && index < details.length) {
      return details[index].ridgeOffset;
    }
    return verticalResult?.ridgeOffset ?? 0;
  }

  int _resolveGaugeForIndex(int index) {
    final details = verticalResult?.rafterDetails;
    if (details != null && index < details.length && details[index].gauge > 0) {
      return details[index].gauge;
    }
    return _resolveGaugeSpacing(verticalResult!).round();
  }

  int? _resolveCutCourseForIndex(int index) {
    final details = verticalResult?.rafterDetails;
    if (details != null && index < details.length) {
      return details[index].cutCourse;
    }
    return verticalResult?.cutCourse;
  }

  double _eaveBattenMm(VerticalCalculationResult result) {
    return (result.eaveBatten ?? result.firstBatten).toDouble();
  }

  double _mmFromFascia(double marginOther, double scale, double mm) {
    return marginOther + mm * scale;
  }

  void _drawVerticalBattens({
    required Canvas canvas,
    required Paint battenPaint,
    required TextStyle textStyle,
    required double marginLeft,
    required double marginOther,
    required double rafterSpacing,
    required int totalRafters,
    required int totalCourses,
    required double battenStart,
    required double scale,
    required double defaultGauge,
  }) {
    final columnBattenYs = List<List<double>>.generate(
      totalRafters,
      (column) {
        final gaugeMm = _resolveGaugeForIndex(column);
        final scaledColumnGauge = gaugeMm * scale;
        final ys = <double>[];
        var y = _mmFromFascia(marginOther, scale, battenStart);
        for (var course = 0; course < totalCourses - 1; course++) {
          ys.add(y);
          y += scaledColumnGauge;
        }
        return ys;
      },
    );

    for (var course = 0; course < totalCourses - 1; course++) {
      for (var j = 0; j < totalRafters - 1; j++) {
        final x1 = marginLeft + j * rafterSpacing;
        final x2 = marginLeft + (j + 1) * rafterSpacing;
        canvas.drawLine(
          Offset(x1, columnBattenYs[j][course]),
          Offset(x2, columnBattenYs[j + 1][course]),
          battenPaint,
        );
      }
      if (course == 0) {
        _drawText(
          canvas,
          'Gauge (${defaultGauge.toStringAsFixed(0)} mm)',
          Offset(marginLeft - 100, columnBattenYs[0][course]),
          textStyle,
          angle: -pi / 2,
        );
      }
    }
  }

  /// First gauge batten position from fascia top.
  double _battenStartMm(VerticalCalculationResult result) {
    return gaugeBattenStartMm(
      result,
      materialType: tileMaterialType,
    ).toDouble();
  }

  List<Map<String, dynamic>> _resolveRafterHeights() {
    if (rafterHeights != null && rafterHeights!.isNotEmpty) {
      return ensureMinimumLabeledEntries(
        entries: rafterHeights!,
        minimum: 2,
        labelPrefix: 'Rafter',
        defaultValue: verticalResult?.inputRafter ?? 0,
      );
    }
    if (savedResult != null &&
        (savedResult!.type == CalculationType.vertical ||
            savedResult!.type == CalculationType.combined)) {
      final fromSaved = parseLabeledEntries(
        savedResult!.inputs['vertical_inputs']?['rafterHeights'],
      );
      if (fromSaved.isNotEmpty) {
        return ensureMinimumLabeledEntries(
          entries: fromSaved,
          minimum: 2,
          labelPrefix: 'Rafter',
          defaultValue: verticalResult?.inputRafter ?? 0,
        );
      }
    }
    return ensureMinimumLabeledEntries(
      entries: const [],
      minimum: 2,
      labelPrefix: 'Rafter',
      defaultValue: verticalResult?.inputRafter ?? 0,
    );
  }

  List<Map<String, dynamic>> _resolveWidths() {
    if (widths != null && widths!.isNotEmpty) {
      return ensureMinimumLabeledEntries(
        entries: widths!,
        minimum: 2,
        labelPrefix: 'Width',
        defaultValue: horizontalResult?.width ?? 0,
      );
    }
    if (savedResult != null &&
        (savedResult!.type == CalculationType.horizontal ||
            savedResult!.type == CalculationType.combined)) {
      final fromSaved = parseLabeledEntries(
        savedResult!.inputs['horizontal_inputs']?['widths'],
      );
      if (fromSaved.isNotEmpty) {
        return ensureMinimumLabeledEntries(
          entries: fromSaved,
          minimum: 2,
          labelPrefix: 'Width',
          defaultValue: horizontalResult?.width ?? 0,
        );
      }
    }
    return ensureMinimumLabeledEntries(
      entries: const [],
      minimum: 2,
      labelPrefix: 'Width',
      defaultValue: horizontalResult?.width ?? 0,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double marginLeft = 120.0;
    const double marginOther = 80.0;
    const double labelOffset = 10.0;
    const double minElementSize = 10.0;

    canvasSize = size;
    final double canvasWidth = isThumbnail ? size.width : kVisualizationA3WidthPx;
    final double canvasHeight =
        isThumbnail ? size.height : kVisualizationA3HeightPx;
    final double availableWidth = canvasWidth - marginLeft - marginOther;
    final double availableHeight = canvasHeight - 2 * marginOther;

    if (availableWidth <= 0 || availableHeight <= 0) {
      return;
    }

    final rafterPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = isThumbnail ? 2.5 : 5.0;
    final battenPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.72)
      ..strokeWidth = isThumbnail ? 1.5 : 3.0;
    final markPaint = Paint()
      ..color = accentColor
      ..strokeWidth = isThumbnail ? 1.5 : 3.0;
    final dashedPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.55)
      ..strokeWidth = isThumbnail ? 1.5 : 2.5
      ..style = PaintingStyle.stroke;

    if (verticalResult != null && horizontalResult == null) {
      _paintVerticalOnly(
        canvas: canvas,
        rafterPaint: rafterPaint,
        battenPaint: battenPaint,
        dashedPaint: dashedPaint,
        marginLeft: marginLeft,
        marginOther: marginOther,
        labelOffset: labelOffset,
        minElementSize: minElementSize,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );
    } else if (horizontalResult != null && verticalResult == null) {
      _paintHorizontalOnly(
        canvas: canvas,
        dashedPaint: dashedPaint,
        markPaint: markPaint,
        marginLeft: marginLeft,
        marginOther: marginOther,
        labelOffset: labelOffset,
        minElementSize: minElementSize,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );
    } else if (verticalResult != null && horizontalResult != null) {
      _paintCombined(
        canvas: canvas,
        rafterPaint: rafterPaint,
        battenPaint: battenPaint,
        markPaint: markPaint,
        dashedPaint: dashedPaint,
        marginLeft: marginLeft,
        marginOther: marginOther,
        labelOffset: labelOffset,
        minElementSize: minElementSize,
        availableWidth: availableWidth,
        availableHeight: availableHeight,
      );
    }
  }

  void _paintVerticalOnly({
    required Canvas canvas,
    required Paint rafterPaint,
    required Paint battenPaint,
    required Paint dashedPaint,
    required double marginLeft,
    required double marginOther,
    required double labelOffset,
    required double minElementSize,
    required double availableWidth,
    required double availableHeight,
  }) {
    if (verticalResult!.inputRafter <= 0 || verticalResult!.totalCourses <= 0) {
      return;
    }

    final rafterHeights = _resolveRafterHeights();
    final totalRafters = rafterHeights.length;

    final double inputRafter = verticalResult!.inputRafter.toDouble();
    final double gauge =
        _resolveGaugeSpacing(verticalResult!);
    final int totalCourses = verticalResult!.totalCourses;
    final double battenStart = _battenStartMm(verticalResult!);
    final double eaveBatten = _eaveBattenMm(verticalResult!);
    final double effectiveGutterOverhang = gutterOverhang ?? 0;

    if (gauge <= 0) return;

    final double rafterSpacing = availableWidth / (totalRafters - 1);
    final double totalBattens = totalCourses - 1;
    final double minRequiredHeight = totalBattens * minElementSize;
    final double baseHeightScale = availableHeight / inputRafter;
    final double heightScale =
        max(baseHeightScale, minRequiredHeight / inputRafter);
    final double widthScale =
        availableWidth / (inputRafter * (totalRafters - 1));
    final double scale = min(heightScale, widthScale);

    final double scaledInputRafter = inputRafter * scale;
    final double scaledGutterOverhang = effectiveGutterOverhang * scale;

    for (int i = 0; i < totalRafters; i++) {
      final double x = marginLeft + i * rafterSpacing;
      canvas.drawLine(
        Offset(x, marginOther),
        Offset(x, marginOther + scaledInputRafter),
        rafterPaint,
      );
      final label = rafterHeights[i]['label'] ?? 'Rafter ${i + 1}';
      _drawText(
        canvas,
        label.toString(),
        Offset(x - 20, marginOther + scaledInputRafter + labelOffset),
        textStyle,
      );
    }

    _drawVerticalBattens(
      canvas: canvas,
      battenPaint: battenPaint,
      textStyle: textStyle,
      marginLeft: marginLeft,
      marginOther: marginOther,
      rafterSpacing: rafterSpacing,
      totalRafters: totalRafters,
      totalCourses: totalCourses,
      battenStart: battenStart,
      scale: scale,
      defaultGauge: gauge,
    );

    for (int i = 0; i < totalRafters; i++) {
      final double x = marginLeft + i * rafterSpacing;
      final double scaledRidgeOffset =
          _resolveRidgeOffsetForIndex(i).toDouble() * scale;
      canvas.drawLine(
        Offset(x - 12, marginOther + scaledInputRafter - scaledRidgeOffset),
        Offset(x + 12, marginOther + scaledInputRafter - scaledRidgeOffset),
        dashedPaint,
      );
      if (i == 0) {
        _drawText(
          canvas,
          'Ridge (${_resolveRidgeOffsetForIndex(i)} mm)',
          Offset(marginLeft - 100,
              marginOther + scaledInputRafter - scaledRidgeOffset),
          textStyle,
          angle: -pi / 2,
        );
      }
    }

    canvas.drawLine(
      Offset(marginLeft, marginOther + scaledGutterOverhang),
      Offset(marginLeft + availableWidth, marginOther + scaledGutterOverhang),
      dashedPaint,
    );
    _drawText(
      canvas,
      'Eave (${effectiveGutterOverhang.toStringAsFixed(1)} mm)',
      Offset(marginLeft - 100, marginOther + scaledGutterOverhang),
      textStyle,
      angle: -pi / 2,
    );

    if (shouldShowUnderEaveBatten(
      materialType: tileMaterialType,
      result: verticalResult!,
    )) {
      final underEaveY = _mmFromFascia(
        marginOther,
        scale,
        verticalResult!.underEaveBatten!.toDouble(),
      );
      _drawText(
        canvas,
        'Under Eave (${verticalResult!.underEaveBatten} mm)',
        Offset(marginLeft - 100, underEaveY),
        textStyle,
        angle: -pi / 2,
      );
    }
    if (shouldShowEaveBatten(verticalResult!)) {
      _drawText(
        canvas,
        'Eave Batten (${verticalResult!.eaveBatten} mm)',
        Offset(
          marginLeft - 100,
          _mmFromFascia(marginOther, scale, eaveBatten),
        ),
        textStyle,
        angle: -pi / 2,
      );
    }
    final firstGaugeY = _mmFromFascia(marginOther, scale, battenStart);
    canvas.drawLine(
      Offset(marginLeft, firstGaugeY),
      Offset(marginLeft + availableWidth, firstGaugeY),
      dashedPaint,
    );
    _drawText(
      canvas,
      'First Gauge (${verticalResult!.firstBatten} mm)',
      Offset(marginLeft - 100, firstGaugeY),
      textStyle,
      angle: -pi / 2,
    );
    final cutCourse = _resolveCutCourseForIndex(0);
    if (cutCourse != null && cutCourse > 0) {
      _drawText(
        canvas,
        'Cut Course (above eave, ${cutCourse} mm)',
        Offset(
          marginLeft - 100,
          _mmFromFascia(marginOther, scale, battenStart) - 8,
        ),
        textStyle,
        angle: -pi / 2,
      );
    }
  }

  void _paintHorizontalOnly({
    required Canvas canvas,
    required Paint dashedPaint,
    required Paint markPaint,
    required double marginLeft,
    required double marginOther,
    required double labelOffset,
    required double minElementSize,
    required double availableWidth,
    required double availableHeight,
  }) {
    if (horizontalResult!.width <= 0) return;

    final widths = _resolveWidths();
    final totalWidths = widths.length;

    final double width = horizontalResult!.width.toDouble();
    final double marks = _resolveMarksSpacing(horizontalResult!);
    final double lhOverhang = (horizontalResult!.lhOverhang ?? 0).toDouble();
    final double rhOverhang = (horizontalResult!.rhOverhang ?? 0).toDouble();
    final double firstMark = horizontalResult!.firstMark.toDouble();

    if (marks <= 0) return;

    final double widthHeight = availableHeight / totalWidths;
    final int totalMarks = (width / marks).floor();
    final double minRequiredWidth = totalMarks * minElementSize;
    final double baseScale = availableWidth / width;
    final double scale = max(baseScale, minRequiredWidth / width);

    final double scaledWidth = width * scale;
    final double scaledMarks = marks * scale;
    final double scaledLhOverhang = lhOverhang * scale;
    final double scaledFirstMark = firstMark * scale;

    for (int i = 0; i < totalWidths; i++) {
      final double y = marginOther + i * widthHeight;
      canvas.drawLine(
        Offset(marginLeft + scaledLhOverhang, y),
        Offset(marginLeft + scaledLhOverhang + scaledWidth, y),
        dashedPaint,
      );
      final label = widths[i]['label'] ?? 'Width ${i + 1}';
      _drawText(
        canvas,
        label.toString(),
        Offset(
            marginLeft + scaledLhOverhang + scaledWidth + labelOffset, y),
        textStyle,
      );
    }

    double x = marginLeft + scaledLhOverhang + scaledFirstMark;
    for (int i = 0; i < totalMarks; i++) {
      for (int j = 0; j < totalWidths; j++) {
        final double y = marginOther + j * widthHeight;
        canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), markPaint);
      }
      for (int j = 0; j < totalWidths - 1; j++) {
        final double y1 = marginOther + j * widthHeight;
        final double y2 = marginOther + (j + 1) * widthHeight;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), markPaint);
      }
      if (i == 0) {
        _drawText(
          canvas,
          'First Mark (${firstMark.toStringAsFixed(1)} mm)',
          Offset(x - 40, marginOther + labelOffset),
          textStyle,
        );
      }
      x += scaledMarks;
    }

    if (lhOverhang > 0) {
      _drawText(
        canvas,
        'LH Overhang (${lhOverhang.toStringAsFixed(1)} mm)',
        Offset(marginLeft, marginOther + labelOffset),
        textStyle,
      );
    }
    if (rhOverhang > 0) {
      _drawText(
        canvas,
        'RH Overhang (${rhOverhang.toStringAsFixed(1)} mm)',
        Offset(marginLeft + scaledLhOverhang + scaledWidth - 60,
            marginOther + labelOffset),
        textStyle,
      );
    }
    if (horizontalResult!.cutTile != null) {
      _drawText(
        canvas,
        'Cut Tile (${horizontalResult!.cutTile!.toStringAsFixed(1)} mm)',
        Offset(marginLeft + scaledLhOverhang + scaledWidth / 2,
            marginOther + labelOffset),
        textStyle,
      );
    }
    if (horizontalResult!.actualSpacing != null) {
      _drawText(
        canvas,
        'Actual Spacing (${horizontalResult!.actualSpacing!.toStringAsFixed(1)} mm)',
        Offset(marginLeft + scaledLhOverhang + scaledWidth / 4,
            marginOther + labelOffset),
        textStyle,
      );
    }
  }

  void _paintCombined({
    required Canvas canvas,
    required Paint rafterPaint,
    required Paint battenPaint,
    required Paint markPaint,
    required Paint dashedPaint,
    required double marginLeft,
    required double marginOther,
    required double labelOffset,
    required double minElementSize,
    required double availableWidth,
    required double availableHeight,
  }) {
    if (verticalResult!.inputRafter <= 0 || horizontalResult!.width <= 0) {
      return;
    }

    final rafterHeights = _resolveRafterHeights();
    final widths = _resolveWidths();
    final totalRafters = rafterHeights.length;
    final totalWidths = widths.length;

    final double inputRafter = verticalResult!.inputRafter.toDouble();
    final double gauge =
        _resolveGaugeSpacing(verticalResult!);
    final int totalCourses = verticalResult!.totalCourses;
    final double battenStart = _battenStartMm(verticalResult!);
    final double effectiveGutterOverhang = gutterOverhang ?? 0;

    final double width = horizontalResult!.width.toDouble();
    final double marks = _resolveMarksSpacing(horizontalResult!);
    final double lhOverhang = (horizontalResult!.lhOverhang ?? 0).toDouble();
    final double firstMark = horizontalResult!.firstMark.toDouble();

    if (gauge <= 0 || marks <= 0) return;

    final double rafterSpacing = availableWidth / (totalRafters - 1);
    final double widthHeight = availableHeight / totalWidths;

    final double totalBattens = totalCourses - 1;
    final int totalMarks = (width / marks).floor();
    final double minRequiredHeight = totalBattens * minElementSize;
    final double minRequiredWidth = totalMarks * minElementSize;
    final double heightScale = availableHeight / inputRafter;
    final double widthScale = availableWidth / width;
    final double baseScaleFactor = min(heightScale, widthScale);
    final double scaleFactor = max(
      baseScaleFactor,
      max(minRequiredHeight / inputRafter, minRequiredWidth / width),
    );

    final double scaledInputRafter = inputRafter * scaleFactor;
    final double scaledGutterOverhang = effectiveGutterOverhang * scaleFactor;
    final double scaledWidth = width * scaleFactor;
    final double scaledMarks = marks * scaleFactor;
    final double scaledLhOverhang = lhOverhang * scaleFactor;
    final double scaledFirstMark = firstMark * scaleFactor;

    for (int i = 0; i < totalRafters; i++) {
      final double x = marginLeft + i * rafterSpacing;
      canvas.drawLine(
        Offset(x, marginOther),
        Offset(x, marginOther + scaledInputRafter),
        rafterPaint,
      );
      final label = rafterHeights[i]['label'] ?? 'Rafter ${i + 1}';
      _drawText(
        canvas,
        label.toString(),
        Offset(x - 20, marginOther + scaledInputRafter + labelOffset),
        textStyle,
      );
    }

    for (int i = 0; i < totalWidths; i++) {
      final double y = marginOther + i * widthHeight;
      canvas.drawLine(
        Offset(marginLeft + scaledLhOverhang, y),
        Offset(marginLeft + scaledLhOverhang + scaledWidth, y),
        dashedPaint,
      );
      final label = widths[i]['label'] ?? 'Width ${i + 1}';
      _drawText(
        canvas,
        label.toString(),
        Offset(marginLeft + scaledLhOverhang + scaledWidth + labelOffset, y),
        textStyle,
      );
    }

    _drawVerticalBattens(
      canvas: canvas,
      battenPaint: battenPaint,
      textStyle: textStyle,
      marginLeft: marginLeft,
      marginOther: marginOther,
      rafterSpacing: rafterSpacing,
      totalRafters: totalRafters,
      totalCourses: totalCourses,
      battenStart: battenStart,
      scale: scaleFactor,
      defaultGauge: gauge,
    );

    double x = marginLeft + scaledLhOverhang + scaledFirstMark;
    for (int i = 0; i < totalMarks; i++) {
      for (int j = 0; j < totalWidths; j++) {
        final double markY = marginOther + j * widthHeight;
        canvas.drawLine(
            Offset(x, markY - 5), Offset(x, markY + 5), markPaint);
      }
      for (int j = 0; j < totalWidths - 1; j++) {
        final double y1 = marginOther + j * widthHeight;
        final double y2 = marginOther + (j + 1) * widthHeight;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), markPaint);
      }
      x += scaledMarks;
    }

    for (int i = 0; i < totalRafters; i++) {
      final double rafterX = marginLeft + i * rafterSpacing;
      final double scaledRidgeOffset =
          _resolveRidgeOffsetForIndex(i).toDouble() * scaleFactor;
      canvas.drawLine(
        Offset(rafterX - 12, marginOther + scaledInputRafter - scaledRidgeOffset),
        Offset(rafterX + 12, marginOther + scaledInputRafter - scaledRidgeOffset),
        dashedPaint,
      );
      if (i == 0) {
        _drawText(
          canvas,
          'Ridge (${_resolveRidgeOffsetForIndex(i)} mm)',
          Offset(marginLeft - 100,
              marginOther + scaledInputRafter - scaledRidgeOffset),
          textStyle,
          angle: -pi / 2,
        );
      }
    }

    canvas.drawLine(
      Offset(marginLeft, marginOther + scaledGutterOverhang),
      Offset(marginLeft + scaledLhOverhang + scaledWidth,
          marginOther + scaledGutterOverhang),
      dashedPaint,
    );
    _drawText(
      canvas,
      'Eave (${effectiveGutterOverhang.toStringAsFixed(1)} mm)',
      Offset(marginLeft - 100, marginOther + scaledGutterOverhang),
      textStyle,
      angle: -pi / 2,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    TextStyle style, {
    double angle = 0,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    double adjustedWidth = textPainter.width;
    double adjustedHeight = textPainter.height;
    if (angle != 0) {
      adjustedWidth = textPainter.height;
      adjustedHeight = textPainter.width;
    }

    if (position.dx + adjustedWidth > canvasSize.width ||
        position.dy + adjustedHeight > canvasSize.height ||
        position.dx < 0 ||
        position.dy < 0) {
      return;
    }

    canvas.save();
    canvas.translate(position.dx, position.dy);
    if (angle != 0) {
      canvas.rotate(angle);
    }
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  late Size canvasSize;

  @override
  bool shouldRepaint(covariant RoofPainter oldDelegate) {
    return oldDelegate.verticalResult != verticalResult ||
        oldDelegate.horizontalResult != horizontalResult ||
        oldDelegate.gutterOverhang != gutterOverhang ||
        oldDelegate.savedResult != savedResult ||
        oldDelegate.rafterHeights != rafterHeights ||
        oldDelegate.widths != widths ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isThumbnail != isThumbnail;
  }
}