import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_dual_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_project_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_materials_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_saved_quote.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_backend_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_materials_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_quotes_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/utils/labour_quote_lookup.dart';
import 'package:roofgrid_uk/app/organisation/providers/organisation_provider.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/boq_suggestion_service.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_pricing_engine.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_validation.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/saved_result_labour_adapter.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

class LabourPricingState {
  final LabourQuoteProject project;
  final LabourQuoteConfig quoteConfig;
  final LabourProjectResult? projectResult;
  final String? importedProjectName;
  final String? sourceJobId;

  const LabourPricingState({
    required this.project,
    required this.quoteConfig,
    this.projectResult,
    this.importedProjectName,
    this.sourceJobId,
  });

  factory LabourPricingState.initial() {
    return LabourPricingState(
      project: LabourQuoteProject.initial(),
      quoteConfig: const LabourQuoteConfig(),
    );
  }

  /// Active project rollup — used for PDF export and summary.
  LabourQuoteResult? get result => projectResult?.rollup;

  /// First section input — convenience for single-section import flows.
  LabourQuoteInput get input =>
      project.sections.first.input;

  LabourDualQuoteResult? get dualResult =>
      projectResult?.sectionResults.isNotEmpty == true
          ? projectResult!.sectionResults.first.dualResult
          : null;

  LabourQuoteMethod get selectedMethod =>
      project.sections.first.selectedMethod;

  LabourPricingState copyWith({
    LabourQuoteProject? project,
    LabourQuoteConfig? quoteConfig,
    LabourProjectResult? projectResult,
    String? importedProjectName,
    String? sourceJobId,
    bool clearResult = false,
    bool clearImport = false,
    bool clearSourceJob = false,
  }) {
    return LabourPricingState(
      project: project ?? this.project,
      quoteConfig: quoteConfig ?? this.quoteConfig,
      projectResult: clearResult ? null : (projectResult ?? this.projectResult),
      importedProjectName:
          clearImport ? null : (importedProjectName ?? this.importedProjectName),
      sourceJobId: clearSourceJob ? null : (sourceJobId ?? this.sourceJobId),
    );
  }
}

class LabourPricingNotifier extends Notifier<LabourPricingState> {
  int _sectionCounter = 1;

  @override
  LabourPricingState build() {
    ref.listen(labourBackendProvider, (previous, next) {
      if (previous == null) {
        state = state.copyWith(quoteConfig: next.quoteConfig);
        return;
      }
      if (previous.quoteConfig != next.quoteConfig) {
        state = state.copyWith(quoteConfig: next.quoteConfig);
      }
      if (previous.backendData != next.backendData && state.projectResult != null) {
        _recalculateSilent();
      }
    });

    ref.listen(labourMaterialsProvider, (previous, next) {
      if (previous?.entries != next.entries && state.projectResult != null) {
        _recalculateSilent();
      }
    });

    return LabourPricingState.initial();
  }

  void updateProjectMaterialLines(List<LabourMaterialLine> lines) {
    state = state.copyWith(
      project: state.project.copyWith(projectMaterialLines: lines),
      clearResult: state.projectResult == null,
    );
    if (state.projectResult != null) _recalculateSilent();
  }

  void updateSectionMaterialLines(
    String sectionId,
    List<LabourMaterialLine> lines, {
    SectionMaterialsMode? materialsMode,
  }) {
    _mapSection(
      sectionId,
      (section) => section.copyWith(
        materialLines: lines,
        materialsMode:
            materialsMode ?? SectionMaterialsMode.sectionOverride,
      ),
      recalculate: state.projectResult != null,
    );
  }

  void setSectionMaterialsMode(String sectionId, SectionMaterialsMode mode) {
    _mapSection(
      sectionId,
      (section) => section.copyWith(materialsMode: mode),
      recalculate: state.projectResult != null,
    );
  }

  int applyBoqSuggestions(String sectionId) {
    final section = state.project.sectionById(sectionId);
    if (section == null) return 0;

    final priceList = ref.read(labourMaterialsProvider).entries;
    final suggested = BoqSuggestionService.suggestForSection(
      section: section,
      priceList: priceList,
    );
    if (suggested.isEmpty) return 0;

    updateSectionMaterialLines(sectionId, suggested);
    return suggested.length;
  }

  int applyProjectBoq() {
    final priceList = ref.read(labourMaterialsProvider).entries;
    final suggested = BoqSuggestionService.suggestForProject(
      project: state.project,
      priceList: priceList,
    );
    if (suggested.isEmpty) return 0;

    updateProjectMaterialLines(suggested);
    return suggested.length;
  }

  void updateQuoteConfig(LabourQuoteConfig quoteConfig) {
    ref.read(labourBackendProvider.notifier).updateQuoteConfig(quoteConfig);
    state = state.copyWith(quoteConfig: quoteConfig, clearResult: true);
  }

