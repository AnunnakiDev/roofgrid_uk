import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/organisation/providers/company_permissions_provider.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/app/organisation/utils/org_job_saved_result.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class OrgJobPipelineCard extends ConsumerWidget {
  const OrgJobPipelineCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(isInstallerRoleProvider)) {
      return const SizedBox.shrink();
    }

    final jobsAsync = ref.watch(orgJobsProvider);
    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) return const SizedBox.shrink();
        final active = jobs
            .where((job) => job.status != OrgJobStatus.complete)
            .take(5)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Company pipeline',
              subtitle: 'Shared jobs across your team',
            ),
            const SizedBox(height: 12),
            ...active.map((job) => _JobPipelineTile(job: job)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _JobPipelineTile extends StatelessWidget {
  final OrgJob job;

  const _JobPipelineTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final tileName = job.lockedTile['name']?.toString() ?? 'Tile';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(job.projectName),
        subtitle: Text('$tileName · ${job.status.label}'),
        trailing: _StatusChip(status: job.status),
        onTap: () {
          final result = savedResultFromOrgJob(job);
          if (result != null) {
            context.push('/result-detail', extra: result);
          }
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrgJobStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
    );
  }
}