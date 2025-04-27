import 'dart:math';

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
        // Visualization Thumbnail in Expansion Tile
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: const Text('Visualization Preview'),
            children: [
              GestureDetector(
                onTap: () => _openVisualizationPopOut(context),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: ResultVisualization(
                    verticalResult: _currentMode == ViewMode.horizontal
                        ? null
                        : widget.verticalResult,
                    horizontalResult: _currentMode == ViewMode.vertical
                        ? null
                        : widget.horizontalResult,
                    gutterOverhang: widget.gutterOverhang,
                    isThumbnail: false, // Full view in expansion tile
                  ),
                ),
              ),
            ],
            collapsedIconColor: Theme.of(context).colorScheme.primary,
            iconColor: Theme.of(context).colorScheme.primary,
            childrenPadding: EdgeInsets.zero,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            // Thumbnail preview
            leading: SizedBox(
              width: 60,
              height: 60,
              child: ResultVisualization(
                verticalResult: _currentMode == ViewMode.horizontal
                    ? null
                    : widget.verticalResult,
                horizontalResult: _currentMode == ViewMode.vertical
                    ? null
                    : widget.horizontalResult,
                gutterOverhang: widget.gutterOverhang,
                isThumbnail: true,
              ),
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
          // Calculate the scale to fit the A3 visualization within the screen
          final screenSize = MediaQuery.of(context).size;
          final scaleWidth = screenSize.width / a3WidthPx;
          final scaleHeight = screenSize.height / a3HeightPx;
          final scale = min(scaleWidth, scaleHeight);

          return InteractiveViewer(
            minScale: scale, // Fit to screen
            maxScale: 4.0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                child: SizedBox(
                  width: a3WidthPx,
                  height: a3HeightPx,
                  child: ResultVisualization(
                    verticalResult: verticalResult,
                    horizontalResult: horizontalResult,
                    gutterOverhang: gutterOverhang,
                    isThumbnail: false,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
