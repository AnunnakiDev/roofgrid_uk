import 'package:flutter/material.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/widgets/results/results_section_header.dart';
import 'package:roofgrid_uk/widgets/visualization_toggle.dart';

/// Themed card wrapping the roof diagram and mode toggle.
class ResultsVisualizationCard extends StatelessWidget {
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double gutterOverhang;
  final ViewMode defaultMode;
  final List<Map<String, dynamic>>? rafterHeights;
  final List<Map<String, dynamic>>? widths;
  final SavedResult? savedResult;
  final String? tileMaterialType;
  final bool showCombinedToggle;
  final double fontSize;

  const ResultsVisualizationCard({
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
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResultsSectionHeader(
              title: 'Visualization',
              fontSize: fontSize,
            ),
            const SizedBox(height: 12),
            VisualizationWithToggle(
              verticalResult: verticalResult,
              horizontalResult: horizontalResult,
              gutterOverhang: gutterOverhang,
              defaultMode: defaultMode,
              rafterHeights: rafterHeights,
              widths: widths,
              savedResult: savedResult,
              tileMaterialType: tileMaterialType,
              showCombinedToggle: showCombinedToggle,
            ),
          ],
        ),
      ),
    );
  }
}