import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_flow_step.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_flow_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_pdf_exporter.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/saved_result_labour_adapter.dart';
import 'package:roofgrid_uk/app/labour_pricing/utils/labour_quote_lookup.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/labour/steps/labour_materials_step.dart';
import 'package:roofgrid_uk/screens/labour/steps/labour_project_step.dart';
import 'package:roofgrid_uk/screens/labour/steps/labour_quote_step.dart';
import 'package:roofgrid_uk/screens/labour/steps/labour_results_step.dart';
import 'package:roofgrid_uk/screens/labour/steps/labour_sections_step.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_step_progress.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/labour/labour_import_summary_dialog.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:share_plus/share_plus.dart';

class LabourPricingCalculatorScreen extends ConsumerStatefulWidget {
  final LabourQuoteProject? initialProject;
  final LabourQuoteConfig? initialQuoteConfig;
  final String? importJobId;
  final String? loadQuoteId;
  final void Function(LabourSavedQuote quote)? onQuoteSaved;

  const LabourPricingCalculatorScreen({
    super.key,
    this.initialProject,
    this.initialQuoteConfig,
    this.importJobId,
    this.loadQuoteId,
    this.onQuoteSaved,
  });

  @override
  ConsumerState<LabourPricingCalculatorScreen> createState() =>
      _LabourPricingCalculatorScreenState();
}

