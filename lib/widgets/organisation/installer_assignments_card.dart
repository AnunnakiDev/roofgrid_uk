import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class InstallerAssignmentsCard extends ConsumerWidget {
  const InstallerAssignmentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myJobAssignmentsProvider);

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
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
            ...assignments.map(
              (assignment) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(assignment.projectName),
                  subtitle: Text('Status: ${assignment.status.name}'),
                  trailing: const Icon(Icons.arrow_forward_rounded),
                  onTap: () => _openAssignment(context, ref, assignment.savedResultId),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _openAssignment(
    BuildContext context,
    WidgetRef ref,
    String savedResultId,
  ) async {
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null) return;
    final results = await ref.read(savedResultsProvider(userId).future);
    for (final result in results) {
      if (result.id != savedResultId) continue;
      if (!context.mounted) return;
      context.push('/result-detail', extra: result);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Assigned job not found on this device')),
    );
  }
}