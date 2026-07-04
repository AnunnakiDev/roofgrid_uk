import 'package:flutter/material.dart';

/// Subtle roof-grid lines for app bar and hero surfaces.
class RoofGridPattern extends StatelessWidget {
  final Color lineColor;
  final double cellSize;

  const RoofGridPattern({
    super.key,
    required this.lineColor,
    this.cellSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RoofGridPainter(
        lineColor: lineColor,
        cellSize: cellSize,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RoofGridPainter extends CustomPainter {
  final Color lineColor;
  final double cellSize;

  _RoofGridPainter({
    required this.lineColor,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    for (var x = 0.0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoofGridPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.cellSize != cellSize;
  }
}