class _LabourPricingCalculatorScreenState
    extends ConsumerState<LabourPricingCalculatorScreen> {
  bool _isExportingPdf = false;
  bool _hostHandoffApplied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyHostHandoff());
  }

  void _syncFlowStepAfterLoad({bool hasResult = false}) {
    ref.read(labourFlowProvider.notifier).goTo(
          hasResult ? LabourFlowStep.results : LabourFlowStep.project,
        );
  }

  Future<void> _applyHostHandoff() async {
    if (_hostHandoffApplied || !mounted) return;
    _hostHandoffApplied = true;

    final notifier = ref.read(labourPricingProvider.notifier);

    if (widget.initialProject != null) {
      notifier.loadInitialProject(
        widget.initialProject!,
        quoteConfig: widget.initialQuoteConfig,
      );
      _syncFlowStepAfterLoad(
        hasResult: ref.read(labourPricingProvider).result != null,
      );
      return;
    }

    final quoteId = widget.loadQuoteId?.trim();
    if (quoteId != null && quoteId.isNotEmpty) {
      final quotes = await ref.read(labourQuotesProvider.future);
      final quote = findLabourQuoteById(quotes, quoteId);
      if (!mounted) return;
      if (quote == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find saved quote to load')),
        );
        return;
      }
      notifier.loadQuote(quote);
      _syncFlowStepAfterLoad(
        hasResult: ref.read(labourPricingProvider).result != null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loaded "${quote.name}"')),
      );
      return;
    }

    final jobId = widget.importJobId?.trim();
    if (jobId == null || jobId.isEmpty) return;

    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null || userId.isEmpty) return;

    final results = await ref.read(savedResultsProvider(userId).future);
    SavedResult? match;
    for (final result in results) {
      if (result.id == jobId) {
        match = result;
        break;
      }
    }
    if (!mounted) return;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find saved job to import')),
      );
      return;
    }

    final count = notifier.importFromSavedResult(match);
    if (!mounted) return;
    if (count == null || count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved job could not be imported')),
      );
      return;
    }
    ref.read(labourFlowProvider.notifier).goTo(LabourFlowStep.project);
    final summary =
        SavedResultLabourAdapter.importSummaryFromSavedResult(match);
    if (summary != null) {
      await showLabourImportSummaryDialog(context, summary);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count section(s) from saved job')),
      );
    }
  }

  void _openCustomerQuote() {
    final canAccessCustomerQuote = ref.read(canAccessCustomerQuoteProvider);
    if (canAccessCustomerQuote) {
      navigateToCustomerQuotePreview(context);
      return;
    }
    showCustomerQuoteGateSnackBar(context);
    context.go(customerQuoteUpsellPath);
  }

  Future<void> _exportPdf() async {
    final state = ref.read(labourPricingProvider);
    final result = state.result;
    if (result == null) return;

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await LabourQuotePdfExporter.generateBytes(
        project: state.project,
        config: state.quoteConfig,
        projectResult: state.projectResult!,
        importedFrom: state.importedProjectName,
      );
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/roofgrid_labour_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(path).writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/pdf')],
          text: 'RoofGrid UK Labour Quote',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _showSaveQuoteDialog() async {
    final nameController = TextEditingController(
      text: ref.read(labourPricingProvider).project.customerName.trim().isNotEmpty
          ? ref.read(labourPricingProvider).project.customerName.trim()
          : 'Labour quote',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Save quote'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Quote name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true || !mounted) {
      nameController.dispose();
      return;
    }

    final quote = await ref
        .read(labourPricingProvider.notifier)
        .saveCurrentQuote(nameController.text);
    nameController.dispose();

    if (!mounted) return;
    if (quote != null) {
      widget.onQuoteSaved?.call(quote);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          quote != null
              ? 'Saved "${quote.name}"'
              : 'Enter a quote name to save',
        ),
      ),
    );
  }

  Widget _buildStepBody(LabourFlowStep step) {
    switch (step) {
      case LabourFlowStep.project:
        return const LabourProjectStep();
      case LabourFlowStep.materials:
        return const LabourMaterialsStep();
      case LabourFlowStep.sections:
        return const LabourSectionsStep();
      case LabourFlowStep.quote:
        return LabourQuoteStep(onSaveQuote: _showSaveQuoteDialog);
      case LabourFlowStep.results:
        return LabourResultsStep(onOpenCustomerQuote: _openCustomerQuote);
    }
  }

  Widget _buildSummaryChip() {
    final state = ref.watch(labourPricingProvider);
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');
    final sectionCount = state.project.sections.length;
    final total = state.projectResult?.activeQuoteTotalGbp;

    if (total == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizontalPadding(context),
        vertical: 6,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                '$sectionCount section${sectionCount == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                gbp.format(total),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardFooter(LabourFlowStep step) {
    final flow = ref.read(labourFlowProvider.notifier);
    final validation = flow.validationMessageForAdvance();
    final horizontalPadding = screenHorizontalPadding(context);

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 12),
          child: Row(
            children: [
              if (step.previous != null)
                OutlinedButton(
                  onPressed: flow.retreat,
                  child: const Text('Back'),
                )
              else
                const SizedBox(width: 80),
              const Spacer(),
              if (step == LabourFlowStep.quote)
                FilledButton.icon(
                  onPressed: () => calculateLabourQuote(context, ref),
                  icon: const Icon(Icons.calculate_rounded),
                  label: const Text('Calculate'),
                )
              else if (step == LabourFlowStep.results)
                FilledButton(
                  onPressed: () => flow.goTo(LabourFlowStep.quote),
                  child: const Text('Edit quote'),
                )
              else
                FilledButton(
                  onPressed: validation == null
                      ? flow.advance
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(validation)),
                          );
                        },
                  child: Text(step == LabourFlowStep.sections ? 'Continue' : 'Next'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWizardShell() {
    final step = ref.watch(labourFlowProvider);
    final compactProgress = isNarrowLayout(context);
    final horizontalPadding = screenHorizontalPadding(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 0),
          child: LabourStepProgress(
            currentStep: step,
            compact: compactProgress,
          ),
        ),
        _buildSummaryChip(),
        Expanded(
          child: constrainContentWidth(
            context,
            _buildStepBody(step),
          ),
        ),
        _buildWizardFooter(step),
      ],
    );
  }

  Widget _buildLegacyScroll() {
    final state = ref.watch(labourPricingProvider);
    final horizontalPadding = screenHorizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 32),
      children: [
        const LabourProjectStep(embedded: true),
        const SizedBox(height: 24),
        const LabourMaterialsStep(embedded: true),
        const SizedBox(height: 24),
        const LabourSectionsStep(embedded: true),
        const SizedBox(height: 24),
        LabourQuoteStep(
          embedded: true,
          onSaveQuote: _showSaveQuoteDialog,
        ),
        const SizedBox(height: 24),
        LabourResultsStep(
          embedded: true,
          onOpenCustomerQuote: _openCustomerQuote,
        ),
        if (state.result != null) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final message =
                  ref.read(labourPricingProvider.notifier).recalculate();
              if (!mounted) return;
              if (message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recalculate'),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(labourPricingProvider);
    final backendHydrated = ref.watch(labourBackendProvider).isHydrated;
    final useWizard = useLabourWizardLayout(context);

    if (!backendHydrated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Labour Pricing'),
        actions: [
          if (state.result != null) ...[
            IconButton(
              icon: const Icon(Icons.description_outlined),
              tooltip: 'Customer quote',
              onPressed: _openCustomerQuote,
            ),
            IconButton(
              icon: _isExportingPdf
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Internal breakdown PDF',
              onPressed: _isExportingPdf ? null : _exportPdf,
            ),
          ],
          const HomeBackButton(),
        ],
      ),
      drawer: const MainDrawer(),
      body: useWizard ? _buildWizardShell() : _buildLegacyScroll(),
    );
  }
}