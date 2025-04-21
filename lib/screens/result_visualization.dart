import 'package:flutter/material.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

class ResultVisualization extends StatefulWidget {
  final SavedResult result;

  const ResultVisualization({super.key, required this.result});

  @override
  State<ResultVisualization> createState() => _ResultVisualizationState();
}

class _ResultVisualizationState extends State<ResultVisualization> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(0.5, 3.0);
          _offset += details.focalPointDelta;
        });
      },
      child: ClipRect(
        child: CustomPaint(
          painter: RoofResultPainter(widget.result, _scale, _offset),
          child: Container(),
        ),
      ),
    );
  }
}

class RoofResultPainter extends CustomPainter {
  final SavedResult result;
  final double scale;
  final Offset offset;

  RoofResultPainter(this.result, this.scale, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Define colors
    final battensColor = Colors.brown.shade700;
    final measurementsColor = Colors.blue.shade700;
    final fasciaColor = Colors.green.shade700;
    final ridgeColor = Colors.red.shade700;

    // Define paints
    final rafterPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final widthLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final battenPaint = Paint()
      ..color = battensColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final markPaint = Paint()
      ..color = battensColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final measurementPaint = Paint()
      ..color = measurementsColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fasciaPaint = Paint()
      ..color = fasciaColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final ridgePaint = Paint()
      ..color = ridgeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Define text styles
    final textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 10 / scale,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Get data from result
    final inputs = result.inputs;
    final outputs = result.outputs;

    // Extract rafters and widths
    final rafterInputs =
        (inputs['vertical_inputs']?['rafterHeights'] as List<dynamic>?) ?? [];
    final widthInputs =
        (inputs['horizontal_inputs']?['widths'] as List<dynamic>?) ?? [];

    final rafterColors = (inputs['rafterColors'] as List<dynamic>? ?? [])
        .asMap()
        .map((index, colorStr) => MapEntry(
              index,
              Color(int.parse(colorStr)),
            ));

    final widthColors = (inputs['widthColors'] as List<dynamic>? ?? [])
        .asMap()
        .map((index, colorStr) => MapEntry(
              index,
              Color(int.parse(colorStr)),
            ));

    // If no rafters, use a default single rafter
    final rafters = rafterInputs.isEmpty
        ? [
            {'label': 'Rafter 1', 'value': 5000.0},
            {'label': 'Rafter 1', 'value': 5000.0},
          ]
        : rafterInputs.length == 1
            ? [
                rafterInputs[0],
                rafterInputs[0] as Map<String, dynamic>,
              ]
            : rafterInputs;

    // If no widths, use a default single width
    final widths = widthInputs.isEmpty
        ? [
            {'label': 'Width 1', 'value': 4000.0},
            {'label': 'Width 1', 'value': 4000.0},
          ]
        : widthInputs.length == 1
            ? [
                widthInputs[0],
                widthInputs[0] as Map<String, dynamic>,
              ]
            : widthInputs;

    // Update colors for duplicated inputs
    final updatedRafterColors = rafters.asMap().map((index, _) => MapEntry(
          index,
          index < rafterColors.length
              ? rafterColors[index] ?? Colors.grey.shade800
              : rafterColors[0] ?? Colors.grey.shade800,
        ));

    final updatedWidthColors = widths.asMap().map((index, _) => MapEntry(
          index,
          index < widthColors.length
              ? widthColors[index] ?? Colors.grey.shade800
              : widthColors[0] ?? Colors.grey.shade800,
        ));

    // Calculate dimensions
    final maxRafterHeight = rafters
        .map((r) =>
            (r['value'] as num) +
            (inputs['vertical_inputs']?['gutterOverhang'] ?? 0.0))
        .reduce((a, b) => a > b ? a : b);
    final maxWidth =
        widths.map((w) => (w['value'] as num)).reduce((a, b) => a > b ? a : b);

    // Calculate scale factors to fit in view
    final scaleFactorX = size.width / maxWidth * 0.9;
    final scaleFactorY = size.height / maxRafterHeight * 0.9;
    final scaleFactor =
        scaleFactorX < scaleFactorY ? scaleFactorX : scaleFactorY;

    final startX = 20.0;
    final startY = 20.0;

    // Draw widths (horizontal lines, left to right)
    for (int i = 0; i < widths.length; i++) {
      final width = widths[i]['value'] as num;
      final widthColor = updatedWidthColors[i] ?? Colors.grey.shade800;
      final y =
          startY + i * (maxRafterHeight * scaleFactor) / (widths.length - 1);

      // Draw width line
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + width * scaleFactor, y),
        widthLinePaint..color = widthColor,
      );

