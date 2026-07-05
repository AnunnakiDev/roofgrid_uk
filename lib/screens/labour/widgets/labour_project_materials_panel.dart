import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_material_lines_panel.dart';

class LabourProjectMaterialsPanel extends ConsumerWidget {
  const LabourProjectMaterialsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labourPricingProvider);
    final notifier = ref.read(labourPricingProvider.notifier);
    final lines = state.project.projectMaterialLines;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project materials',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Default BoQ for sections set to inherit project materials. '
              'Included in Method A totals only.',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            const SizedBox(height: 12),
            LabourMaterialLinesPanel(
              lines: lines,
              onChanged: notifier.updateProjectMaterialLines,
              onSuggest: () {
                final count = notifier.applyProjectBoq();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'Suggested $count project material lines'
                          : 'No suggestions — check price list and roof areas',
                    ),
                  ),
                );
              },
              suggestLabel: 'Suggest project BoQ',
            ),
          ],
        ),
      ),
    );
  }
}