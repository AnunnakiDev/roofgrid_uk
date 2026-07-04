import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SchematicPreviewAxis { verticalBatten, horizontalCourse }

/// Non-calculating schematic hint for entered dimensions.
class SchematicPreviewStrip extends StatelessWidget {
  final SchematicPreviewAxis axis;
  final List<double> dimensionsMm;

  const SchematicPreviewStrip({
    super.key,
    required this.axis,
    required this.dimensionsMm,
  });

  List<double> get _validDimensions =>
      dimensionsMm.where((value) => value > 0).toList();

  @override
  Widget build(BuildContext context) {
    final values = _validDimensions;
    if (values.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final caption = axis == SchematicPreviewAxis.verticalBatten
        ? 'Schematic batten spacing (not calculated)'
        : 'Schematic tile courses (not calculated)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: Row(
              children: [
                for (var i = 0; i < values.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _SchematicCell(
                      axis: axis,
                      dimensionMm: values[i],
                      accent: colorScheme.secondary,
                      frame: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchematicCell extends StatelessWidget {
  final SchematicPreviewAxis axis;
  final double dimensionMm;
  final Color accent;
  final Color frame;

  const _SchematicCell({
    required this.axis,
    required this.dimensionMm,
    required this.accent,
    required this.frame,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SchematicPainter(
        axis: axis,
        dimensionMm: dimensionMm,
        accent: accent,
        frame: frame,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SchematicPainter extends CustomPainter {
  final SchematicPreviewAxis axis;
  final double dimensionMm;
  final Color accent;
  final Color frame;

  _SchematicPainter({
    required this.axis,
    required this.dimensionMm,
    required this.accent,
    required this.frame,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final border = Paint()
      ..color = frame.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final line = Paint()
      ..color = accent.withValues(alpha: 0.75)
      ..strokeWidth = 1.4;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, border);

    final lineCount = (dimensionMm / 450).clamp(3, 10).round();

    if (axis == SchematicPreviewAxis.verticalBatten) {
      final spacing = size.height / (lineCount + 1);
      for (var i = 1; i <= lineCount; i++) {
        final y = spacing * i;
        canvas.drawLine(Offset(6, y), Offset(size.width - 6, y), line);
      }
    } else {
      final spacing = size.width / (lineCount + 1);
      for (var i = 1; i <= lineCount; i++) {
        final x = spacing * i;
        canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SchematicPainter oldDelegate) {
    return oldDelegate.dimensionMm != dimensionMm ||
        oldDelegate.axis != axis;
  }
}