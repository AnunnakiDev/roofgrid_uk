import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CalculatorFlowStep {
  selectTile,
  selectType,
  enterMeasurements,
  viewResults,
}

/// Top-of-flow progress: Tile → Type → Measurements → Results.
class CalculatorStepProgress extends StatelessWidget {
  final CalculatorFlowStep currentStep;
  final bool compact;

  const CalculatorStepProgress({
    super.key,
    required this.currentStep,
    this.compact = false,
  });

  static const _labels = ['Tile', 'Type', 'Measurements', 'Results'];

  int get _currentIndex => currentStep.index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(bottom: compact ? 0 : 14),
                  color: i <= _currentIndex
                      ? colorScheme.secondary.withValues(alpha: 0.5)
                      : colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
            _StepNode(
              index: i,
              label: _labels[i],
              compact: compact,
              state: i < _currentIndex
                  ? _StepNodeState.completed
                  : i == _currentIndex
                      ? _StepNodeState.active
                      : _StepNodeState.upcoming,
            ),
          ],
        ],
      ),
    );
  }
}

enum _StepNodeState { completed, active, upcoming }

class _StepNode extends StatelessWidget {
  final int index;
  final String label;
  final _StepNodeState state;
  final bool compact;

  const _StepNode({
    required this.index,
    required this.label,
    required this.state,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.secondary;

    final Color circleColor;
    final Color labelColor;
    final Widget circleChild;

    switch (state) {
      case _StepNodeState.completed:
        circleColor = colorScheme.primary;
        labelColor = colorScheme.onSurface;
        circleChild = Icon(Icons.check, size: 14, color: colorScheme.onPrimary);
      case _StepNodeState.active:
        circleColor = accent;
        labelColor = accent;
        circleChild = Text(
          '${index + 1}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSecondary,
          ),
        );
      case _StepNodeState.upcoming:
        circleColor = colorScheme.onSurface.withValues(alpha: 0.12);
        labelColor = colorScheme.onSurfaceVariant;
        circleChild = Text(
          '${index + 1}',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: state == _StepNodeState.active
                ? Border.all(color: accent.withValues(alpha: 0.4), width: 2)
                : null,
          ),
          child: Center(child: circleChild),
        ),
        if (!compact) ...[
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: state == _StepNodeState.active
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ],
    );
  }
}