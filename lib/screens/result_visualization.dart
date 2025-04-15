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
          painter: widget.result.type == CalculationType.vertical
              ? VerticalResultPainter(widget.result, _scale, _offset)
              : HorizontalResultPainter(widget.result, _scale, _offset),
          child: Container(),
        ),
      ),
    );
  }
}

class VerticalResultPainter extends CustomPainter {
  final SavedResult result;
  final double scale;
  final Offset offset;

  VerticalResultPainter(this.result, this.scale, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Define colors
    final battensColor = Colors.brown.shade700;
    final rafterColor = Colors.grey.shade800;
    final measurementsColor = Colors.blue.shade700;

    // Define paints
    final rafterPaint = Paint()
      ..color = rafterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final battenPaint = Paint()
      ..color = battensColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final measurementPaint = Paint()
      ..color = measurementsColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

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

    final rafterHeights = (inputs['rafterHeights'] as List<dynamic>);
    final firstRafterHeight = rafterHeights[0]['value'] as num;

    // Calculate scale factor to fit in view
    final maxHeight = firstRafterHeight;
    const maxWidth = 500.0;
    final scaleFactor = size.height / maxHeight * 0.9;
    final baseX = size.width / 2;

    // Draw rafter (vertical line)
    canvas.drawLine(
      Offset(baseX, 10),
      Offset(baseX, 10 + maxHeight * scaleFactor),
      rafterPaint,
    );

    // Draw battens (horizontal lines)
    final eavesBatten = outputs['eaveBatten'];
    final firstBatten = outputs['firstBatten'];
    final totalCourses = outputs['totalCourses'];
    final gauge = outputs['gauge'];
    final ridgeOffset = outputs['ridgeOffset'];

    // Draw eaves batten if present
    if (eavesBatten != null) {
      final y = 10 + (maxHeight - eavesBatten) * scaleFactor;
      canvas.drawLine(
        Offset(baseX - 50, y),
        Offset(baseX + 50, y),
        battenPaint,
      );

      // Label
      textPainter.text = TextSpan(
        text: 'Eaves: ${eavesBatten}mm',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(baseX + 55, y - 5));
    }

    // Draw first batten
    final firstBattenY = 10 + (maxHeight - firstBatten) * scaleFactor;
    canvas.drawLine(
      Offset(baseX - 50, firstBattenY),
      Offset(baseX + 50, firstBattenY),
      battenPaint,
    );

    // Label first batten
    textPainter.text = TextSpan(
      text: 'First: ${firstBatten}mm',
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(baseX + 55, firstBattenY - 5));

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
    for (int i = 1; i <= regularBattens; i++) {
      final y = firstBattenY - (gaugeDistance * i * scaleFactor);
      canvas.drawLine(
        Offset(baseX - 50, y),
        Offset(baseX + 50, y),
        battenPaint,
      );

      // Only label some battens to avoid clutter
      if (i == 1 || i == regularBattens || i % 5 == 0) {
        textPainter.text = TextSpan(
          text: 'Batten ${i + 1}',
          style: textStyle,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(baseX - 90, y - 5));
      }
    }

    // Draw ridge line
    const ridgeY = 10;
    canvas.drawLine(
      Offset(baseX - 60, ridgeY as double),
      Offset(baseX + 60, ridgeY as double),
      battenPaint..color = Colors.red.shade700,
    );

    // Label ridge
    textPainter.text = TextSpan(
      text: 'Ridge (offset: ${ridgeOffset}mm)',
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(baseX + 65, ridgeY - 5));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VerticalResultPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}

class HorizontalResultPainter extends CustomPainter {
  final SavedResult result;
  final double scale;
  final Offset offset;

  HorizontalResultPainter(this.result, this.scale, this.offset);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    // Define colors
    final tileColor = Colors.orangeAccent.shade200;
    final measurementsColor = Colors.blue.shade700;
    final widthLineColor = Colors.grey.shade800;