      // Label width
      textPainter.text = TextSpan(
        text: '${widths[i]['label']}: ${width}mm',
        style: textStyle.copyWith(color: widthColor),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(startX + width * scaleFactor + 5, y - 5));

      // Label fascia and ridge
      if (i == 0) {
        // Fascia (first width)
        canvas.drawLine(
          Offset(startX - 5, y),
          Offset(startX + width * scaleFactor + 5, y),
          fasciaPaint,
        );
        textPainter.text = const TextSpan(
          text: 'Fascia',
          style: TextStyle(color: Colors.green, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(startX - 5, y - 15));
      }
      if (i == widths.length - 1) {
        // Ridge (last width)
        canvas.drawLine(
          Offset(startX - 5, y),
          Offset(startX + width * scaleFactor + 5, y),
          ridgePaint,
        );
        textPainter.text = const TextSpan(
          text: 'Ridge',
          style: TextStyle(color: Colors.red, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(startX + width * scaleFactor + 5, y + 10));
      }
    }

    // Draw rafters (vertical lines, bottom to top)
    for (int i = 0; i < rafters.length; i++) {
      final rafterHeight = rafters[i]['value'] as num;
      final gutterOverhang =
          inputs['vertical_inputs']?['gutterOverhang'] ?? 0.0;
      final totalHeight = rafterHeight + gutterOverhang;
      final rafterColor = updatedRafterColors[i] ?? Colors.grey.shade800;
      final x = startX + i * (maxWidth * scaleFactor) / (rafters.length - 1);

      // Draw rafter line
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + totalHeight * scaleFactor),
        rafterPaint..color = rafterColor,
      );

