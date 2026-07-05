import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';

class OrgJobStatusControls extends ConsumerWidget {
  final OrgJob orgJob;

  const OrgJobStatusControls({super.key, required this.orgJob});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pipeline status',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Track this job from survey through to completion.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OrgJobStatus.values.map((status) {
                final selected = orgJob.status == status;
                return FilterChip(
                  label: Text(status.label),
                  selected: selected,
                  onSelected: selected
                      ? null
                      : (_) => _updateStatus(context, ref, status),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrgJobStatus status,
  ) async {
    try {
      await ref.read(orgJobServiceProvider).updateStatus(
            orgId: orgJob.orgId,
            jobId: orgJob.id,
            status: status,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.label}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $e')),
      );
    }
  }
}