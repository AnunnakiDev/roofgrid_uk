import 'package:flutter/material.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/saved_result_labour_import_summary.dart';

Future<void> showLabourImportSummaryDialog(
  BuildContext context,
  SavedResultLabourImportSummary summary,
) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Job imported'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.projectName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (summary.tileName != null && summary.tileName!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(summary.tileName!),
              ],
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Sections',
                value: '${summary.sectionCount}',
              ),
              _SummaryRow(
                label: 'Roof type',
                value: summary.roofType.label,
              ),
              _SummaryRow(
                label: 'Area',
                value: '${summary.roofAreaSqm.toStringAsFixed(1)} m²',
              ),
              _SummaryRow(
                label: 'Ridge',
                value: '${summary.ridgeMetres.toStringAsFixed(1)} m',
              ),
              _SummaryRow(
                label: 'Verge',
                value: '${summary.vergeMetres.toStringAsFixed(1)} m',
              ),
              if (summary.dryRidge)
                const _SummaryRow(label: 'Ridge detail', value: 'Dry ridge'),
              if (summary.dryVerge)
                const _SummaryRow(label: 'Verge detail', value: 'Dry verge'),
              if (summary.sectionLabels.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Sections',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                ...summary.sectionLabels.map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text('• $label'),
                  ),
                ),
              ],
              if (summary.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Review before calculating',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                ...summary.notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      note,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Review quote'),
          ),
        ],
      );
    },
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}