    // Define paints
    final tilePaint = Paint()
      ..color = tileColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final measurementPaint = Paint()
      ..color = measurementsColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final widthLinePaint = Paint()
      ..color = widthLineColor
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

    final widths = (inputs['widths'] as List<dynamic>);
    final firstWidth = widths[0]['value'] as num;

    // Calculate scale factor to fit in view
    final maxWidth = firstWidth;
    final scaleFactor = size.width / maxWidth * 0.9;
    const baseY = 100.0;
    const startX = 20.0;

    // Draw width line (horizontal)
    canvas.drawLine(
      const Offset(startX, baseY),
      Offset(startX + maxWidth * scaleFactor, baseY),
      widthLinePaint,
    );

    // Draw tiles based on width calculation
    final solution = outputs['solution'];
    final marks = outputs['marks'];
    final firstMark = outputs['firstMark'];
    final secondMark = outputs['secondMark'];

    // Label width
    textPainter.text = TextSpan(
      text: 'Width: ${firstWidth}mm',
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(startX, baseY + 20));

    // Label solution
    textPainter.text = TextSpan(
      text: 'Solution: $solution',
      style: textStyle.copyWith(fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(startX, baseY - 30));

    // Draw first mark
    if (firstMark != null) {
      final x = startX + (firstMark * scaleFactor);
      canvas.drawLine(
        Offset(x, baseY - 15),
        Offset(x, baseY + 15),
        measurementPaint,
      );

      // Label
      textPainter.text = TextSpan(
        text: '${firstMark}mm',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 15, baseY - 30));
    }

    // Draw second mark if exists
    if (secondMark != null) {
      final x = startX + (secondMark * scaleFactor);
      canvas.drawLine(
        Offset(x, baseY - 15),
        Offset(x, baseY + 15),
        measurementPaint,
      );

      // Label
      textPainter.text = TextSpan(
        text: '${secondMark}mm',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 15, baseY + 20));
    }

    // Draw marks info
    if (marks != null) {
      textPainter.text = TextSpan(
        text: 'Marks: $marks',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(startX, baseY - 50));
    }

    // Draw tiles schematically (rectangles)
    final tileCoverWidth = result.tile['tileCoverWidth'] as num? ?? 200;
    const tileHeight = 40.0; // visual only

    // For cut course solution
    if (solution == 'Cut Course' && outputs['cutTile'] != null) {
      final cutTileWidth = outputs['cutTile'] as num;
      final adjustedMarks = outputs['adjustedMarks'] as num? ?? 0;
      final actualSpacing = outputs['actualSpacing'] as num? ?? 0;

      // Calculate number of tiles that fit
      int numFullTiles =
          ((firstWidth - cutTileWidth) / (tileCoverWidth + actualSpacing))
              .floor();

      // Draw full tiles
      for (int i = 0; i < numFullTiles; i++) {
        final tileX =
            startX + i * (tileCoverWidth + actualSpacing) * scaleFactor;
        final tileRect = Rect.fromLTWH(
          tileX,
          baseY - tileHeight - 10,
          tileCoverWidth * scaleFactor,
          tileHeight,
        );
        canvas.drawRect(tileRect, tilePaint);
      }

      // Draw cut tile at the end
      final cutTileX = startX +
          numFullTiles * (tileCoverWidth + actualSpacing) * scaleFactor;
      final cutTileRect = Rect.fromLTWH(
        cutTileX,
        baseY - tileHeight - 10,
        cutTileWidth * scaleFactor,
        tileHeight,
      );
      canvas.drawRect(cutTileRect, tilePaint..color = Colors.red.shade300);

      // Label cut tile
      textPainter.text = TextSpan(
        text: '${cutTileWidth}mm',
        style: textStyle.copyWith(color: Colors.red.shade700),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
            cutTileX + (cutTileWidth * scaleFactor / 2) - textPainter.width / 2,
            baseY - tileHeight - 25),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HorizontalResultPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
