import 'package:flutter/material.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'dart:math';

class ResultVisualization extends StatelessWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final SavedResult? savedResult;
  final double? gutterOverhang;
  final bool isThumbnail; // New parameter to adjust for thumbnail view

  const ResultVisualization({
    super.key,
    this.verticalResult,
    this.horizontalResult,
    this.savedResult,
    this.gutterOverhang,
    this.isThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extract vertical and horizontal results from savedResult if provided
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

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: CustomPaint(
        painter: RoofPainter(
          verticalResult: effectiveVerticalResult,
          horizontalResult: effectiveHorizontalResult,
          savedResult: savedResult,
          gutterOverhang: gutterOverhang,
          primaryColor: Theme.of(context).colorScheme.primary,
          textStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontSize: isThumbnail ? 12 : 16, // Adjust font size
                color: Colors.black,
              ),
          isThumbnail: isThumbnail,
        ),
        child: Container(),
      ),
    );
  }
}

class RoofPainter extends CustomPainter {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final SavedResult? savedResult;
  final double? gutterOverhang;
  final Color primaryColor;
  final TextStyle textStyle;
  final bool isThumbnail;

  RoofPainter({
    required this.verticalResult,
    required this.horizontalResult,
    this.savedResult,
    this.gutterOverhang,
    required this.primaryColor,
    required this.textStyle,
    required this.isThumbnail,
  });

