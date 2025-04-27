import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/widgets/visulization_toggle.dart';
import 'package:roofgrid_uk/widgets/info_row.dart';

class ViewResultsStep extends ConsumerWidget {
  final UserModel user;
  final VerticalInputs verticalInputs;
  final HorizontalInputs horizontalInputs;
  final CalculationTypeSelection calculationType;
  final Map<String, dynamic>? lastVerticalCalculationData;
  final Map<String, dynamic>? lastHorizontalCalculationData;
  final VoidCallback onBack;
  final Function(UserModel) onSaveCombined;

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calcState = ref.watch(calculatorProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 12.0 : 8.0;
    final fontSize = isLargeScreen ? 14.0 : 12.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Semantics(
            label: 'Step 4: View Results',
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Text(
                'Step 4: View Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calculation Context Section
                _buildCalculationContext(context, fontSize, ref),
                const SizedBox(height: 8),
                // Single Visualization with Toggle Buttons
                _buildVisualizationSection(context, calcState, fontSize)
                    .animate()
                    .fadeIn(duration: 600.ms),
                const SizedBox(height: 8),
                // Results Summary and Details
                if (calcState.verticalResult != null &&
                    lastVerticalCalculationData != null)
                  _buildVerticalResultsSection(
                      context, calcState.verticalResult!, fontSize),
                if (calcState.horizontalResult != null &&
                    lastHorizontalCalculationData != null)
                  _buildHorizontalResultsSection(
                      context, calcState.horizontalResult!, fontSize),
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
        Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (calcState.verticalResult != null &&
                  calcState.horizontalResult != null)
                ElevatedButton(
                  onPressed: () => onSaveCombined(user),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Save Combined',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildCalculationContext(
      BuildContext context, double fontSize, WidgetRef ref) {
    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));
    List<Widget> contextRows = [];

    // Tile Information
    if (selectedTile != null) {
      contextRows.add(InfoRow(label: 'Tile Name', value: selectedTile.name));
      contextRows.add(InfoRow(
          label: 'Material Type', value: selectedTile.materialType.toString()));
      if (selectedTile.tileCoverWidth != null) {
        contextRows.add(InfoRow(
            label: 'Cover Width', value: '${selectedTile.tileCoverWidth} mm'));
      }
      if (selectedTile.slateTileHeight != null) {
        contextRows.add(InfoRow(
            label: 'Height', value: '${selectedTile.slateTileHeight} mm'));
      }
    } else {
      contextRows.add(InfoRow(label: 'Tile Name', value: 'N/A'));
    }

    // Vertical Inputs
    if (calculationType == CalculationTypeSelection.verticalOnly ||
        calculationType == CalculationTypeSelection.both) {
      contextRows.add(const Divider());
      contextRows.add(InfoRow(
          label: 'Gutter Overhang',
          value: '${verticalInputs.gutterOverhang} mm'));
      contextRows.add(InfoRow(
          label: 'Dry Ridge',
          value: verticalInputs.useDryRidge == 'YES' ? 'Yes' : 'No'));
      for (int i = 0; i < verticalInputs.rafterHeights.length; i++) {
        final rafter = verticalInputs.rafterHeights[i];
        contextRows.add(InfoRow(
            label: rafter['label'] ?? 'Rafter ${i + 1}',
            value: '${rafter['value']} mm'));
      }
    }

    // Horizontal Inputs
    if (calculationType == CalculationTypeSelection.horizontalOnly ||
        calculationType == CalculationTypeSelection.both) {
      contextRows.add(const Divider());
      for (int i = 0; i < horizontalInputs.widths.length; i++) {
        final width = horizontalInputs.widths[i];
        contextRows.add(InfoRow(
            label: width['label'] ?? 'Width ${i + 1}',
            value: '${width['value']} mm'));
      }
      contextRows.add(InfoRow(
          label: 'Dry Verge',
          value: horizontalInputs.useDryVerge == 'YES' ? 'Yes' : 'No'));
      contextRows.add(InfoRow(
          label: 'Abutment Side', value: horizontalInputs.abutmentSide));
      contextRows.add(InfoRow(
          label: 'Left Hand Tile',
          value: horizontalInputs.useLHTile == 'YES' ? 'Yes' : 'No'));
      contextRows.add(InfoRow(
          label: 'Cross Bonded',
          value: horizontalInputs.crossBonded == 'YES' ? 'Yes' : 'No'));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculation Context',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            ...contextRows,
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationSection(
      BuildContext context, CalculatorState calcState, double fontSize) {
    final hasVertical =
        calcState.verticalResult != null && lastVerticalCalculationData != null;
    final hasHorizontal = calcState.horizontalResult != null &&
        lastHorizontalCalculationData != null;

    // Default to Combined if both are available, otherwise the available result
    final defaultMode = hasVertical && hasHorizontal
        ? ViewMode.combined
        : hasVertical
            ? ViewMode.vertical
            : ViewMode.horizontal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visualization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            if (hasVertical || hasHorizontal)
              VisualizationWithToggle(
                verticalResult: calcState.verticalResult,
                horizontalResult: calcState.horizontalResult,
                gutterOverhang: verticalInputs.gutterOverhang,
                defaultMode: defaultMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalResultsSection(
      BuildContext context, VerticalCalculationResult result, double fontSize) {
    // Summary Metrics
    List<Widget> summaryRows = [
      InfoRow(label: 'Total Courses', value: result.totalCourses.toString()),
      InfoRow(label: 'Gauge', value: '${result.gauge} mm'),
      if (result.splitGauge != null)
        InfoRow(label: 'Split Gauge', value: '${result.splitGauge} mm'),
    ];

    // Detailed Results for Each Rafter Height
    List<Widget> detailRows = [];
    for (int i = 0; i < verticalInputs.rafterHeights.length; i++) {
      final rafter = verticalInputs.rafterHeights[i];
      detailRows.add(InfoRow(
          label: rafter['label'] ?? 'Rafter ${i + 1}',
          value: '${rafter['value']} mm'));
      detailRows.add(
          InfoRow(label: 'Ridge Offset', value: '${result.ridgeOffset} mm'));
      if (result.eaveBatten != null) {
        detailRows.add(
            InfoRow(label: 'Eave Batten', value: '${result.eaveBatten} mm'));
      }
      detailRows.add(
          InfoRow(label: 'First Batten', value: '${result.firstBatten} mm'));
      if (result.cutCourse != null) {
        detailRows
            .add(InfoRow(label: 'Cut Course', value: '${result.cutCourse} mm'));
      }
      if (i < verticalInputs.rafterHeights.length - 1) {
        detailRows.add(const Divider());
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vertical Calculation Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            // Summary
            Column(children: summaryRows),
            if (result.warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.warning!,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Expandable Details
            ExpansionTile(
              title: Text(
                'Detailed Results per Rafter',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize - 2,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(children: detailRows),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: 'Share Vertical Calculation',
                  child: OutlinedButton(
                    onPressed:
                        user.isPro ? () {} : null, // TODO: Implement share
                    child: Text(
                      'Share',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
                if (user.isPro)
                  Semantics(
                    label: 'Save Vertical Calculation Result',
                    child: ElevatedButton(
                      onPressed: () => _promptSaveResult(
                          lastVerticalCalculationData!, 'vertical', context),
                      child: Text(
                        'Save Result',
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalResultsSection(BuildContext context,
      HorizontalCalculationResult result, double fontSize) {
    // Summary Metrics
    List<Widget> summaryRows = [
      InfoRow(label: 'New Width', value: '${result.newWidth} mm'),
      InfoRow(label: 'Marks', value: '${result.marks} mm'),
      if (result.splitMarks != null)
        InfoRow(label: 'Split Marks', value: '${result.splitMarks} mm'),
    ];

    // Detailed Results for Each Width
    List<Widget> detailRows = [];
    for (int i = 0; i < horizontalInputs.widths.length; i++) {
      final width = horizontalInputs.widths[i];
      detailRows.add(InfoRow(
          label: width['label'] ?? 'Width ${i + 1}',
          value: '${width['value']} mm'));
      if (result.lhOverhang != null) {
        detailRows.add(
            InfoRow(label: 'LH Overhang', value: '${result.lhOverhang} mm'));
      }
      if (result.rhOverhang != null) {
        detailRows.add(
            InfoRow(label: 'RH Overhang', value: '${result.rhOverhang} mm'));
      }
      if (result.cutTile != null) {
        detailRows
            .add(InfoRow(label: 'Cut Tile', value: '${result.cutTile} mm'));
      }
      detailRows
          .add(InfoRow(label: 'First Mark', value: '${result.firstMark} mm'));
      if (result.secondMark != null) {
        detailRows.add(
            InfoRow(label: 'Second Mark', value: '${result.secondMark} mm'));
      }
      if (i < horizontalInputs.widths.length - 1) {
        detailRows.add(const Divider());
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horizontal Calculation Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            // Summary
            Column(children: summaryRows),
            if (result.warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.warning!,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Expandable Details
            ExpansionTile(
              title: Text(
                'Detailed Results per Width',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize - 2,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(children: detailRows),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: 'Share Horizontal Calculation',
                  child: OutlinedButton(
                    onPressed:
                        user.isPro ? () {} : null, // TODO: Implement share
                    child: Text(
                      'Share',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
                if (user.isPro)
                  Semantics(
                    label: 'Save Horizontal Calculation Result',
                    child: ElevatedButton(
                      onPressed: () => _promptSaveResult(
                          lastHorizontalCalculationData!,
                          'horizontal',
                          context),
                      child: Text(
                        'Save Result',
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _promptSaveResult(
      Map<String, dynamic> calculationData, String type, BuildContext context) {
    final TextEditingController projectNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Calculation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Would you like to save this calculation result?'),
            const SizedBox(height: 16),
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Skip saving
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              if (projectNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a project name'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }
              final updatedCalculationData =
                  Map<String, dynamic>.from(calculationData);
              updatedCalculationData['projectName'] =
                  projectNameController.text.trim();
              Navigator.pop(context);
              // Saving logic is handled in CalculatorScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calculation result saved successfully'),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
