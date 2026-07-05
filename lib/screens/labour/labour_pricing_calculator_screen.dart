import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/app/auth/providers/permissions_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_pdf_exporter.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/saved_result_labour_adapter.dart';
import 'package:roofgrid_uk/widgets/labour/labour_import_summary_dialog.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/navigation/nav_utils.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_decimal_text_field.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_int_text_field.dart';
import 'package:roofgrid_uk/app/labour_pricing/utils/labour_quote_lookup.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_linked_job_banner.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_project_materials_panel.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_quotes_sync_chip.dart';
import 'package:roofgrid_uk/screens/labour/widgets/labour_section_panel.dart';
import 'package:roofgrid_uk/widgets/section_header.dart';
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

  Future<void> _applyHostHandoff() async {
    if (_hostHandoffApplied || !mounted) return;
    _hostHandoffApplied = true;

    final notifier = ref.read(labourPricingProvider.notifier);

    if (widget.initialProject != null) {
      notifier.loadInitialProject(
        widget.initialProject!,
        quoteConfig: widget.initialQuoteConfig,
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

  Future<void> _pickQuoteDate(DateTime? current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    ref.read(labourPricingProvider.notifier).updateProject(
          ref.read(labourPricingProvider).project.copyWith(quoteDate: picked),
        );
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

  void _showImportPicker() {
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
                                  if (!mounted) return;
                                  if (sectionCount == null || sectionCount <= 0) {
                                    ScaffoldMessenger.of(this.context)
                                        .showSnackBar(
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
                                      this.context,
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

  Future<void> _confirmDeleteQuote(LabourSavedQuote quote) async {
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

    if (confirmed != true || !mounted) return;

    final deleted =
        await ref.read(labourPricingProvider.notifier).deleteSavedQuote(quote.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted ? 'Deleted "${quote.name}"' : 'Could not delete quote',
        ),
      ),
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
  Widget build(BuildContext context) {
    final state = ref.watch(labourPricingProvider);
    final savedQuotesAsync = ref.watch(labourQuotesProvider);
    final backendHydrated = ref.watch(labourBackendProvider).isHydrated;
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final notifier = ref.read(labourPricingProvider.notifier);
    final gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£');

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          const SectionHeader(
            title: 'Project quote',
            subtitle:
                'Add roof sections, then calculate your profitable day rate',
          ),
          if (state.sourceJobId != null && state.sourceJobId!.isNotEmpty) ...[
            const SizedBox(height: 12),
            LabourLinkedJobBanner(jobId: state.sourceJobId!),
          ],
          const SizedBox(height: 16),
          const HeaderWidget(title: 'Project details'),
          const SizedBox(height: 12),
          _TextField(
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
            onTap: () => _pickQuoteDate(state.project.quoteDate),
          ),
          const SizedBox(height: 12),
          _TextField(
            label: 'Customer name',
            value: state.project.customerName,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(customerName: value),
            ),
          ),
          const SizedBox(height: 12),
          _TextField(
            label: 'Site address',
            value: state.project.siteAddress,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(siteAddress: value),
            ),
          ),
          const SizedBox(height: 12),
          _TextField(
            label: 'Access notes',
            value: state.project.accessNotes,
            onChanged: (value) => notifier.updateProject(
              state.project.copyWith(accessNotes: value),
            ),
          ),
          const SizedBox(height: 12),
          _TextField(
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
            onPressed: _showImportPicker,
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
          const SizedBox(height: 20),
          const HeaderWidget(title: 'My quotes'),
          if (userId != null && userId.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: LabourQuotesSyncChip(),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showSaveQuoteDialog,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save current quote'),
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
              return Column(
                children: quotes.map((quote) {
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
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Loaded "${quote.name}"'),
                                ),
                              );
                            case 'duplicate':
                              final messenger = ScaffoldMessenger.of(context);
                              final duplicate = await notifier
                                  .duplicateSavedQuote(quote.id);
                              if (!mounted) return;
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
                              await _confirmDeleteQuote(quote);
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
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text(
              'Could not load saved quotes: $error',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          if (!effectiveIsPro)
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
          if (!effectiveIsPro) const SizedBox(height: 16),
          const HeaderWidget(title: 'Project materials'),
          const SizedBox(height: 12),
          const LabourProjectMaterialsPanel(),
          const SizedBox(height: 20),
          const HeaderWidget(title: 'Roof sections'),
          const SizedBox(height: 12),
          const LabourSectionList(),
          const SizedBox(height: 20),
          const HeaderWidget(title: 'Gang & uplifts'),
          const SizedBox(height: 12),
          LabourIntTextField(
            label: 'Gang size',
            value: state.quoteConfig.gangSize,
            onChanged: (value) => notifier.updateQuoteConfig(
              state.quoteConfig.copyWith(gangSize: value),
            ),
          ),
          LabourDecimalTextField(
            label: 'Difficulty uplift (%)',
            value: state.quoteConfig.difficultyUpliftPercent,
            onChanged: (value) => notifier.updateQuoteConfig(
              state.quoteConfig.copyWith(difficultyUpliftPercent: value),
            ),
          ),
          LabourDecimalTextField(
            label: 'Travel miles (one way)',
            value: state.quoteConfig.travelMiles,
            onChanged: (value) => notifier.updateQuoteConfig(
              state.quoteConfig.copyWith(travelMiles: value),
            ),
          ),
          LabourIntTextField(
            label: 'Overnight nights',
            value: state.quoteConfig.overnightNights,
            onChanged: (value) => notifier.updateQuoteConfig(
              state.quoteConfig.copyWith(overnightNights: value),
            ),
          ),
          LabourDecimalTextField(
            label: 'Target margin (%)',
            value: state.quoteConfig.targetMarginPercent,
            onChanged: (value) => notifier.updateQuoteConfig(
              state.quoteConfig.copyWith(targetMarginPercent: value),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/profile?tab=labour-rates'),
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Edit rates in Profile'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              final message = notifier.recalculate();
              if (!mounted) return;
              if (message != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('Calculate quote'),
          ),
          if (state.projectResult != null) ...[
            const SizedBox(height: 24),
            const HeaderWidget(title: 'Project methods'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MethodTotalCard(
                    title: 'Method A',
                    subtitle: 'All sections rate-based',
                    totalGbp: state.projectResult!.methodATotalGbp,
                    isSelected: false,
                    gbp: gbp,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MethodTotalCard(
                    title: 'Method B',
                    subtitle: 'All sections timing-based',
                    totalGbp: state.projectResult!.methodBTotalGbp,
                    isSelected: false,
                    gbp: gbp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const HeaderWidget(title: 'Project total'),
            const SizedBox(height: 12),
            _ResultHighlight(
              label: 'Quote total',
              value: gbp.format(state.projectResult!.activeQuoteTotalGbp),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openCustomerQuote,
                icon: const Icon(Icons.description_outlined),
                label: Text(
                  ref.watch(canAccessCustomerQuoteProvider)
                      ? 'Open customer quote preview'
                      : 'Unlock customer quote PDF',
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ResultRow(
              label: 'Profitable day rate / man',
              value: gbp.format(
                state.projectResult!.rollup.profitableDayRatePerManGbp,
              ),
            ),
            _ResultRow(
              label: 'Profitable day rate / gang',
              value: gbp.format(
                state.projectResult!.rollup.profitableDayRatePerGangGbp,
              ),
            ),
            _ResultRow(
              label: 'Man-days (gang)',
              value: state.projectResult!.rollup.manDays.toStringAsFixed(2),
            ),
            _ResultRow(
              label: 'Total hours',
              value:
                  state.projectResult!.rollup.upliftedHours.toStringAsFixed(1),
            ),
            _ResultRow(
              label: 'Labour cost',
              value: gbp.format(state.projectResult!.rollup.baseLabourCostGbp),
            ),
            if (state.projectResult!.rollup.travelCostGbp > 0)
              _ResultRow(
                label: 'Travel',
                value: gbp.format(state.projectResult!.rollup.travelCostGbp),
              ),
            if (state.projectResult!.rollup.overnightCostGbp > 0)
              _ResultRow(
                label: 'Overnight',
                value:
                    gbp.format(state.projectResult!.rollup.overnightCostGbp),
              ),
            if (state.project.contingencyPercent > 0)
              _ResultRow(
                label: 'Contingency',
                value: gbp.format(state.projectResult!.contingencyCostGbp),
              ),
            const SizedBox(height: 16),
            const HeaderWidget(title: 'Section totals'),
            const SizedBox(height: 8),
            ...state.projectResult!.sectionResults.map(
              (sectionResult) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sectionResult.section.label,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sectionResult.section.selectedMethod.shortLabel,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      _ResultRow(
                        label: 'Section labour',
                        value: gbp.format(sectionResult.activeLabourCostGbp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _TextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFocused && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => _isFocused = focused,
      child: TextFormField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _MethodTotalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double totalGbp;
  final bool isSelected;
  final NumberFormat gbp;

  const _MethodTotalCard({
    required this.title,
    required this.subtitle,
    required this.totalGbp,
    required this.isSelected,
    required this.gbp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.outline.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? colorScheme.secondary.withValues(alpha: 0.08)
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gbp.format(totalGbp),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultHighlight extends StatelessWidget {
  final String label;
  final String value;

  const _ResultHighlight({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins()),
          Text(
            value,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}