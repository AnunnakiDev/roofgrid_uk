import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/saved_result_labour_adapter.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_linked_job_banner.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_text_field.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/labour/labour_import_summary_dialog.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';

class LabourProjectStep extends ConsumerWidget {
  final bool embedded;

  const LabourProjectStep({super.key, this.embedded = false});

  Future<void> _pickQuoteDate(
    BuildContext context,
    WidgetRef ref,
    DateTime? current,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !context.mounted) return;
    ref.read(labourPricingProvider.notifier).updateProject(
          ref.read(labourPricingProvider).project.copyWith(quoteDate: picked),
        );
  }

  void _showImportPicker(BuildContext context, WidgetRef ref) {
    final effectiveIsPro = ref.read(effectiveIsProProvider);
    if (!effectiveIsPro) {
      showProGateSnackBar(context);
      context.go('/subscription');
      return;
    }

    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null || userId.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final resultsAsync = ref.watch(savedResultsProvider(userId));
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import from saved job',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    resultsAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return Text(
                            'No saved jobs found. Save a set-out calculation first.',
                            style: GoogleFonts.poppins(),
                          );
                        }
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(sheetContext).size.height * 0.45,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final job = results[index];
                              return ListTile(
                                title: Text(job.projectName),
                                subtitle: Text(_savedJobSubtitle(job)),
                                onTap: () async {
                                  final sectionCount = ref
                                      .read(labourPricingProvider.notifier)
                                      .importFromSavedResult(job);
                                  Navigator.pop(sheetContext);
                                  if (!context.mounted) return;
                                  if (sectionCount == null || sectionCount <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not import "${job.projectName}"',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final summary =
                                      SavedResultLabourAdapter
                                          .importSummaryFromSavedResult(job);
                                  if (summary != null) {
                                    await showLabourImportSummaryDialog(
                                      context,
                                      summary,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => Text('Error loading jobs: $error'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _savedJobSubtitle(SavedResult job) {
    final type = switch (job.type) {
      CalculationType.vertical => 'Vertical',
      CalculationType.horizontal => 'Horizontal',
      CalculationType.combined => 'Combined',
    };
    return '$type · ${DateFormat('d MMM yyyy').format(job.createdAt)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labourPricingProvider);
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final notifier = ref.read(labourPricingProvider.notifier);
    final horizontalPadding = screenHorizontalPadding(context);

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Project details',
            subtitle: 'Customer, site, and quote reference',
          ),
          if (state.sourceJobId != null && state.sourceJobId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            LabourLinkedJobBanner(jobId: state.sourceJobId!),
          ],
          const SizedBox(height: 16),
          LabourTextField(
            label: 'Quote reference',
            value: state.project.quoteRef,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(quoteRef: value),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Quote date', style: GoogleFonts.poppins()),
            subtitle: Text(
              DateFormat('d MMMM yyyy')
                  .format(state.project.quoteDate ?? DateTime.now()),
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () => _pickQuoteDate(context, ref, state.project.quoteDate),
          ),
          const SizedBox(height: 12),
          LabourTextField(
            label: 'Customer name',
            value: state.project.customerName,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(customerName: value),
            ),
          ),
          const SizedBox(height: 12),
          LabourTextField(
            label: 'Site address',
            value: state.project.siteAddress,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(siteAddress: value),
            ),
          ),
          const SizedBox(height: 12),
          LabourTextField(
            label: 'Access notes',
            value: state.project.accessNotes,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(accessNotes: value),
            ),
          ),
          const SizedBox(height: 12),
          LabourTextField(
            label: 'Scaffold notes',
            value: state.project.scaffoldNotes,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(scaffoldNotes: value),
            ),
          ),
          const SizedBox(height: 12),
          LabourDecimalTextField(
            label: 'Contingency (%)',
            value: state.project.contingencyPercent,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(contingencyPercent: value),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showImportPicker(context, ref),
            icon: Icon(
              effectiveIsPro ? Icons.download_rounded : Icons.lock_outline,
            ),
            label: Text(
              effectiveIsPro
                  ? 'Import from saved job'
                  : 'Import from saved job (Pro)',
            ),
          ),
          if (state.importedProjectName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Imported: ${state.importedProjectName} '
              '(${state.project.sections.length} section'
              '${state.project.sections.length == 1 ? '' : 's'})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (!effectiveIsPro) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Set-out Pro is required to import saved jobs. '
                        'You can still quote manually here.',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );

    if (embedded) return content;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        24,
      ),
      child: content,
    );
  }
}