  void updateProject(LabourQuoteProject project) {
    state = state.copyWith(project: project, clearResult: true);
  }

  void updateSection(String sectionId, LabourRoofSection section) {
    _mapSection(sectionId, (_) => section);
  }

  void updateSectionInput(String sectionId, LabourQuoteInput input) {
    _mapSection(
      sectionId,
      (section) => section.copyWith(input: input),
    );
  }

  void updateSectionLabel(String sectionId, String label) {
    _mapSection(
      sectionId,
      (section) => section.copyWith(label: label),
    );
  }

  void setSectionMethod(String sectionId, LabourQuoteMethod method) {
    _mapSection(
      sectionId,
      (section) => section.copyWith(
        selectedMethod: method,
        clearManualOverrideGbp: method != LabourQuoteMethod.manualOverride,
      ),
      recalculate: state.projectResult != null,
    );
  }

  void setSectionManualOverride(String sectionId, double? gbp) {
    _mapSection(
      sectionId,
      (section) => section.copyWith(
        manualOverrideGbp: gbp,
        selectedMethod: LabourQuoteMethod.manualOverride,
      ),
      recalculate: state.projectResult != null,
    );
  }

  void addSection() {
    _sectionCounter += 1;
    final id = 'section-$_sectionCounter';
    final next = [
      ...state.project.sections,
      LabourRoofSection.initial(
        id: id,
        label: 'Section ${state.project.sections.length + 1}',
      ),
    ];
    state = state.copyWith(
      project: state.project.copyWith(sections: next),
      clearResult: true,
    );
  }

  void duplicateSection(String sectionId) {
    final source = state.project.sectionById(sectionId);
    if (source == null) return;

    _sectionCounter += 1;
    final id = 'section-$_sectionCounter';
    final duplicate = source.copyWith(
      id: id,
      label: '${source.label} (copy)',
    );
    final index = state.project.sections.indexWhere((s) => s.id == sectionId);
    final next = [...state.project.sections];
    next.insert(index + 1, duplicate);

    state = state.copyWith(
      project: state.project.copyWith(sections: next),
      clearResult: true,
    );
  }

  void removeSection(String sectionId) {
    if (state.project.sections.length <= 1) return;

    final next =
        state.project.sections.where((s) => s.id != sectionId).toList();
    state = state.copyWith(
      project: state.project.copyWith(sections: next),
      clearResult: true,
    );
  }

  void moveSectionUp(String sectionId) {
    _moveSection(sectionId, -1);
  }

  void moveSectionDown(String sectionId) {
    _moveSection(sectionId, 1);
  }

  void _moveSection(String sectionId, int direction) {
    final sections = [...state.project.sections];
    final index = sections.indexWhere((s) => s.id == sectionId);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= sections.length) return;