      // Label rafter
      textPainter.text = TextSpan(
        text: '${rafters[i]['label']}: ${rafterHeight}mm',
        style: textStyle.copyWith(color: rafterColor),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2,
              startY + totalHeight * scaleFactor + 15));

      // Draw gutter overhang if present
      if (gutterOverhang > 0) {
        final fasciaY = startY + rafterHeight * scaleFactor;
        final overhangY = startY + totalHeight * scaleFactor;
        canvas.drawLine(
          Offset(x - 5, fasciaY),
          Offset(x + 5, fasciaY),
          measurementPaint,
        );
        canvas.drawLine(
          Offset(x - 5, overhangY),
          Offset(x + 5, overhangY),
          measurementPaint,
        );
        textPainter.text = TextSpan(
          text: 'Gutter: ${gutterOverhang}mm',
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 10, (fasciaY + overhangY) / 2));
      }
    }

    // Draw gauges (horizontal lines along rafters)
    if (result.type == CalculationType.vertical) {
      final firstBatten = outputs['firstBatten'];
      final totalCourses = outputs['totalCourses'];
      final gauge = outputs['gauge'];
      final ridgeOffset = outputs['ridgeOffset'];
      final eaveBatten = outputs['eaveBatten'];

      // Draw eave batten if present
      if (eaveBatten != null) {
        for (int i = 0; i < rafters.length; i++) {
          final rafterHeight = rafters[i]['value'] as num;
          final x =
              startX + i * (maxWidth * scaleFactor) / (rafters.length - 1);
          final y = startY + (rafterHeight - (eaveBatten as num)) * scaleFactor;
          canvas.drawLine(
            Offset(x - 5, y),
            Offset(x + 5, y),
            battenPaint,
          );
        }
        // Label (only once)
        textPainter.text = TextSpan(
          text: 'Eaves: ${eaveBatten}mm',
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset(
                startX + maxWidth * scaleFactor + 10,
                startY +
                    ((rafters[0]['value'] as num) - (eaveBatten as num)) *
                        scaleFactor));
      }

      // Draw first batten
      for (int i = 0; i < rafters.length; i++) {
        final rafterHeight = rafters[i]['value'] as num;
        final x = startX + i * (maxWidth * scaleFactor) / (rafters.length - 1);
        final y = startY + (rafterHeight - (firstBatten as num)) * scaleFactor;
        canvas.drawLine(
          Offset(x - 5, y),
          Offset(x + 5, y),
          battenPaint,
        );
      }
      // Label (only once)
      textPainter.text = TextSpan(
        text: 'First: ${firstBatten}mm',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              startX + maxWidth * scaleFactor + 10,
              startY +
                  ((rafters[0]['value'] as num) - (firstBatten as num)) *
                      scaleFactor));

      // Extract gauge information
      String gaugeText = gauge;
      int regularBattens = 0;
      int gaugeDistance = 0;

      final gaugeParts = gaugeText.split('@');
      if (gaugeParts.length == 2) {
        regularBattens = int.tryParse(gaugeParts[0].trim()) ?? 0;
        gaugeDistance = int.tryParse(gaugeParts[1].trim()) ?? 0;
      }

      // Draw regular battens
      for (int j = 1; j <= regularBattens; j++) {
        final y = startY +
            ((rafters[0]['value'] as num) -
                    (firstBatten as num) -
                    gaugeDistance * j) *
                scaleFactor;
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + maxWidth * scaleFactor, y),
          battenPaint,
        );

        // Label only some battens to avoid clutter
        if (j == 1 || j == regularBattens || j % 5 == 0) {
          textPainter.text = TextSpan(
            text: 'Batten ${j + 1}',
            style: textStyle,
          );
          textPainter.layout();
          textPainter.paint(
              canvas, Offset(startX + maxWidth * scaleFactor + 10, y));
        }
      }

      // Label ridge offset
      textPainter.text = TextSpan(
        text: 'Ridge Offset: ${ridgeOffset}mm',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(startX + maxWidth * scaleFactor + 10, startY));
    }

    // Draw marks (vertical lines along widths)
    if (result.type == CalculationType.horizontal) {
      final solution = outputs['solution'];
      final marks = outputs['marks'];
      final firstMark = outputs['firstMark'];
      final secondMark = outputs['secondMark'];
      final actualSpacing = outputs['actualSpacing'] ?? 0;
      final lhOverhang = outputs['lhOverhang'];
      final rhOverhang = outputs['rhOverhang'];

      // Draw LH overhang if present
      if (lhOverhang != null) {
        for (int i = 0; i < widths.length; i++) {
          final y = startY +
              i * (maxRafterHeight * scaleFactor) / (widths.length - 1);
          final x = startX;
          canvas.drawLine(
            Offset(x - 5, y),
            Offset(x + 5, y),
            measurementPaint,
          );
          final xOverhang = startX + (lhOverhang as num) * scaleFactor;
          canvas.drawLine(
            Offset(xOverhang - 5, y),
            Offset(xOverhang + 5, y),
            measurementPaint,
          );
          textPainter.text = TextSpan(
            text: 'LH: ${lhOverhang}mm',
            style: textStyle,
          );
          textPainter.layout();
          textPainter.paint(canvas,
              Offset((x + xOverhang) / 2 - textPainter.width / 2, y + 15));
        }
      }

      // Draw RH overhang if present
      if (rhOverhang != null) {
        for (int i = 0; i < widths.length; i++) {
          final width = widths[i]['value'] as num;
          final y = startY +
              i * (maxRafterHeight * scaleFactor) / (widths.length - 1);
          final xEnd = startX + width * scaleFactor;
          canvas.drawLine(
            Offset(xEnd - 5, y),
            Offset(xEnd + 5, y),
            measurementPaint,
          );
          final xOverhang =
              startX + (width - (rhOverhang as num)) * scaleFactor;
          canvas.drawLine(
            Offset(xOverhang - 5, y),
            Offset(xOverhang + 5, y),
            measurementPaint,
          );
          textPainter.text = TextSpan(
            text: 'RH: ${rhOverhang}mm',
            style: textStyle,
          );
          textPainter.layout();
          textPainter.paint(canvas,
              Offset((xOverhang + xEnd) / 2 - textPainter.width / 2, y + 15));
        }
      }

      // Draw first mark
      if (firstMark != null) {
        final x = startX + (firstMark as num) * scaleFactor;
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + maxRafterHeight * scaleFactor),
          markPaint,
        );

        // Label
        textPainter.text = TextSpan(
          text: '${firstMark}mm',
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, startY - 15));
      }

      // Draw second mark if exists
      if (secondMark != null) {
        final x = startX + (secondMark as num) * scaleFactor;
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, startY + maxRafterHeight * scaleFactor),
          markPaint,
        );

        // Label
        textPainter.text = TextSpan(
          text: '${secondMark}mm',
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, startY - 15));
      }

      // Draw marks info
      if (marks != null) {
        textPainter.text = TextSpan(
          text: 'Marks: $marks',
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(startX - textPainter.width / 2, startY - 30));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RoofResultPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
