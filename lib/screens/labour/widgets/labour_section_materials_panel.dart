import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_materials_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_material_lines_panel.dart';

class LabourSectionMaterialsPanel extends ConsumerWidget {
  final String sectionId;
  final LabourRoofSection section;

  const LabourSectionMaterialsPanel({
    super.key,
    required this.sectionId,
    required this.section,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(labourPricingProvider.notifier);
    final project = ref.watch(labourPricingProvider).project;
    final mode = section.materialsMode;
    final inheritedLines = project.projectMaterialLines;
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Section materials',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<SectionMaterialsMode>(
          segments: SectionMaterialsMode.values
              .map(
                (value) => ButtonSegment(
                  value: value,
                  label: Text(
                    value == SectionMaterialsMode.inheritProject
                        ? 'Project'
                        : value == SectionMaterialsMode.sectionOverride
                            ? 'Override'
                            : 'None',
                  ),
                ),
              )
              .toList(),
          selected: {mode},
          onSelectionChanged: (selection) {
            notifier.setSectionMaterialsMode(sectionId, selection.first);
          },
        ),
        const SizedBox(height: 12),
        switch (mode) {
          SectionMaterialsMode.none => Text(
              'Materials excluded from this section (Method A).',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          SectionMaterialsMode.inheritProject => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inheritedLines.isEmpty
                      ? 'No project materials defined yet.'
                      : 'Inheriting ${inheritedLines.length} project line(s) · '
                          '${gbp.format(inheritedLines.fold<double>(0, (s, l) => s + l.lineTotalGbp))}',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ],
            ),
          SectionMaterialsMode.sectionOverride => LabourMaterialLinesPanel(
              lines: section.materialLines,
              onChanged: (next) =>
                  notifier.updateSectionMaterialLines(sectionId, next),
              onSuggest: () {
                final count = notifier.applyBoqSuggestions(sectionId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'Suggested $count material lines'
                          : 'No suggestions for this section',
                    ),
                  ),
                );
              },
            ),
        },
      ],
    );
  }
}