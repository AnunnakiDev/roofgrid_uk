import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/utils/horizontal_result_fields.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/widgets/info_row.dart';
import 'package:roofgrid_uk/widgets/job_workings_sheet.dart';
import 'package:roofgrid_uk/widgets/results/results_section_header.dart';
import 'package:roofgrid_uk/widgets/setout_hero_strip.dart';

class CalculationWarningBanner extends StatelessWidget {
  final String warning;
  final double fontSize;

  const CalculationWarningBanner({
    super.key,
    required this.warning,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warningColor = colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: warningColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warningColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: warningColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              warning,
              style: TextStyle(
                fontSize: fontSize - 2,
                color: colorScheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VerticalSolutionBadge extends StatelessWidget {
  final String solution;
  final double fontSize;

  const VerticalSolutionBadge({
    super.key,
    required this.solution,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (solution) {
      case 'Split Courses':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Split courses',
            style: TextStyle(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'Cut Course':
        return CalculationWarningBanner(
          warning: 'Last resort — cut course above eave',
          fontSize: fontSize,
        );
      case 'Invalid':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No valid vertical solution',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class HorizontalSolutionBadge extends StatelessWidget {
  final String solution;
  final double fontSize;

  const HorizontalSolutionBadge({
    super.key,
    required this.solution,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    switch (solution) {
      case 'Split Sets':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Split sets',
            style: TextStyle(
              fontSize: fontSize - 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case 'Cut Tile':
        return CalculationWarningBanner(
          warning: 'Last resort — cut tile at verge',
          fontSize: fontSize,
        );
      case 'Invalid':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No valid horizontal solution',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class VerticalResultsPanel extends StatelessWidget {
  final VerticalCalculationResult result;
  final String? tileMaterialType;
  final String? tileName;
  final List<SlopeInputEntry> slopes;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final JobWorkingsData? workingsData;
  final Widget? footer;

  const VerticalResultsPanel({
    super.key,
    required this.result,
    required this.tileMaterialType,
    required this.slopes,
    required this.fontSize,
    this.tileName,
    this.padding = const EdgeInsets.all(16.0),
    this.workingsData,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isInvalid = result.solution == 'Invalid';
    final heroRows = verticalHeroRows(
      result: result,
      materialType: tileMaterialType,
      slopes: slopes,
    );
    final secondaryRows = verticalSecondaryRows(
      result: result,
      materialType: tileMaterialType,
    );
    final positionChips = slopes.length <= 1
        ? verticalPositionGaugeChips(
            result: result,
            slopes: slopes,
          )
        : const <String>[];

    final tileChip = tileName != null && tileName!.isNotEmpty
        ? Chip(
            label: Text(
              tileName!,
              style: TextStyle(fontSize: fontSize - 2),
            ),
            visualDensity: VisualDensity.compact,
          )
        : null;

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResultsSectionHeader(
              title: 'Vertical set-out',
              fontSize: fontSize + 1,
              trailing: tileChip,
            ),
            const SizedBox(height: 12),
            SetoutHeroStrip(
              rows: heroRows,
              positionChips: positionChips,
              fontSize: fontSize,
              crossAxisCount: heroRows.length >= 3 ? 3 : null,
            ),
            if (result.solution != 'Even Courses') ...[
              const SizedBox(height: 10),
              VerticalSolutionBadge(
                solution: result.solution,
                fontSize: fontSize,
              ),
            ],
            if (!isInvalid && secondaryRows.isNotEmpty) ...[
              const ResultsSectionDivider(),
              Text(
                'Breakdown',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ...secondaryRows.map(
                (row) => InfoRow(label: row.label, value: row.value),
              ),
            ],
            if (!isInvalid && result.warning != null) ...[
              const SizedBox(height: 10),
              CalculationWarningBanner(
                warning: result.warning!,
                fontSize: fontSize,
              ),
            ],
            if (workingsData != null && !workingsData!.isEmpty) ...[
              const ResultsSectionDivider(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      JobWorkingsSheet.show(context, workingsData!),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Check inputs & workings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class HorizontalResultsPanel extends StatelessWidget {
  final HorizontalCalculationResult result;
  final List<WidthInputEntry> widths;
  final String? tileName;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final JobWorkingsData? workingsData;
  final Widget? footer;

  const HorizontalResultsPanel({
    super.key,
    required this.result,
    required this.widths,
    required this.fontSize,
    this.tileName,
    this.padding = const EdgeInsets.all(16.0),
    this.workingsData,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isInvalid = result.solution == 'Invalid';
    final displaySolution = effectiveHorizontalSolution(result);
    final heroRows = horizontalHeroRows(result);
    final secondaryRows = horizontalSecondaryRows(result);
    final positionChips = horizontalPositionMarkChips(
      result: result,
      widths: widths,
    );
    final widthSections = horizontalDetailSections(
      result: result,
      widths: widths,
    );

    final tileChip = tileName != null && tileName!.isNotEmpty
        ? Chip(
            label: Text(
              tileName!,
              style: TextStyle(fontSize: fontSize - 2),
            ),
            visualDensity: VisualDensity.compact,
          )
        : null;

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResultsSectionHeader(
              title: 'Horizontal set-out',
              fontSize: fontSize + 1,
              trailing: tileChip,
            ),
            const SizedBox(height: 12),
            SetoutHeroStrip(
              rows: heroRows,
              positionChips: positionChips,
              fontSize: fontSize,
              crossAxisCount: heroRows.length >= 3 ? 3 : null,
            ),
            if (displaySolution != 'Even Sets') ...[
              const SizedBox(height: 10),
              HorizontalSolutionBadge(
                solution: displaySolution,
                fontSize: fontSize,
              ),
            ],
            if (!isInvalid && secondaryRows.isNotEmpty) ...[
              const ResultsSectionDivider(),
              Text(
                'Breakdown',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              ...secondaryRows.map(
                (row) => InfoRow(label: row.label, value: row.value),
              ),
            ],
            if (!isInvalid && widthSections.length > 1) ...[
              const ResultsSectionDivider(),
              Text(
                'By width',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              for (var index = 0; index < widthSections.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                Text(
                  widths[index].label,
                  style: TextStyle(
                    fontSize: fontSize - 1,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                ...widthSections[index].map(
                  (row) => InfoRow(label: row.label, value: row.value),
                ),
              ],
            ],
            if (result.warning != null && !isInvalid) ...[
              const SizedBox(height: 10),
              CalculationWarningBanner(
                warning: result.warning!,
                fontSize: fontSize,
              ),
            ],
            if (workingsData != null && !workingsData!.isEmpty) ...[
              const ResultsSectionDivider(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      JobWorkingsSheet.show(context, workingsData!),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Check inputs & workings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}