    final item = sections.removeAt(index);
    sections.insert(target, item);
    state = state.copyWith(
      project: state.project.copyWith(sections: sections),
      clearResult: state.projectResult == null,
    );
    if (state.projectResult != null) _recalculateSilent();
  }

  void loadInitialProject(
    LabourQuoteProject project, {
    LabourQuoteConfig? quoteConfig,
    String? importedProjectName,
  }) {
    _syncSectionCounter(project.sections);
    state = state.copyWith(
      project: project,
      quoteConfig: quoteConfig ?? state.quoteConfig,
      importedProjectName: importedProjectName,
      clearResult: true,
    );
    if (quoteConfig != null) {
      ref.read(labourBackendProvider.notifier).updateQuoteConfig(quoteConfig);
    }
  }

  /// Legacy — updates the first section input.
  void updateInput(LabourQuoteInput input) {
    final firstId = state.project.sections.first.id;
    updateSectionInput(firstId, input);
  }

  /// Legacy — sets method on the first section.
  void setSelectedMethod(LabourQuoteMethod method) {
    final firstId = state.project.sections.first.id;
    setSectionMethod(firstId, method);
  }

  /// Returns imported section count, or null when import fails.
  int? importFromSavedResult(SavedResult result) {
    final imported = SavedResultLabourAdapter.projectFromSavedResult(result);
    if (imported == null || imported.sections.isEmpty) return null;

    _syncSectionCounter(imported.sections);

    state = state.copyWith(
      project: state.project.copyWith(
        sections: imported.sections,
        customerName: imported.customerName.isNotEmpty
            ? imported.customerName
            : result.projectName,
        quoteRef: state.project.quoteRef,
        siteAddress: state.project.siteAddress,
        accessNotes: state.project.accessNotes,
        scaffoldNotes: state.project.scaffoldNotes,
        contingencyPercent: state.project.contingencyPercent,
      ),
      importedProjectName: result.projectName,
      sourceJobId: result.id,
      clearResult: true,
    );
    return imported.sections.length;
  }

  Future<LabourSavedQuote?> saveCurrentQuote(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;

    final quote = LabourSavedQuote(
      id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      savedAt: DateTime.now(),
      project: state.project,
      quoteConfig: state.quoteConfig,
      importedProjectName: state.importedProjectName,
      sourceJobId: state.sourceJobId,
    );
    final saved = await ref.read(labourQuotesProvider.notifier).saveQuote(quote);

    final jobId = state.sourceJobId;
    if (saved != null && jobId != null && jobId.isNotEmpty) {
      try {
        final userId = ref.read(currentUserProvider).value?.id;
        if (userId != null) {
          final results =
              await ref.read(savedResultsProvider(userId).future);
          SavedResult? job;
          for (final entry in results) {
            if (entry.id == jobId) {
              job = entry;
              break;
            }
          }
          if (job != null) {
            await ref.read(resultsServiceProvider).linkQuoteToJob(
                  result: job,
                  quoteId: saved.id,
                );
          }
          final orgId = ref.read(currentUserProvider).value?.primaryOrgId;
          if (orgId != null && orgId.isNotEmpty) {
            await ref.read(orgJobServiceProvider).linkQuote(
                  orgId: orgId,
                  jobId: jobId,
                  quoteId: saved.id,
                );
          }
        }
      } catch (_) {
        // Linking is best-effort; quote is still saved locally/cloud.
      }
    }
    return saved;
  }

  void loadQuote(LabourSavedQuote quote) {
    _syncSectionCounter(quote.project.sections);
    state = state.copyWith(
      project: quote.project,
      quoteConfig: quote.quoteConfig,
      importedProjectName: quote.importedProjectName,
      sourceJobId: quote.sourceJobId,
      clearResult: true,
    );
    ref.read(labourBackendProvider.notifier).updateQuoteConfig(quote.quoteConfig);
  }

  Future<bool> deleteSavedQuote(String id) async {
    final deleted =
        await ref.read(labourQuotesProvider.notifier).deleteQuote(id);
    if (!deleted) return false;

    await _clearQuoteJobLinks(id);
    return true;
  }

  Future<void> _clearQuoteJobLinks(String quoteId) async {
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId == null || userId.isEmpty) return;

    try {
      final results = await ref.read(savedResultsProvider(userId).future);
      final resultsService = ref.read(resultsServiceProvider);
      for (final result in savedResultsLinkedToQuote(results, quoteId)) {
        await resultsService.unlinkQuoteFromJob(result: result);
      }

      final orgId = ref.read(currentUserProvider).value?.primaryOrgId;
      if (orgId != null && orgId.isNotEmpty) {
        final orgJobs = ref.read(orgJobsProvider).value ?? const [];
        final orgJobService = ref.read(orgJobServiceProvider);
        for (final job in orgJobsLinkedToQuote(orgJobs, quoteId)) {
          await orgJobService.unlinkQuote(orgId: orgId, jobId: job.id);
        }
      }
    } catch (_) {
      // Local quote is deleted; link cleanup is best-effort.
    }
  }

  Future<LabourSavedQuote?> duplicateSavedQuote(String id) {
    return ref.read(labourQuotesProvider.notifier).duplicateQuote(id);
  }

  void _syncSectionCounter(List<LabourRoofSection> sections) {
    var max = 1;
    for (final section in sections) {
      final match = RegExp(r'section-(\d+)').firstMatch(section.id);
      if (match == null) continue;
      final parsed = int.tryParse(match.group(1)!);
      if (parsed != null && parsed > max) {
        max = parsed;
      }
    }
    _sectionCounter = max;
  }

  /// Returns an error message when calculation cannot run, or null on success.
  String? recalculate() {
    final validationError =
        LabourQuoteValidation.validateForCalculate(state.project);
    if (validationError != null) return validationError;

    final backend = ref.read(labourBackendProvider).backendData;
    final projectResult = LabourPricingEngine.calculateProject(
      project: state.project,
      backend: backend,
      config: state.quoteConfig,
    );
    state = state.copyWith(projectResult: projectResult);
    return LabourQuoteValidation.warningForSkippedSections(state.project);
  }

  void _recalculateSilent() {
    if (!state.project.hasQuantities) return;
    final backend = ref.read(labourBackendProvider).backendData;
    final projectResult = LabourPricingEngine.calculateProject(
      project: state.project,
      backend: backend,
      config: state.quoteConfig,
    );
    state = state.copyWith(projectResult: projectResult);
  }

  void _mapSection(
    String sectionId,
    LabourRoofSection Function(LabourRoofSection section) transform, {
    bool recalculate = false,
  }) {
    final next = state.project.sections
        .map((section) =>
            section.id == sectionId ? transform(section) : section)
        .toList();
    state = state.copyWith(
      project: state.project.copyWith(sections: next),
      clearResult: !recalculate,
    );
    if (recalculate) _recalculateSilent();
  }
}

final labourPricingProvider =
    NotifierProvider<LabourPricingNotifier, LabourPricingState>(
  LabourPricingNotifier.new,
);