  // Helper to parse gauge or marks strings (e.g., "30 @ 190" -> 190.0)
  double parseMeasurement(String? measurement) {
    if (measurement == null) return 0.0;
    final parts = measurement.split('@');
    if (parts.length < 2) {
      return double.tryParse(measurement) ?? 0.0;
    }
    final valuePart = parts[1].trim();
    final numericPart =
        valuePart.contains('mm') ? valuePart.split('mm')[0].trim() : valuePart;
    final parsedValue = double.tryParse(numericPart);
    debugPrint('Parsed measurement: "$measurement" -> $parsedValue');
    return parsedValue ?? 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double marginLeft = 120.0; // Increased for left-side labels
    const double marginOther = 80.0; // Top, right, bottom
    const double labelOffset = 10.0;
    const double minElementSize = 10.0;
    const double a3WidthPx = 842; // A3 width in pixels at 72 DPI
    const double a3HeightPx = 1191; // A3 height in pixels at 72 DPI

    // Set canvas size
    canvasSize = size;
    final double canvasWidth = isThumbnail ? size.width : a3WidthPx;
    final double canvasHeight = isThumbnail ? size.height : a3HeightPx;
    final double availableWidth = canvasWidth - marginLeft - marginOther;
    final double availableHeight = canvasHeight - 2 * marginOther;

    debugPrint(
        'Canvas size: width=$canvasWidth, height=$canvasHeight, availableWidth=$availableWidth, availableHeight=$availableHeight');

    if (availableWidth <= 0 || availableHeight <= 0) {
      debugPrint('Skipping drawing due to insufficient space');
      return;
    }

    // Paint styles
    final rafterPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.0;
    final battenPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;
    final markPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0;
    final dashedPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Extract inputs for rafters and widths from savedResult
    List<Map<String, dynamic>> rafterHeights = [];
    List<Map<String, dynamic>> widths = [];
    if (savedResult != null) {
      if (savedResult!.type == CalculationType.vertical ||
          savedResult!.type == CalculationType.combined) {
        rafterHeights = List<Map<String, dynamic>>.from(
            savedResult!.inputs['vertical_inputs']?['rafterHeights'] ?? []);
      }
      if (savedResult!.type == CalculationType.horizontal ||
          savedResult!.type == CalculationType.combined) {
        widths = List<Map<String, dynamic>>.from(
            savedResult!.inputs['horizontal_inputs']?['widths'] ?? []);
      }
    }

    // Handle Vertical-only view
    if (verticalResult != null && horizontalResult == null) {
      if (verticalResult!.inputRafter <= 0 ||
          verticalResult!.totalCourses <= 0) {
        debugPrint(
            'Skipping Vertical drawing: invalid inputRafter or totalCourses');
        return;
      }

      // Use ghost rafter if only one rafter
      int totalRafters = rafterHeights.length;
      if (totalRafters <= 1) {
        totalRafters = 2; // Add ghost rafter
        if (rafterHeights.isEmpty) {
          rafterHeights = [
            {'label': 'Rafter 1', 'value': verticalResult!.inputRafter},
            {'label': 'Rafter 2', 'value': verticalResult!.inputRafter},
          ];
        }
      }

      final double inputRafter = verticalResult!.inputRafter.toDouble();
      final double gauge =
          parseMeasurement(verticalResult!.splitGauge ?? verticalResult!.gauge);
      final int totalCourses = verticalResult!.totalCourses;
      final double firstBatten = verticalResult!.firstBatten.toDouble();
      final double ridgeOffset = verticalResult!.ridgeOffset.toDouble();
      final double effectiveGutterOverhang = gutterOverhang ?? 0;

      if (gauge <= 0) return;

      // Calculate rafter spacing
      final double rafterSpacing = availableWidth / (totalRafters - 1);

      // Adjust scale to ensure battens are visible and proportional
      final double totalBattens = totalCourses - 1;
      final double minHeightPerBatten = minElementSize;
      final double minRequiredHeight = totalBattens * minHeightPerBatten;
      final double baseHeightScale = availableHeight / inputRafter;
      final double heightScale =
          max(baseHeightScale, minRequiredHeight / inputRafter);
      final double widthScale =
          availableWidth / (inputRafter * (totalRafters - 1));
      final double scale = min(heightScale, widthScale);

      final double scaledInputRafter = inputRafter * scale;
      final double scaledGauge = gauge * scale;
      final double scaledFirstBatten = firstBatten * scale;
      final double scaledRidgeOffset = ridgeOffset * scale;
      final double scaledGutterOverhang = effectiveGutterOverhang * scale;

      // Draw rafters
      for (int i = 0; i < totalRafters; i++) {
        final double x = marginLeft + i * rafterSpacing;
        canvas.drawLine(
          Offset(x, marginOther),
          Offset(x, marginOther + scaledInputRafter),
          rafterPaint,
        );
        // Label rafters at the bottom
        final label = rafterHeights[i]['label'] ?? 'Rafter ${i + 1}';
        _drawText(
            canvas,
            label,
            Offset(x - 20, marginOther + scaledInputRafter + labelOffset),
            textStyle);
      }

      // Draw battens between rafters
      double y = marginOther + scaledGutterOverhang + scaledFirstBatten;
      for (int i = 0; i < totalCourses - 1; i++) {
        for (int j = 0; j < totalRafters - 1; j++) {
          final double x1 = marginLeft + j * rafterSpacing;
          final double x2 = marginLeft + (j + 1) * rafterSpacing;
          canvas.drawLine(
            Offset(x1, y),
            Offset(x2, y),
            battenPaint,
          );
        }
        // Label batten on the left
        _drawText(
            canvas, 'Batten ${i + 1}', Offset(marginLeft - 100, y), textStyle,
            angle: -pi / 2);
        y += scaledGauge;
      }

      // Draw ridge and eave
      canvas.drawLine(
        Offset(marginLeft, marginOther + scaledInputRafter - scaledRidgeOffset),
        Offset(marginLeft + availableWidth,
            marginOther + scaledInputRafter - scaledRidgeOffset),
        dashedPaint,
      );
      _drawText(
          canvas,
          'Ridge (${ridgeOffset.toStringAsFixed(1)} mm)',
          Offset(marginLeft - 100,
              marginOther + scaledInputRafter - scaledRidgeOffset),
          textStyle,
          angle: -pi / 2);

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
          angle: -pi / 2);

      // Additional labels for vertical results
      if (verticalResult!.underEaveBatten != null) {
        _drawText(
            canvas,
            'Under Eave (${verticalResult!.underEaveBatten!.toStringAsFixed(1)} mm)',
            Offset(marginLeft - 100,
                marginOther + scaledGutterOverhang + scaledFirstBatten / 2),
            textStyle,
            angle: -pi / 2);
      }
      if (verticalResult!.eaveBatten != null) {
        _drawText(
            canvas,
            'Eave Batten (${verticalResult!.eaveBatten!.toStringAsFixed(1)} mm)',
            Offset(marginLeft - 100,
                marginOther + scaledGutterOverhang + scaledFirstBatten / 4),
            textStyle,
            angle: -pi / 2);
      }
      if (verticalResult!.cutCourse != null) {
        _drawText(
            canvas,
            'Cut Course (${verticalResult!.cutCourse!.toStringAsFixed(1)} mm)',
            Offset(marginLeft - 100,
                marginOther + scaledInputRafter - scaledRidgeOffset / 2),
            textStyle,
            angle: -pi / 2);
      }
    }
    // Handle Horizontal-only view
    else if (horizontalResult != null && verticalResult == null) {
      if (horizontalResult!.width <= 0) return;

      // Use ghost width if only one width
      int totalWidths = widths.length;
      if (totalWidths <= 1) {
        totalWidths = 2; // Add ghost width
        if (widths.isEmpty) {
          widths = [
            {'label': 'Width 1', 'value': horizontalResult!.width},
            {'label': 'Width 2', 'value': horizontalResult!.width},
          ];
        }
      }

      final double width = horizontalResult!.width.toDouble();
      final double marks = parseMeasurement(
          horizontalResult!.splitMarks ?? horizontalResult!.marks);
      final double lhOverhang = (horizontalResult!.lhOverhang ?? 0).toDouble();
      final double rhOverhang = (horizontalResult!.rhOverhang ?? 0).toDouble();
      final double firstMark = horizontalResult!.firstMark.toDouble();

      if (marks <= 0) return;

      final double widthHeight = availableHeight / totalWidths;

      // Calculate scale for marks
      final int totalMarks = (width / marks).floor();
      final double minWidthPerMark = minElementSize;
      final double minRequiredWidth = totalMarks * minWidthPerMark;
      final double baseScale = availableWidth / width;
      final double scale = max(baseScale, minRequiredWidth / width);

      final double scaledWidth = width * scale;
      final double scaledMarks = marks * scale;
      final double scaledLhOverhang = lhOverhang * scale;
      final double scaledRhOverhang = rhOverhang * scale;
      final double scaledFirstMark = firstMark * scale;

      // Draw width sections
      for (int i = 0; i < totalWidths; i++) {
        final double y = marginOther + i * widthHeight;
        canvas.drawLine(
          Offset(marginLeft + scaledLhOverhang, y),
          Offset(marginLeft + scaledLhOverhang + scaledWidth, y),
          dashedPaint,
        );
        // Label width on the right
        final label = widths[i]['label'] ?? 'Width ${i + 1}';
        _drawText(
            canvas,
            label,
            Offset(
                marginLeft + scaledLhOverhang + scaledWidth + labelOffset, y),
            textStyle);
      }

      // Draw marks and connect across widths
      double x = marginLeft + scaledLhOverhang + scaledFirstMark;
      for (int i = 0; i < totalMarks; i++) {
        for (int j = 0; j < totalWidths; j++) {
          final double y = marginOther + j * widthHeight;
          canvas.drawLine(
            Offset(x, y - 5),
            Offset(x, y + 5),
            markPaint,
          );
        }
        // Connect marks across widths
        for (int j = 0; j < totalWidths - 1; j++) {
          final double y1 = marginOther + j * widthHeight;
          final double y2 = marginOther + (j + 1) * widthHeight;
          canvas.drawLine(
            Offset(x, y1),
            Offset(x, y2),
            markPaint,
          );
        }
        // Label first mark
        if (i == 0) {
          _drawText(canvas, 'First Mark (${firstMark.toStringAsFixed(1)} mm)',
              Offset(x - 40, marginOther + labelOffset), textStyle);
        }
        x += scaledMarks;
      }

      // Additional labels for horizontal results
      if (lhOverhang > 0) {
        _drawText(canvas, 'LH Overhang (${lhOverhang.toStringAsFixed(1)} mm)',
            Offset(marginLeft, marginOther + labelOffset), textStyle);
      }
      if (rhOverhang > 0) {
        _drawText(
            canvas,
            'RH Overhang (${rhOverhang.toStringAsFixed(1)} mm)',
            Offset(marginLeft + scaledLhOverhang + scaledWidth - 60,
                marginOther + labelOffset),
            textStyle);
      }
      if (horizontalResult!.cutTile != null) {
        _drawText(
            canvas,
            'Cut Tile (${horizontalResult!.cutTile!.toStringAsFixed(1)} mm)',
            Offset(marginLeft + scaledLhOverhang + scaledWidth / 2,
                marginOther + labelOffset),
            textStyle);
      }
      if (horizontalResult!.actualSpacing != null) {
        _drawText(
            canvas,
            'Actual Spacing (${horizontalResult!.actualSpacing!.toStringAsFixed(1)} mm)',
            Offset(marginLeft + scaledLhOverhang + scaledWidth / 4,
                marginOther + labelOffset),
            textStyle);
      }
    }
    // Handle Combined view
    else if (verticalResult != null && horizontalResult != null) {
      if (verticalResult!.inputRafter <= 0 || horizontalResult!.width <= 0)
        return;

      // Extract data
      final double inputRafter = verticalResult!.inputRafter.toDouble();
      final double gauge =
          parseMeasurement(verticalResult!.splitGauge ?? verticalResult!.gauge);
      final int totalCourses = verticalResult!.totalCourses;
      final double firstBatten = verticalResult!.firstBatten.toDouble();
      final double ridgeOffset = verticalResult!.ridgeOffset.toDouble();
      final double effectiveGutterOverhang = gutterOverhang ?? 0;

      final double width = horizontalResult!.width.toDouble();
      final double marks = parseMeasurement(
          horizontalResult!.splitMarks ?? horizontalResult!.marks);
      final double lhOverhang = (horizontalResult!.lhOverhang ?? 0).toDouble();
      final double firstMark = horizontalResult!.firstMark.toDouble();

      if (gauge <= 0 || marks <= 0) return;

      // Determine number of rafters and widths
      int totalRafters = rafterHeights.length;
      if (totalRafters <= 1) {
        totalRafters = 2;
        if (rafterHeights.isEmpty) {
          rafterHeights = [
            {'label': 'Rafter 1', 'value': verticalResult!.inputRafter},
            {'label': 'Rafter 2', 'value': verticalResult!.inputRafter},
          ];
        }
      }

      int totalWidths = widths.length;
      if (totalWidths <= 1) {
        totalWidths = 2;
        if (widths.isEmpty) {
          widths = [
            {'label': 'Width 1', 'value': horizontalResult!.width},
            {'label': 'Width 2', 'value': horizontalResult!.width},
          ];
        }
      }

      // Calculate spacing
      final double rafterSpacing = availableWidth / (totalRafters - 1);
      final double widthHeight = availableHeight / totalWidths;

      // Calculate scale
      final double totalBattens = totalCourses - 1;
      final int totalMarks = (width / marks).floor();
      final double minHeightPerBatten = minElementSize;
      final double minWidthPerMark = minElementSize;
      final double minRequiredHeight = totalBattens * minHeightPerBatten;
      final double minRequiredWidth = totalMarks * minWidthPerMark;
      final double heightScale = availableHeight / inputRafter;
      final double widthScale = availableWidth / width;
      final double baseScaleFactor = min(heightScale, widthScale);
      final double scaleFactor = max(baseScaleFactor,
          max(minRequiredHeight / inputRafter, minRequiredWidth / width));

      final double scaledInputRafter = inputRafter * scaleFactor;
      final double scaledGauge = gauge * scaleFactor;
      final double scaledFirstBatten = firstBatten * scaleFactor;
      final double scaledRidgeOffset = ridgeOffset * scaleFactor;
      final double scaledGutterOverhang = effectiveGutterOverhang * scaleFactor;

      final double scaledWidth = width * scaleFactor;
      final double scaledMarks = marks * scaleFactor;
      final double scaledLhOverhang = lhOverhang * scaleFactor;
      final double scaledFirstMark = firstMark * scaleFactor;

      // Draw rafters
      for (int i = 0; i < totalRafters; i++) {
        final double x = marginLeft + i * rafterSpacing;
        canvas.drawLine(
          Offset(x, marginOther),
          Offset(x, marginOther + scaledInputRafter),
          rafterPaint,
        );
        // Label rafters at the bottom
        final label = rafterHeights[i]['label'] ?? 'Rafter ${i + 1}';
        _drawText(
            canvas,
            label,
            Offset(x - 20, marginOther + scaledInputRafter + labelOffset),
            textStyle);
      }

      // Draw width sections
      for (int i = 0; i < totalWidths; i++) {
        final double y = marginOther + i * widthHeight;
        canvas.drawLine(
          Offset(marginLeft, y),
          Offset(marginLeft + availableWidth, y),
          dashedPaint,
        );
        // Label width on the right
        final label = widths[i]['label'] ?? 'Width ${i + 1}';
        _drawText(canvas, label,
            Offset(marginLeft + availableWidth + labelOffset, y), textStyle);
      }

      // Draw battens between consecutive rafters
      double y = marginOther + scaledGutterOverhang + scaledFirstBatten;
      for (int i = 0; i < totalCourses - 1; i++) {
        for (int j = 0; j < totalRafters - 1; j++) {
          final double x1 = marginLeft + j * rafterSpacing;
          final double x2 = marginLeft + (j + 1) * rafterSpacing;
          canvas.drawLine(
            Offset(x1, y),
            Offset(x2, y),
            battenPaint,
          );
        }
        // Label batten on the left
        _drawText(
            canvas, 'Batten ${i + 1}', Offset(marginLeft - 100, y), textStyle,
            angle: -pi / 2);
        y += scaledGauge;
      }

      // Draw marks and connect across widths
      double x = marginLeft + scaledLhOverhang + scaledFirstMark;
      for (int i = 0; i < totalMarks; i++) {
        for (int j = 0; j < totalWidths; j++) {
          final double y = marginOther + j * widthHeight;
          canvas.drawLine(
            Offset(x, y - 5),
            Offset(x, y + 5),
            markPaint,
          );
        }
        // Connect marks across widths
        for (int j = 0; j < totalWidths - 1; j++) {
          final double y1 = marginOther + j * widthHeight;
          final double y2 = marginOther + (j + 1) * widthHeight;
          canvas.drawLine(
            Offset(x, y1),
            Offset(x, y2),
            markPaint,
          );
        }
        x += scaledMarks;
      }

      // Draw ridge and eave
      canvas.drawLine(
        Offset(marginLeft, marginOther + scaledInputRafter - scaledRidgeOffset),
        Offset(marginLeft + availableWidth,
            marginOther + scaledInputRafter - scaledRidgeOffset),
        dashedPaint,
      );
      _drawText(
          canvas,
          'Ridge (${ridgeOffset.toStringAsFixed(1)} mm)',
          Offset(marginLeft - 100,
              marginOther + scaledInputRafter - scaledRidgeOffset),
          textStyle,
          angle: -pi / 2);

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
          angle: -pi / 2);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, TextStyle style,
      {double angle = 0}) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Adjust overflow check to account for rotation
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
      debugPrint(
          'Skipping text drawing due to overflow: text=$text, position=$position');
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
        oldDelegate.isThumbnail != isThumbnail;
  }
}
