import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/organisation/providers/company_permissions_provider.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/app/organisation/utils/org_job_saved_result.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class CompanyJobsSection extends ConsumerWidget {
  const CompanyJobsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInstaller = ref.watch(isInstallerRoleProvider);
    final jobsAsync = isInstaller
        ? ref.watch(myAssignedOrgJobsProvider)
        : ref.watch(orgJobsProvider);

    return jobsAsync.when(
      data: (jobs) {
        if (jobs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: isInstaller ? 'Assigned jobs' : 'Company jobs',
              subtitle: isInstaller
                  ? 'Set-out jobs assigned to you'
                  : 'Shared across your team',
            ),
            const SizedBox(height: 8),
            ...jobs.map((job) => _CompanyJobTile(job: job)),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CompanyJobTile extends StatelessWidget {
  final OrgJob job;

  const _CompanyJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final tileName = job.lockedTile['name']?.toString() ?? 'Tile';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          job.projectName,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$tileName · ${job.status.label}'),
        trailing: job.status == OrgJobStatus.complete
            ? const Icon(Icons.check_circle_outline)
            : const Icon(Icons.chevron_right),
        onTap: () {
          final result = savedResultFromOrgJob(job);
          if (result == null) return;
          context.push('/result-detail', extra: result);
        },
      ),
    );
  }
}