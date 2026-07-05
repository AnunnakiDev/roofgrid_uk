import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/app/organisation/utils/org_job_saved_result.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class InstallerAssignmentsCard extends ConsumerWidget {
  const InstallerAssignmentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myAssignedOrgJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    title: 'Assigned jobs',
                    subtitle: 'Jobs assigned by your company will appear here',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No assignments yet. Your estimator or owner will assign set-out jobs when a project is won.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Assigned jobs',
              subtitle: 'Open a job to run set-out on site',
            ),
            const SizedBox(height: 12),
            ...jobs.map((job) => _AssignedJobTile(job: job)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AssignedJobTile extends StatelessWidget {
  final OrgJob job;

  const _AssignedJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final tileName = job.lockedTile['name']?.toString() ?? 'Tile';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(job.projectName),
        subtitle: Text('$tileName · ${job.status.label}'),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: () {
          final result = savedResultFromOrgJob(job);
          if (result == null) return;
          navigateToLockedSetOutCalculator(
            context,
            savedResult: result,
            orgJobId: job.id,
          );
        },
      ),
    );
  }
}