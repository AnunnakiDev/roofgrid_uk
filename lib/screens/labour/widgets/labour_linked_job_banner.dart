import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

class LabourLinkedJobBanner extends ConsumerWidget {
  final String jobId;

  const LabourLinkedJobBanner({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider).value?.id;
    if (userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    final resultsAsync = ref.watch(savedResultsProvider(userId));
    return resultsAsync.when(
      data: (results) {
        SavedResult? linked;
        for (final result in results) {
          if (result.id == jobId) {
            linked = result;
            break;
          }
        }
        if (linked == null) return const SizedBox.shrink();

        final label = linked.projectName.trim().isNotEmpty
            ? linked.projectName
            : 'Saved job';

        return Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/result-detail', extra: linked),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.link_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Linked to job: $label',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}