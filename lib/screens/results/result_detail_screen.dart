import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/visulization_toggle.dart';
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

  @override
  Widget build(BuildContext context) {
    final result = widget.result; // Use result from constructor
    final isVertical = result.type == CalculationType.vertical;
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(result.timestamp);
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
          IconButton(
            icon: const Icon(Icons.share),
            onPressed:
                _isExporting ? null : () => _showExportOptions(context, result),
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isExporting
                ? null
                : () => _navigateToEditScreen(context, result),
            tooltip: 'Edit',
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
                      isVertical
                          ? 'Vertical Calculation'
                          : result.type == CalculationType.combined
                              ? 'Combined Calculation'
                              : 'Horizontal Calculation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created on $formattedDate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
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
                    // Calculation Context Section
                    _buildCalculationContext(context, result, fontSize),
                    const SizedBox(height: 16),
                    // Single Visualization with Toggle Buttons
                    _buildVisualizationSection(context, verticalResult,
                        horizontalResult, gutterOverhang, fontSize),
                    const SizedBox(height: 16),
                    // Results Summary and Details
                    if (verticalResult != null)
                      _buildVerticalResultsSection(
                          context, verticalResult, result, fontSize),
                    if (horizontalResult != null)
                      _buildHorizontalResultsSection(
                          context, horizontalResult, result, fontSize),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationContext(
      BuildContext context, SavedResult result, double fontSize) {
    List<Widget> contextRows = [];

    // Tile Information
    contextRows
        .add(_infoRow('Tile Name', result.tile['name']?.toString() ?? 'N/A'));
    contextRows.add(_infoRow(
        'Material Type', result.tile['materialType']?.toString() ?? 'N/A'));
    if (result.tile['tileCoverWidth'] != null) {
      contextRows
          .add(_infoRow('Cover Width', '${result.tile['tileCoverWidth']} mm'));
    }
    if (result.tile['slateTileHeight'] != null) {
      contextRows
          .add(_infoRow('Height', '${result.tile['slateTileHeight']} mm'));
    }

    // Vertical Inputs
    if (result.inputs['vertical_inputs'] != null) {
      final verticalInputs =
          result.inputs['vertical_inputs'] as Map<String, dynamic>;
      contextRows.add(const Divider());
      if (verticalInputs['gutterOverhang'] != null) {
        contextRows.add(_infoRow(
            'Gutter Overhang', '${verticalInputs['gutterOverhang']} mm'));
      }
      if (verticalInputs['useDryRidge'] != null) {
        contextRows.add(_infoRow('Dry Ridge',
            verticalInputs['useDryRidge'] == 'YES' ? 'Yes' : 'No'));
      }
      if (verticalInputs['rafterHeights'] != null) {
        final rafters = verticalInputs['rafterHeights'] as List<dynamic>;
        for (int i = 0; i < rafters.length; i++) {
          final rafter = rafters[i];
          contextRows.add(_infoRow(
              rafter['label'] ?? 'Rafter ${i + 1}', '${rafter['value']} mm'));
        }
      }
    }

    // Horizontal Inputs
    if (result.inputs['horizontal_inputs'] != null) {
      final horizontalInputs =
          result.inputs['horizontal_inputs'] as Map<String, dynamic>;
      contextRows.add(const Divider());
      if (horizontalInputs['widths'] != null) {
        final widths = horizontalInputs['widths'] as List<dynamic>;
        for (int i = 0; i < widths.length; i++) {
          final width = widths[i];
          contextRows.add(_infoRow(
              width['label'] ?? 'Width ${i + 1}', '${width['value']} mm'));
        }
      }
      if (horizontalInputs['useDryVerge'] != null) {
        contextRows.add(_infoRow('Dry Verge',
            horizontalInputs['useDryVerge'] == 'YES' ? 'Yes' : 'No'));
      }
      if (horizontalInputs['abutmentSide'] != null) {
        contextRows
            .add(_infoRow('Abutment Side', horizontalInputs['abutmentSide']));
      }
      if (horizontalInputs['useLHTile'] != null) {
        contextRows.add(_infoRow('Left Hand Tile',
            horizontalInputs['useLHTile'] == 'YES' ? 'Yes' : 'No'));
      }
      if (horizontalInputs['crossBonded'] != null) {
        contextRows.add(_infoRow('Cross Bonded',
            horizontalInputs['crossBonded'] == 'YES' ? 'Yes' : 'No'));
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
      BuildContext context,
      VerticalCalculationResult? verticalResult,
      HorizontalCalculationResult? horizontalResult,
      double? gutterOverhang,
      double fontSize) {
    final hasVertical = verticalResult != null;
    final hasHorizontal = horizontalResult != null;

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
        padding: const EdgeInsets.all(16.0),
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
                verticalResult: verticalResult,
                horizontalResult: horizontalResult,
                gutterOverhang: gutterOverhang ?? 0,
                defaultMode: defaultMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalResultsSection(
      BuildContext context,
      VerticalCalculationResult result,
      SavedResult savedResult,
      double fontSize) {
    // Summary Metrics
    List<Widget> summaryRows = [
      _infoRow('Total Courses', result.totalCourses.toString()),
      _infoRow('Gauge', '${result.gauge} mm'),
      if (result.splitGauge != null)
        _infoRow('Split Gauge', '${result.splitGauge} mm'),
    ];

    // Detailed Results for Each Rafter Height
    List<Widget> detailRows = [];
    if (savedResult.inputs['vertical_inputs'] != null) {
      final verticalInputs =
          savedResult.inputs['vertical_inputs'] as Map<String, dynamic>;
      if (verticalInputs['rafterHeights'] != null) {
        final rafters = verticalInputs['rafterHeights'] as List<dynamic>;
        for (int i = 0; i < rafters.length; i++) {
          final rafter = rafters[i];
          detailRows.add(_infoRow(
              rafter['label'] ?? 'Rafter ${i + 1}', '${rafter['value']} mm'));
          detailRows.add(_infoRow('Ridge Offset', '${result.ridgeOffset} mm'));
          if (result.eaveBatten != null) {
            detailRows.add(_infoRow('Eave Batten', '${result.eaveBatten} mm'));
          }
          detailRows.add(_infoRow('First Batten', '${result.firstBatten} mm'));
          if (result.cutCourse != null) {
            detailRows.add(_infoRow('Cut Course', '${result.cutCourse} mm'));
          }
          if (i < rafters.length - 1) {
            detailRows.add(const Divider());
          }
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            if (detailRows.isNotEmpty)
              ExpansionTile(
                title: Text(
                  'Detailed Results per Rafter',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(children: detailRows),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalResultsSection(
      BuildContext context,
      HorizontalCalculationResult result,
      SavedResult savedResult,
      double fontSize) {
    // Summary Metrics
    List<Widget> summaryRows = [
      _infoRow('New Width', '${result.newWidth} mm'),
      _infoRow('Marks', '${result.marks} mm'),
      if (result.splitMarks != null)
        _infoRow('Split Marks', '${result.splitMarks} mm'),
    ];

    // Detailed Results for Each Width
    List<Widget> detailRows = [];
    if (savedResult.inputs['horizontal_inputs'] != null) {
      final horizontalInputs =
          savedResult.inputs['horizontal_inputs'] as Map<String, dynamic>;
      if (horizontalInputs['widths'] != null) {
        final widths = horizontalInputs['widths'] as List<dynamic>;
        for (int i = 0; i < widths.length; i++) {
          final width = widths[i];
          detailRows.add(_infoRow(
              width['label'] ?? 'Width ${i + 1}', '${width['value']} mm'));
          if (result.lhOverhang != null) {
            detailRows.add(_infoRow('LH Overhang', '${result.lhOverhang} mm'));
          }
          if (result.rhOverhang != null) {
            detailRows.add(_infoRow('RH Overhang', '${result.rhOverhang} mm'));
          }
          if (result.cutTile != null) {
            detailRows.add(_infoRow('Cut Tile', '${result.cutTile} mm'));
          }
          detailRows.add(_infoRow('First Mark', '${result.firstMark} mm'));
          if (result.secondMark != null) {
            detailRows.add(_infoRow('Second Mark', '${result.secondMark} mm'));
          }
          if (i < widths.length - 1) {
            detailRows.add(const Divider());
          }
        }
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            if (detailRows.isNotEmpty)
              ExpansionTile(
                title: Text(
                  'Detailed Results per Width',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(children: detailRows),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context, SavedResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditResultSheet(result: result),
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

      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'RoofGrid UK Calculation Result',
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
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: 'RoofGrid UK Calculation Result',
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

      await Share.share(
        emailBody,
        subject: 'RoofGrid UK - ${result.projectName}',
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

  const EditResultSheet({super.key, required this.result});

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
      await resultsService.updateProjectName(
        widget.result,
        _projectNameController.text.trim(),
      );
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
            'Edit Result',
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
