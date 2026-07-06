import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_flow_step.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_flow_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';

Future<void> showLabourSavedQuotesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _LabourSavedQuotesSheet(),
  );
}

class _LabourSavedQuotesSheet extends ConsumerWidget {
  const _LabourSavedQuotesSheet();

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    LabourSavedQuote quote,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete quote?'),
          content: Text('Delete "${quote.name}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final deleted =
        await ref.read(labourPricingProvider.notifier).deleteSavedQuote(quote.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Deleted "${quote.name}"' : 'Could not delete quote',
        ),
      ),
    );
  }

  void _goToStepAfterLoad(WidgetRef ref, bool hasResult) {
    final flow = ref.read(labourFlowProvider.notifier);
    if (hasResult) {
      flow.goTo(LabourFlowStep.results);
    } else {
      flow.goTo(LabourFlowStep.quote);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedQuotesAsync = ref.watch(labourQuotesProvider);
    final notifier = ref.read(labourPricingProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved quotes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            savedQuotesAsync.when(
              data: (quotes) {
                if (quotes.isEmpty) {
                  return Text(
                    'No saved quotes yet. Save your current project to reload it later.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: quotes.length,
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            quote.name,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${quote.project.sections.length} section'
                            '${quote.project.sections.length == 1 ? '' : 's'} · '
                            '${DateFormat('d MMM yyyy').format(quote.savedAt)}',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) async {
                              switch (action) {
                                case 'load':
                                  notifier.loadQuote(quote);
                                  _goToStepAfterLoad(
                                    ref,
                                    ref.read(labourPricingProvider).result != null,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Loaded "${quote.name}"'),
                                      ),
                                    );
                                  }
                                case 'duplicate':
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final duplicate = await notifier
                                      .duplicateSavedQuote(quote.id);
                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        duplicate != null
                                            ? 'Duplicated as "${duplicate.name}"'
                                            : 'Could not duplicate quote',
                                      ),
                                    ),
                                  );
                                case 'delete':
                                  await _confirmDelete(context, ref, quote);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'load',
                                child: Text('Load'),
                              ),
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text(
                'Could not load saved quotes: $error',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}