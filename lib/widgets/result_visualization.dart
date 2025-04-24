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

  const ResultVisualization({
    super.key,
    this.verticalResult,
    this.horizontalResult,
    this.savedResult,
    this.gutterOverhang,
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
      color: Colors.white, // White background for clarity
      padding: const EdgeInsets.all(16.0),
      child: CustomPaint(
        painter: RoofPainter(
          verticalResult: effectiveVerticalResult,
          horizontalResult: effectiveHorizontalResult,
          gutterOverhang: gutterOverhang,
          primaryColor: Theme.of(context).colorScheme.primary,
          textStyle:
              Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 14),
        ),
        child: Container(),
      ),
    );
  }
}

class RoofPainter extends CustomPainter {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double? gutterOverhang;
  final Color primaryColor;
  final TextStyle textStyle;

  RoofPainter({
    required this.verticalResult,
    required this.horizontalResult,
    this.gutterOverhang,
    required this.primaryColor,
    required this.textStyle,
  });

  // Helper method to parse gauge or marks strings (e.g., "30 @ 190" -> 190.0)
  double parseMeasurement(String? measurement) {
    if (measurement == null) return 0.0;
    // Split the string by "@" and take the part after it
    final parts = measurement.split('@');
    if (parts.length < 2) {
      // Try parsing the whole string as a fallback
      return double.tryParse(measurement) ?? 0.0;
    }
    // Extract the numeric value (trim any units like "mm" if present)
    final valuePart = parts[1].trim();
    // Remove "mm" if present, otherwise use the trimmed value
    final numericPart =
        valuePart.contains('mm') ? valuePart.split('mm')[0].trim() : valuePart;
    final parsedValue = double.tryParse(numericPart);
    debugPrint('Parsed measurement: "$measurement" -> $parsedValue');
    return parsedValue ?? 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const double margin = 40.0; // Margin for labels
    const double labelOffset = 10.0;
    const double minElementSize =
        10.0; // Minimum size for battens/marks to be visible

    // Calculate available drawing area
    final double availableWidth = size.width - 2 * margin;
    final double availableHeight = size.height - 2 * margin;

    debugPrint(
        'Available drawing area: width=$availableWidth, height=$availableHeight');

    if (availableWidth <= 0 || availableHeight <= 0) {
      debugPrint('Skipping drawing due to insufficient space');
      return; // Skip drawing if there's no space
    }

    // Paint for lines and shapes
    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 4.0;
    final dashedPaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final tilePaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final tileBorderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw Vertical-only view
    if (verticalResult != null && horizontalResult == null) {
      if (verticalResult!.inputRafter <= 0 ||
          verticalResult!.totalCourses <= 0) {
        debugPrint(
            'Skipping Vertical drawing: invalid inputRafter=${verticalResult!.inputRafter} or totalCourses=${verticalResult!.totalCourses}');
        return;
      }

      final double inputRafter = verticalResult!.inputRafter.toDouble();
      final double gauge =
          parseMeasurement(verticalResult!.splitGauge ?? verticalResult!.gauge);
      final int totalCourses = verticalResult!.totalCourses;
      final double firstBatten = verticalResult!.firstBatten.toDouble();
      final double ridgeOffset = verticalResult!.ridgeOffset.toDouble();
      final double effectiveGutterOverhang = gutterOverhang ?? 0;

      if (gauge <= 0) {
        debugPrint('Skipping Vertical drawing: invalid gauge=$gauge');
        return;
      }

      // Calculate scale based on the number of battens to ensure visibility
      final double totalBattens =
          totalCourses - 1; // Number of battens between courses
      final double minHeightPerBatten =
          minElementSize; // Minimum height for each batten
      final double minRequiredHeight = totalBattens * minHeightPerBatten;
      final double baseScale = availableHeight / inputRafter;
      // Scale to ensure each batten is at least minElementSize
      final double scale = max(baseScale, minRequiredHeight / inputRafter);

      final double scaledInputRafter = inputRafter * scale;
      final double scaledGauge = gauge * scale;
      final double scaledFirstBatten = firstBatten * scale;
      final double scaledRidgeOffset = ridgeOffset * scale;
      final double scaledGutterOverhang = effectiveGutterOverhang * scale;

      debugPrint(
          'Vertical Drawing: scale=$scale, scaledInputRafter=$scaledInputRafter, scaledGauge=$scaledGauge, scaledFirstBatten=$scaledFirstBatten');

      // Draw rafter line (vertical)
      canvas.drawLine(
        Offset(margin, margin),
        Offset(margin, margin + scaledInputRafter),
        linePaint,
      );

      // Draw battens
      double y = margin + scaledGutterOverhang + scaledFirstBatten;
      for (int i = 0; i < totalCourses - 1; i++) {
        canvas.drawLine(
          Offset(margin - 10, y),
          Offset(margin + 10, y),
          linePaint,
        );

        // Label batten position
        _drawText(canvas, 'Batten ${i + 1}',
            Offset(margin + 20, y - labelOffset), textStyle);
        y += scaledGauge;
      }

      // Draw ridge
      canvas.drawLine(
        Offset(margin - 10, margin + scaledInputRafter - scaledRidgeOffset),
        Offset(margin + 10, margin + scaledInputRafter - scaledRidgeOffset),
        linePaint,
      );
      _drawText(
          canvas,
          'Ridge (${ridgeOffset.toStringAsFixed(1)} mm)',
          Offset(margin + 20,
              margin + scaledInputRafter - scaledRidgeOffset - labelOffset),
          textStyle);

      // Draw eave
      canvas.drawLine(
        Offset(margin - 10, margin + scaledGutterOverhang),
        Offset(margin + 10, margin + scaledGutterOverhang),
        linePaint,
      );
      _drawText(
          canvas,
          'Eave (${effectiveGutterOverhang.toStringAsFixed(1)} mm)',
          Offset(margin + 20, margin + scaledGutterOverhang - labelOffset),
          textStyle);

      // Draw first batten label
      _drawText(
          canvas,
          'First Batten (${verticalResult!.firstBatten.toStringAsFixed(1)} mm)',
          Offset(margin + 20,
              margin + scaledGutterOverhang + scaledFirstBatten - labelOffset),
          textStyle);
    }
    // Draw Horizontal-only view
    else if (horizontalResult != null && verticalResult == null) {
      if (horizontalResult!.width <= 0) {
        debugPrint(
            'Skipping Horizontal drawing: invalid width=${horizontalResult!.width}');
        return;
      }

      final double width = horizontalResult!.width.toDouble();
      final double marks = parseMeasurement(
          horizontalResult!.splitMarks ?? horizontalResult!.marks);
      final double lhOverhang = (horizontalResult!.lhOverhang ?? 0).toDouble();
      final double rhOverhang = (horizontalResult!.rhOverhang ?? 0).toDouble();
      final double firstMark = horizontalResult!.firstMark.toDouble();

      if (marks <= 0) {
        debugPrint('Skipping Horizontal drawing: invalid marks=$marks');
        return;
      }

      // Calculate scale based on the number of marks to ensure visibility
      final int totalMarks = (width / marks).floor();
      final double minWidthPerMark =
          minElementSize; // Minimum width for each mark
      final double minRequiredWidth = totalMarks * minWidthPerMark;
      final double baseScale = availableWidth / width;
      final double scale = max(baseScale, minRequiredWidth / width);

      final double scaledWidth = width * scale;
      final double scaledMarks = marks * scale;
      final double scaledLhOverhang = lhOverhang * scale;
      final double scaledRhOverhang = rhOverhang * scale;
      final double scaledFirstMark = firstMark * scale;

      debugPrint(
          'Horizontal Drawing: scale=$scale, scaledWidth=$scaledWidth, scaledMarks=$scaledMarks');

      // Draw width line (horizontal)
      canvas.drawLine(
        Offset(margin + scaledLhOverhang, margin),
        Offset(margin + scaledLhOverhang + scaledWidth, margin),
        linePaint,
      );

      // Draw tile marks
      double x = margin + scaledLhOverhang + scaledFirstMark;
      for (int i = 0; i < totalMarks; i++) {
        canvas.drawLine(
          Offset(x, margin - 10),
          Offset(x, margin + 10),
          linePaint,
        );

        // Label mark position
        _drawText(canvas, 'Mark ${i + 1}', Offset(x - 20, margin + labelOffset),
            textStyle);
        x += scaledMarks;
      }

      // Draw left and right overhangs
      if (lhOverhang > 0) {
        _drawText(canvas, 'LH Overhang (${lhOverhang.toStringAsFixed(1)} mm)',
            Offset(margin, margin + labelOffset), textStyle);
      }
      if (rhOverhang > 0) {
        _drawText(
            canvas,
            'RH Overhang (${rhOverhang.toStringAsFixed(1)} mm)',
            Offset(margin + scaledLhOverhang + scaledWidth - 60,
                margin + labelOffset),
            textStyle);
      }

      // Draw first mark label
      _drawText(
          canvas,
          'First Mark (${horizontalResult!.firstMark.toStringAsFixed(1)} mm)',
          Offset(margin + scaledLhOverhang + scaledFirstMark - 40,
              margin + labelOffset),
          textStyle);
    }
    // Draw Combined view
    else if (verticalResult != null && horizontalResult != null) {
      if (verticalResult!.inputRafter <= 0 || horizontalResult!.width <= 0) {
        debugPrint(
            'Skipping Combined drawing: invalid inputRafter=${verticalResult!.inputRafter} or width=${horizontalResult!.width}');
        return;
      }

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

      if (gauge <= 0 || marks <= 0) {
        debugPrint(
            'Skipping Combined drawing: invalid gauge=$gauge or marks=$marks');
        return;
      }

      // Calculate scale based on the number of elements for both dimensions
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

      debugPrint(
          'Combined Drawing: scaleFactor=$scaleFactor, scaledInputRafter=$scaledInputRafter, scaledWidth=$scaledWidth');

      // Draw grid
      double y = margin + scaledGutterOverhang + scaledFirstBatten;
      final int totalVertical = totalCourses - 1;
      for (int i = 0; i < totalVertical; i++) {
        double x = margin + scaledLhOverhang + scaledFirstMark;
        for (int j = 0; j < totalMarks; j++) {
          // Draw tile rectangle
          final rect =
              Rect.fromLTWH(x, y - scaledGauge, scaledMarks, scaledGauge);
          canvas.drawRect(rect, tilePaint);
          canvas.drawRect(rect, tileBorderPaint);
          x += scaledMarks;
        }
        y += scaledGauge;
      }

      // Draw axes and labels
      // Vertical axis (Y-axis)
      canvas.drawLine(
        Offset(margin, margin),
        Offset(margin, margin + scaledInputRafter),
        linePaint,
      );
      _drawText(
          canvas,
          'Eave (${effectiveGutterOverhang.toStringAsFixed(1)} mm)',
          Offset(margin - 30, margin + scaledGutterOverhang),
          textStyle,
          angle: -pi / 2);
      _drawText(
          canvas,
          'First Batten (${verticalResult!.firstBatten.toStringAsFixed(1)} mm)',
          Offset(
              margin - 50, margin + scaledGutterOverhang + scaledFirstBatten),
          textStyle,
          angle: -pi / 2);
      _drawText(
          canvas,
          'Ridge (${ridgeOffset.toStringAsFixed(1)} mm)',
          Offset(margin - 30, margin + scaledInputRafter - scaledRidgeOffset),
          textStyle,
          angle: -pi / 2);

      // Horizontal axis (X-axis)
      canvas.drawLine(
        Offset(margin + scaledLhOverhang, margin + scaledInputRafter + 10),
        Offset(margin + scaledLhOverhang + scaledWidth,
            margin + scaledInputRafter + 10),
        linePaint,
      );
      if (lhOverhang > 0) {
        _drawText(canvas, 'LH Overhang (${lhOverhang.toStringAsFixed(1)} mm)',
            Offset(margin, margin + scaledInputRafter + 20), textStyle);
      }
      _drawText(
          canvas,
          'First Mark (${horizontalResult!.firstMark.toStringAsFixed(1)} mm)',
          Offset(margin + scaledLhOverhang + scaledFirstMark - 40,
              margin + scaledInputRafter + 20),
          textStyle);
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

    // Check if the text will fit within bounds
    if (position.dx + textPainter.width > canvasSize.width ||
        position.dy + textPainter.height > canvasSize.height) {
      debugPrint(
          'Skipping text drawing due to overflow: text=$text, position=$position');
      return; // Skip drawing if text overflows
    }

    canvas.save();
    canvas.translate(position.dx, position.dy);
    if (angle != 0) {
      canvas.rotate(angle);
    }
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  Size canvasSize = Size.zero;

  @override
  bool shouldRepaint(covariant RoofPainter oldDelegate) {
    return oldDelegate.verticalResult != verticalResult ||
        oldDelegate.horizontalResult != horizontalResult ||
        oldDelegate.gutterOverhang != gutterOverhang;
  }
}
