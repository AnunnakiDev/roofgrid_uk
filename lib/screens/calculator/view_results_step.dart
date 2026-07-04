import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/calculation_results_panel.dart';
import 'package:roofgrid_uk/widgets/save_result_dialog.dart';


class ViewResultsStep extends ConsumerWidget {
  final UserModel user;
  final VerticalInputs verticalInputs;
  final HorizontalInputs horizontalInputs;
  final CalculationTypeSelection calculationType;
  final Map<String, dynamic>? lastVerticalCalculationData;
  final Map<String, dynamic>? lastHorizontalCalculationData;
  final VoidCallback onBack;
  final Function(UserModel) onSaveCombined;
  final Future<SavedResult?> Function(
    UserModel user,
    Map<String, dynamic> calculationData,
    String type, {
    SaveResultAction saveAction,
  }) onSaveResult;
  final String? existingSavedResultId;
  final String? existingProjectName;

  const ViewResultsStep({
    super.key,
    required this.user,
    required this.verticalInputs,
    required this.horizontalInputs,
    required this.calculationType,
    required this.lastVerticalCalculationData,
    required this.lastHorizontalCalculationData,
    required this.onBack,
    required this.onSaveCombined,
    required this.onSaveResult,
    this.existingSavedResultId,
    this.existingProjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calcState = ref.watch(calculatorProvider);
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
    final tileMaterialType = ref.watch(calculatorProvider.select(
      (state) => state.selectedTile?.materialTypeString,
    ));
    final isNarrow = isNarrowLayout(context);
    final padding = isNarrow ? 8.0 : 12.0;
    final fontSize = isNarrow ? 14.0 : 15.0;
    final colorScheme = Theme.of(context).colorScheme;
    final useStickySave = isNarrow;

    return Column(
      children: [
        if (existingSavedResultId != null) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Material(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        existingProjectName != null
                            ? 'Recalculating "$existingProjectName" — save to apply changes'
                            : 'Recalculating saved result — save to apply changes',
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: padding),
        ],
        Padding(
          padding: EdgeInsets.all(padding),
          child: Semantics(
            label: 'Step 3: View Results',
            child: CalculatorStepProgress(
              currentStep: CalculatorFlowStep.viewResults,
              compact: isNarrow,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showVerticalResults(calcState))
                  _buildVerticalResultsSection(
                    context,
                    calcState,
                    fontSize,
                    effectiveIsPro,
                    tileMaterialType,
                    ref,
                    includePanelSave: !useStickySave,
                  ),
                if (_showVerticalResults(calcState) &&
                    _showHorizontalResults(calcState))
                  const SizedBox(height: 16),
                if (_showHorizontalResults(calcState))
                  _buildHorizontalResultsSection(
                    context,
                    calcState,
                    fontSize,
                    effectiveIsPro,
                    ref,
                    includePanelSave: !useStickySave,
                  ),
                if (calcState.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            calcState.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontSize: fontSize - 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            color: colorScheme.surface,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text('Back'),
                  ),
                  const Spacer(),
                  ..._buildFooterSaveActions(
                    context,
                    calcState,
                    effectiveIsPro,
                    fontSize,
                    includeSingleModeSave: useStickySave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  List<Widget> _buildFooterSaveActions(
    BuildContext context,
    CalculatorState calcState,
    bool effectiveIsPro,
    double fontSize, {
    required bool includeSingleModeSave,
  }) {
    if (!effectiveIsPro) return const [];

    if (calculationType == CalculationTypeSelection.both &&
        _canSaveCombined(calcState)) {
      return [
        ElevatedButton.icon(
          onPressed: () => onSaveCombined(user),
          icon: const Icon(Icons.save_outlined, size: 20),
          label: const Text('Save Combined'),
        ),
      ];
    }

    if (!includeSingleModeSave) return const [];

    if (calculationType == CalculationTypeSelection.verticalOnly &&
        _showVerticalResults(calcState)) {
      return [
        ElevatedButton.icon(
          onPressed: () => _promptSaveResult(
            lastVerticalCalculationData!,
            'vertical',
            context,
          ),
          icon: const Icon(Icons.save_outlined, size: 20),
          label: Text(
            'Save Result',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
      ];
    }

    if (calculationType == CalculationTypeSelection.horizontalOnly &&
        _showHorizontalResults(calcState)) {
      return [
        ElevatedButton.icon(
          onPressed: () => _promptSaveResult(
            lastHorizontalCalculationData!,
            'horizontal',
            context,
          ),
          icon: const Icon(Icons.save_outlined, size: 20),
          label: Text(
            'Save Result',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
      ];
    }

    return const [];
  }

  JobWorkingsData _buildJobWorkingsData(
    WidgetRef ref,
    CalculatorState calcState,
    CalculatorWorkingsScope scope,
  ) {
    final selectedTile =
        ref.read(calculatorProvider.select((state) => state.selectedTile));
    final includeVertical = scope == CalculatorWorkingsScope.vertical ||
        scope == CalculatorWorkingsScope.combined;
    final includeHorizontal = scope == CalculatorWorkingsScope.horizontal ||
        scope == CalculatorWorkingsScope.combined;

    return buildJobWorkingsData(
      tileName: selectedTile?.name,
      materialType: selectedTile?.materialTypeString,
      coverWidth: selectedTile?.tileCoverWidth,
      tileHeight: selectedTile?.slateTileHeight,
      gutterOverhang:
          includeVertical ? verticalInputs.gutterOverhang : null,
      useDryRidge: includeVertical ? verticalInputs.useDryRidge : null,
      rafterHeights:
          includeVertical ? verticalInputs.rafterHeights : null,
      widths: includeHorizontal ? horizontalInputs.widths : null,
      useDryVerge: includeHorizontal ? horizontalInputs.useDryVerge : null,
      abutmentSide: includeHorizontal ? horizontalInputs.abutmentSide : null,
      useLHTile: includeHorizontal ? horizontalInputs.useLHTile : null,
      verticalResult: includeVertical ? calcState.verticalResult : null,
      horizontalResult: includeHorizontal ? calcState.horizontalResult : null,
      scope: scope,
    );
  }

  bool _canSaveCombined(CalculatorState calcState) {
    final vertical = calcState.verticalResult;
    final horizontal = calcState.horizontalResult;
    if (vertical == null ||
        horizontal == null ||
        lastVerticalCalculationData == null ||
        lastHorizontalCalculationData == null) {
      return false;
    }
    return vertical.solution != 'Invalid' && horizontal.solution != 'Invalid';
  }

  bool _showVerticalResults(CalculatorState calcState) {
    return (calculationType == CalculationTypeSelection.verticalOnly ||
            calculationType == CalculationTypeSelection.both) &&
        calcState.verticalResult != null &&
        lastVerticalCalculationData != null;
  }

  bool _showHorizontalResults(CalculatorState calcState) {
    return (calculationType == CalculationTypeSelection.horizontalOnly ||
            calculationType == CalculationTypeSelection.both) &&
        calcState.horizontalResult != null &&
        lastHorizontalCalculationData != null;
  }

  Widget _buildVerticalResultsSection(
    BuildContext context,
    CalculatorState calcState,
    double fontSize,
    bool effectiveIsPro,
    String? tileMaterialType,
    WidgetRef ref, {
    required bool includePanelSave,
  }) {
    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));

    return VerticalResultsPanel(
      result: calcState.verticalResult!,
      tileMaterialType: tileMaterialType,
      tileName: selectedTile?.name,
      slopes: slopeEntriesFromMaps(verticalInputs.rafterHeights),
      fontSize: fontSize,
      workingsData: _buildJobWorkingsData(
        ref,
        calcState,
        CalculatorWorkingsScope.vertical,
      ),
      footer: includePanelSave &&
              calculationType != CalculationTypeSelection.both
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (effectiveIsPro)
                  Semantics(
                    label: 'Save calculation result',
                    child: ElevatedButton.icon(
                      onPressed: () => _promptSaveResult(
                        lastVerticalCalculationData!,
                        'vertical',
                        context,
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        'Save Result',
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildHorizontalResultsSection(
    BuildContext context,
    CalculatorState calcState,
    double fontSize,
    bool effectiveIsPro,
    WidgetRef ref, {
    required bool includePanelSave,
  }) {
    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));

    return HorizontalResultsPanel(
      result: calcState.horizontalResult!,
      widths: widthEntriesFromMaps(horizontalInputs.widths),
      tileName: selectedTile?.name,
      fontSize: fontSize,
      workingsData: _buildJobWorkingsData(
        ref,
        calcState,
        CalculatorWorkingsScope.horizontal,
      ),
      footer: includePanelSave &&
              calculationType != CalculationTypeSelection.both
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (effectiveIsPro)
                  Semantics(
                    label: 'Save calculation result',
                    child: ElevatedButton.icon(
                      onPressed: () => _promptSaveResult(
                        lastHorizontalCalculationData!,
                        'horizontal',
                        context,
                      ),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        'Save Result',
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }

  Future<void> _promptSaveResult(
    Map<String, dynamic> calculationData,
    String type,
    BuildContext context,
  ) async {
    final dialogResult = await showSaveResultDialog(
      context: context,
      initialProjectName: existingProjectName,
      allowUpdateExisting: existingSavedResultId != null,
    );
    if (dialogResult == null) return;

    final updatedCalculationData = Map<String, dynamic>.from(calculationData);
    updatedCalculationData['projectName'] = dialogResult.projectName;
    if (dialogResult.action == SaveResultAction.updateExisting &&
        existingSavedResultId != null) {
      updatedCalculationData['id'] = existingSavedResultId;
    }

    await onSaveResult(
      user,
      updatedCalculationData,
      type,
      saveAction: dialogResult.action,
    );
  }
}
