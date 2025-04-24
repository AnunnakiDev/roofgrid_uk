import 'package:flutter/material.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/widgets/result_visualization.dart';

// Enum for Visualization View Modes
enum ViewMode { vertical, horizontal, combined }

// Stateful Widget to Manage Visualization Toggle
class VisualizationWithToggle extends StatefulWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double gutterOverhang;
  final ViewMode defaultMode;

  const VisualizationWithToggle({
    super.key,
    required this.verticalResult,
    required this.horizontalResult,
    required this.gutterOverhang,
    required this.defaultMode,
  });

  @override
  State<VisualizationWithToggle> createState() =>
      _VisualizationWithToggleState();
}

class _VisualizationWithToggleState extends State<VisualizationWithToggle> {
  late ViewMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.defaultMode;
  }

  // Open the visualization in a full-screen pop-out
  void _openVisualizationPopOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: VisualizationPopOut(
          verticalResult: _currentMode == ViewMode.horizontal
              ? null
              : widget.verticalResult,
          horizontalResult: _currentMode == ViewMode.vertical
              ? null
              : widget.horizontalResult,
          gutterOverhang: widget.gutterOverhang,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVertical = widget.verticalResult != null;
    final hasHorizontal = widget.horizontalResult != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasVertical)
              _buildToggleButton(
                label: 'Vertical',
                mode: ViewMode.vertical,
                isSelected: _currentMode == ViewMode.vertical,
              ),
            if (hasHorizontal)
              _buildToggleButton(
                label: 'Horizontal',
                mode: ViewMode.horizontal,
                isSelected: _currentMode == ViewMode.horizontal,
              ),
            if (hasVertical && hasHorizontal)
              _buildToggleButton(
                label: 'Combined',
                mode: ViewMode.combined,
                isSelected: _currentMode == ViewMode.combined,
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Visualization with Tap to Pop-Out
        GestureDetector(
          onTap: () => _openVisualizationPopOut(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200,
              minHeight: 200,
              maxWidth: double.infinity,
            ),
            child: ResultVisualization(
              verticalResult: _currentMode == ViewMode.horizontal
                  ? null
                  : widget.verticalResult,
              horizontalResult: _currentMode == ViewMode.vertical
                  ? null
                  : widget.horizontalResult,
              gutterOverhang: widget.gutterOverhang,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required ViewMode mode,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentMode = mode;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary.withOpacity(0.2),
          foregroundColor: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(label),
      ),
    );
  }
}

// Full-screen visualization pop-out widget
class VisualizationPopOut extends StatelessWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double gutterOverhang;

  const VisualizationPopOut({
    super.key,
    this.verticalResult,
    this.horizontalResult,
    required this.gutterOverhang,
  });

  @override
  Widget build(BuildContext context) {
    // A3 size in pixels at 72 DPI (297mm x 420mm)
    const double a3WidthPx = 842; // 297mm * 72 DPI / 25.4 mm/inch
    const double a3HeightPx = 1191; // 420mm * 72 DPI / 25.4 mm/inch

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualization'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CustomPaint(
                size: Size(a3WidthPx, a3HeightPx), // A3 size
                painter: RoofPainter(
                  verticalResult: verticalResult,
                  horizontalResult: horizontalResult,
                  gutterOverhang: gutterOverhang,
                  primaryColor: Theme.of(context).colorScheme.primary,
                  textStyle: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 14),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
