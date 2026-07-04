import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/result_display_registry.dart';
import 'package:roofgrid_uk/utils/saved_result_dates.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';
import 'package:roofgrid_uk/utils/vertical_result_fields.dart';
import 'package:roofgrid_uk/widgets/calculation_results_panel.dart';
import 'package:roofgrid_uk/widgets/results/results_visualization_card.dart';
import 'package:roofgrid_uk/widgets/visualization_toggle.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';

class ResultDetailScreen extends ConsumerStatefulWidget {
  final SavedResult result; // Receive result via constructor

  const ResultDetailScreen({super.key, required this.result});

  @override
  ConsumerState<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends ConsumerState<ResultDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;
  late SavedResult _result;

  @override
  void initState() {
    super.initState();
    _result = normalizeSavedResult(widget.result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final typeLabel = savedCalculationTypeLabel(result.type);
    final formattedDate = formatSavedDateTime(result.createdAt);
    final updatedLine =
        formatSavedUpdatedLine(result.createdAt, result.updatedAt);
    final tileName = result.tile['name']?.toString();
    final fontSize = MediaQuery.of(context).size.width >= 600 ? 16.0 : 14.0;

    // Extract vertical and horizontal results from savedResult
    VerticalCalculationResult? verticalResult;
    HorizontalCalculationResult? horizontalResult;

    if (result.type == CalculationType.vertical) {
      verticalResult = VerticalCalculationResult.fromJson(result.outputs);
    } else if (result.type == CalculationType.horizontal) {
      horizontalResult = HorizontalCalculationResult.fromJson(result.outputs);
    } else if (result.type == CalculationType.combined) {
      verticalResult =
          VerticalCalculationResult.fromJson(result.outputs['vertical']);
      horizontalResult =
          HorizontalCalculationResult.fromJson(result.outputs['horizontal']);
    }

    // Extract gutterOverhang from inputs if available
    double? gutterOverhang;
    if (result.inputs['vertical_inputs'] != null) {
      gutterOverhang =
          result.inputs['vertical_inputs']['gutterOverhang'] as double?;
    } else if (result.inputs['inputs'] != null &&
        result.inputs['inputs']['vertical_inputs'] != null) {
      gutterOverhang = result.inputs['inputs']['vertical_inputs']
          ['gutterOverhang'] as double?;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(result.projectName),
        actions: [
          const HomeBackButton(),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed:
                _isExporting ? null : () => _showExportOptions(context, result),
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            onPressed: _isExporting
                ? null
                : () => context.push('/calculator', extra: _result),
            tooltip: 'Recalculate',
          ),
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed:
                _isExporting ? null : () => _navigateToEditScreen(context),
            tooltip: 'Rename project',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Screenshot(
        controller: _screenshotController,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary banner
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (tileName != null && tileName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tileName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Saved $formattedDate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    if (updatedLine != null)
                      Text(
                        updatedLine,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white60,
                            ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (verticalResult != null)
                      _buildVerticalResultsSection(
                          context, verticalResult, result, fontSize),
                    if (horizontalResult != null)
                      _buildHorizontalResultsSection(
                          context, horizontalResult, result, fontSize),
                    if (verticalResult != null || horizontalResult != null) ...[
                      const SizedBox(height: 16),
                      _buildVisualizationSection(
                        context,
                        verticalResult,
                        horizontalResult,
                        gutterOverhang,
                        result,
                        fontSize,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizationSection(
      BuildContext context,
      VerticalCalculationResult? verticalResult,
      HorizontalCalculationResult? horizontalResult,
      double? gutterOverhang,
      SavedResult savedResult,
      double fontSize) {
    final hasVertical = verticalResult != null;
    final hasHorizontal = horizontalResult != null;

    final defaultMode = hasVertical && hasHorizontal
        ? ViewMode.combined
        : hasVertical
            ? ViewMode.vertical
            : ViewMode.horizontal;

    return ResultsVisualizationCard(
      verticalResult: verticalResult,
      horizontalResult: horizontalResult,
      gutterOverhang: gutterOverhang ?? 0,
      defaultMode: defaultMode,
      savedResult: savedResult,
      tileMaterialType: materialTypeFromTileJson(savedResult.tile),
      showCombinedToggle: savedResult.type == CalculationType.combined,
      fontSize: fontSize,
    );
  }

  Widget _buildVerticalResultsSection(
      BuildContext context,
      VerticalCalculationResult result,
      SavedResult savedResult,
      double fontSize) {
    final tileMaterialType = materialTypeFromTileJson(savedResult.tile);
    final slopes = _savedSlopeEntries(savedResult);

    return VerticalResultsPanel(
      result: result,
      tileMaterialType: tileMaterialType,
      tileName: savedResult.tile['name']?.toString(),
      slopes: slopes,
      fontSize: fontSize,
      padding: const EdgeInsets.all(16.0),
      workingsData: buildJobWorkingsDataFromSavedResult(
        savedResult,
        scope: savedResult.type == CalculationType.combined
            ? CalculatorWorkingsScope.vertical
            : null,
      ),
    );
  }

  Widget _buildHorizontalResultsSection(
      BuildContext context,
      HorizontalCalculationResult result,
      SavedResult savedResult,
      double fontSize) {
    return HorizontalResultsPanel(
      result: result,
      widths: _savedWidthEntries(savedResult),
      tileName: savedResult.tile['name']?.toString(),
      fontSize: fontSize,
      padding: const EdgeInsets.all(16.0),
      workingsData: buildJobWorkingsDataFromSavedResult(
        savedResult,
        scope: savedResult.type == CalculationType.combined
            ? CalculatorWorkingsScope.horizontal
            : null,
      ),
    );
  }

  List<SlopeInputEntry> _savedSlopeEntries(SavedResult savedResult) {
    final verticalInputs =
        savedResult.inputs['vertical_inputs'] as Map<String, dynamic>?;
    final rafters = verticalInputs?['rafterHeights'] as List<dynamic>?;
    if (rafters == null) {
      return const [];
    }
    return slopeEntriesFromSavedInputs(rafters);
  }

  List<WidthInputEntry> _savedWidthEntries(SavedResult savedResult) {
    final horizontalInputs =
        savedResult.inputs['horizontal_inputs'] as Map<String, dynamic>?;
    final widths = horizontalInputs?['widths'] as List<dynamic>?;
    if (widths == null) {
      return const [];
    }
    return widthEntriesFromSavedInputs(widths);
  }



  void _navigateToEditScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditResultSheet(
        result: _result,
        onRenamed: (newName) {
          setState(() {
            _result = SavedResult(
              id: _result.id,
              userId: _result.userId,
              projectName: newName,
              type: _result.type,
              timestamp: _result.timestamp,
              inputs: _result.inputs,
              outputs: _result.outputs,
              tile: _result.tile,
              createdAt: _result.createdAt,
              updatedAt: DateTime.now(),
            );
          });
        },
      ),
    );
  }

  Future<void> _showExportOptions(
      BuildContext context, SavedResult result) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                context.pop();
                _exportAsPdf(result);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Export as Image'),
              onTap: () {
                context.pop();
                _exportAsImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send via Email'),
              onTap: () {
                context.pop();
                _shareViaEmail(result);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsImage() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final image = await _screenshotController.capture();
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture screenshot')),
          );
        }
        return;
      }

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/roofgrid_result_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(image);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath)],
          text: 'RoofGrid UK Calculation Result',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportAsPdf(SavedResult result) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final resultsService = ref.read(resultsServiceProvider);
      final pdfPath = await resultsService.exportResultAsPdf(result);

      if (pdfPath != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(pdfPath)],
            text: 'RoofGrid UK Calculation Result',
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF export feature coming soon!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _shareViaEmail(SavedResult result) async {
    setState(() {
      _isExporting = true;
    });

    try {
      final image = await _screenshotController.capture();
      if (image == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture screenshot')),
          );
        }
        return;
      }

      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/roofgrid_result_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(imagePath);
      await file.writeAsBytes(image);

      final isVertical = result.type == CalculationType.vertical;
      final dateFormat = DateFormat('dd MMMM yyyy');
      final formattedDate = dateFormat.format(result.timestamp);

      String emailBody = '''
RoofGrid UK Calculation Result

Project: ${result.projectName}
Date: $formattedDate
Type: ${isVertical ? 'Vertical' : result.type == CalculationType.combined ? 'Combined' : 'Horizontal'} Calculation

Tile: ${result.tile['name'] ?? 'N/A'}
''';

      await SharePlus.instance.share(
        ShareParams(
          text: emailBody,
          subject: 'RoofGrid UK - ${result.projectName}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

class EditResultSheet extends ConsumerStatefulWidget {
  final SavedResult result;
  final ValueChanged<String>? onRenamed;

  const EditResultSheet({
    super.key,
    required this.result,
    this.onRenamed,
  });

  @override
  ConsumerState<EditResultSheet> createState() => _EditResultSheetState();
}

class _EditResultSheetState extends ConsumerState<EditResultSheet> {
  final TextEditingController _projectNameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _projectNameController.text = widget.result.projectName;
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final resultsService = ref.read(resultsServiceProvider);
      final newName = _projectNameController.text.trim();
      await resultsService.updateProjectName(
        widget.result,
        newName,
      );
      ref.invalidate(savedResultsProvider(widget.result.userId));
      widget.onRenamed?.call(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project name updated')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rename Project',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _projectNameController,
            decoration: const InputDecoration(
              labelText: 'Project Name',
              border: OutlineInputBorder(),
            ),
            enabled: !_isSaving,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed:
                    _isSaving || _projectNameController.text.trim().isEmpty
                        ? null
                        : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
