import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/utils/labour_quote_lookup.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job.dart';
import 'package:roofgrid_uk/app/organisation/models/org_job_status.dart';
import 'package:roofgrid_uk/app/organisation/providers/company_permissions_provider.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/app/organisation/utils/org_job_saved_result.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
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

class _JobPipelineTile extends ConsumerWidget {
  final OrgJob job;

  const _JobPipelineTile({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileName = job.lockedTile['name']?.toString() ?? 'Tile';
    final quotes = ref.watch(labourQuotesProvider).value ?? const [];
    final linkedQuote = findLabourQuoteById(quotes, job.linkedQuoteId);
    final canAccessLabour = ref.watch(canAccessLabourCalculatorProvider);

    final subtitleParts = <String>[
      tileName,
      job.status.label,
      if (linkedQuote != null) 'Quote: ${linkedQuote.name}',
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(job.projectName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitleParts.join(' · ')),
            if (linkedQuote != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => navigateToLabourCalculatorWithQuote(
                    context,
                    linkedQuote.id,
                    canAccessLabour: canAccessLabour,
                  ),
                  child: const Text('Open quote'),
                ),
              ),
          ],
        ),
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