import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/widgets/result_visualization.dart';

enum ViewMode { vertical, horizontal, combined }

class VisualizationWithToggle extends StatefulWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double gutterOverhang;
  final ViewMode defaultMode;
  final List<Map<String, dynamic>>? rafterHeights;
  final List<Map<String, dynamic>>? widths;
  final SavedResult? savedResult;
  final String? tileMaterialType;
  final bool showCombinedToggle;

  const VisualizationWithToggle({
    super.key,
    required this.verticalResult,
    required this.horizontalResult,
    required this.gutterOverhang,
    required this.defaultMode,
    this.rafterHeights,
    this.widths,
    this.savedResult,
    this.tileMaterialType,
    this.showCombinedToggle = true,
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

  @override
  void didUpdateWidget(covariant VisualizationWithToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultMode != widget.defaultMode) {
      _currentMode = widget.defaultMode;
    }
  }

  VerticalCalculationResult? get _activeVerticalResult =>
      _currentMode == ViewMode.horizontal ? null : widget.verticalResult;

  HorizontalCalculationResult? get _activeHorizontalResult =>
      _currentMode == ViewMode.vertical ? null : widget.horizontalResult;

  void _openVisualizationPopOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: VisualizationPopOut(
          verticalResult: _activeVerticalResult,
          horizontalResult: _activeHorizontalResult,
          gutterOverhang: widget.gutterOverhang,
          rafterHeights: widget.rafterHeights,
          widths: widget.widths,
          savedResult: widget.savedResult,
          tileMaterialType: widget.tileMaterialType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVertical = widget.verticalResult != null;
    final hasHorizontal = widget.horizontalResult != null;
    final showCombined =
        widget.showCombinedToggle && hasVertical && hasHorizontal;
    final showModeToggle = showCombined || (hasVertical && hasHorizontal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showModeToggle)
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
              if (showCombined)
                _buildToggleButton(
                  label: 'Combined',
                  mode: ViewMode.combined,
                  isSelected: _currentMode == ViewMode.combined,
                ),
            ],
          ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Roof visualization. Tap to open full screen.',
          button: true,
          child: GestureDetector(
            onTap: () => _openVisualizationPopOut(context),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.18),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  ResultVisualization(
                    verticalResult: _activeVerticalResult,
                    horizontalResult: _activeHorizontalResult,
                    gutterOverhang: widget.gutterOverhang,
                    rafterHeights: widget.rafterHeights,
                    widths: widget.widths,
                    savedResult: widget.savedResult,
                    tileMaterialType: widget.tileMaterialType,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Icon(
                      Icons.zoom_in,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap diagram to open full-screen zoom',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => setState(() => _currentMode = mode),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? colorScheme.secondary
              : colorScheme.surface,
          foregroundColor: isSelected
              ? colorScheme.onSecondary
              : colorScheme.onSurface,
          elevation: isSelected ? 2 : 0,
          side: isSelected
              ? null
              : BorderSide(color: colorScheme.secondary.withValues(alpha: 0.35)),
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

class VisualizationPopOut extends StatelessWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double gutterOverhang;
  final List<Map<String, dynamic>>? rafterHeights;
  final List<Map<String, dynamic>>? widths;
  final SavedResult? savedResult;
  final String? tileMaterialType;

  const VisualizationPopOut({
    super.key,
    this.verticalResult,
    this.horizontalResult,
    required this.gutterOverhang,
    this.rafterHeights,
    this.widths,
    this.savedResult,
    this.tileMaterialType,
  });

  @override
  Widget build(BuildContext context) {
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
          final screenSize = MediaQuery.of(context).size;
          final scaleWidth = screenSize.width / kVisualizationA3WidthPx;
          final scaleHeight = screenSize.height / kVisualizationA3HeightPx;
          final scale = min(scaleWidth, scaleHeight);

          return InteractiveViewer(
            minScale: scale,
            maxScale: 4.0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
                child: SizedBox(
                  width: kVisualizationA3WidthPx,
                  height: kVisualizationA3HeightPx,
                  child: ResultVisualization(
                    verticalResult: verticalResult,
                    horizontalResult: horizontalResult,
                    gutterOverhang: gutterOverhang,
                    rafterHeights: rafterHeights,
                    widths: widths,
                    savedResult: savedResult,
                    tileMaterialType: tileMaterialType,
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