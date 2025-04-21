// lib/app/results/result_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/screens/result_visualization.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:roofgrid_uk/app/results/services/results_service.dart';

class ResultDetailScreen extends ConsumerStatefulWidget {
  const ResultDetailScreen({super.key});

  @override
  ConsumerState<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends ConsumerState<ResultDetailScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(selectedResultProvider);

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result Details')),
        drawer: const MainDrawer(),
        body: const Center(child: Text('No result selected')),
      );
    }

    final isVertical = result.type == CalculationType.vertical;
    final dateFormat = DateFormat('dd MMMM yyyy, HH:mm');
    final formattedDate = dateFormat.format(result.timestamp);

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

              // Visualization
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 2,
                  child: ResultVisualization(result: result),
                ),
              ),

              // Details section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Tile Information'),
                    _buildInfoCard(
                      context,
                      title: 'Tile Details',
                      content: Column(
                        children: [
                          _infoRow(
                              'Name', result.tile['name']?.toString() ?? 'N/A'),
                          _infoRow('Type',
                              result.tile['materialType']?.toString() ?? 'N/A'),
                          if (result.tile['tileCoverWidth'] != null)
                            _infoRow('Cover Width',
                                '${result.tile['tileCoverWidth']} mm'),
                          if (result.tile['slateTileHeight'] != null)
                            _infoRow('Height',
                                '${result.tile['slateTileHeight']} mm'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Inputs'),

                    // Inputs card (dynamic based on calculation type)
                    _buildInputsCard(context, result),

                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Results'),

                    // Results card (dynamic based on calculation type)
                    _buildResultsCard(context, result),
                  ],
                ),
              ),
            ],
          ),
        ),
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
Type: ${isVertical ? 'Vertical' : 'Horizontal'} Calculation

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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required Widget content}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            content,
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

  Widget _buildInputsCard(BuildContext context, SavedResult result) {
    final isVertical = result.type == CalculationType.vertical;
    final inputs = result.inputs;

    List<Widget> inputRows = [];

    // Common settings
    if (inputs['gutterOverhang'] != null) {
      inputRows
          .add(_infoRow('Gutter Overhang', '${inputs['gutterOverhang']} mm'));
    }

    if (inputs['useDryRidge'] != null) {
      inputRows.add(
          _infoRow('Dry Ridge', inputs['useDryRidge'] == 'YES' ? 'Yes' : 'No'));
    }

    // Vertical specific
    if (isVertical && inputs['rafterHeights'] != null) {
      final rafters = inputs['rafterHeights'] as List<dynamic>;
      for (int i = 0; i < rafters.length; i++) {
        final rafter = rafters[i];
        inputRows.add(_buildEditableInfoRow(
          context,
          label: rafter['label'] ?? 'Rafter ${i + 1}',
          value: '${rafter['value']} mm',
          onEdit: () => _showEditLabelDialog(
            context,
            'Rename Rafter',
            rafter['label'] ?? 'Rafter ${i + 1}',
            (newLabel) =>
                _updateInputLabel(result, 'rafterHeights', i, newLabel),
          ),
        ));
      }
    }

    // Horizontal specific
    if (!isVertical) {
      if (inputs['widths'] != null) {
        final widths = inputs['widths'] as List<dynamic>;
        for (int i = 0; i < widths.length; i++) {
          final width = widths[i];
          inputRows.add(_buildEditableInfoRow(
            context,
            label: width['label'] ?? 'Width ${i + 1}',
            value: '${width['value']} mm',
            onEdit: () => _showEditLabelDialog(
              context,
              'Rename Width',
              width['label'] ?? 'Width ${i + 1}',
              (newLabel) => _updateInputLabel(result, 'widths', i, newLabel),
            ),
          ));
        }
      }

      if (inputs['useDryVerge'] != null) {
        inputRows.add(_infoRow(
            'Dry Verge', inputs['useDryVerge'] == 'YES' ? 'Yes' : 'No'));
      }

      if (inputs['abutmentSide'] != null) {
        inputRows.add(_infoRow('Abutment Side', inputs['abutmentSide']));
      }

      if (inputs['useLHTile'] != null) {
        inputRows.add(_infoRow(
            'Left Hand Tile', inputs['useLHTile'] == 'YES' ? 'Yes' : 'No'));
      }
    }

    return _buildInfoCard(
      context,
      title: 'Calculation Inputs',
      content: Column(children: inputRows),
    );
  }

  Widget _buildEditableInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$label:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Rename',
                ),
              ],
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

  Future<void> _showEditLabelDialog(
    BuildContext context,
    String title,
    String currentLabel,
    Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: currentLabel);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Label',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                context.pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateInputLabel(
      SavedResult result, String inputType, int index, String newLabel) async {
    try {
      final resultsService = ref.read(resultsServiceProvider);
      final success =
          await resultsService.renameInput(result, inputType, index, newLabel);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label updated')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update label')),
        );
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
    }
  }

  Widget _buildResultsCard(BuildContext context, SavedResult result) {
    final isVertical = result.type == CalculationType.vertical;
    final outputs = result.outputs;

    List<Widget> outputRows = [];

    // Common outputs
    if (outputs['solution'] != null) {
      outputRows.add(_infoRow('Solution Type', outputs['solution']));
    }

    // Vertical specific
    if (isVertical) {
      if (outputs['totalCourses'] != null) {
        outputRows.add(_infoRow('Total Courses', '${outputs['totalCourses']}'));
      }

      if (outputs['ridgeOffset'] != null) {
        outputRows
            .add(_infoRow('Ridge Offset', '${outputs['ridgeOffset']} mm'));
      }

      if (outputs['eaveBatten'] != null) {
        outputRows.add(_infoRow('Eave Batten', '${outputs['eaveBatten']} mm'));
      }

      if (outputs['firstBatten'] != null) {
        outputRows
            .add(_infoRow('First Batten', '${outputs['firstBatten']} mm'));
      }

      if (outputs['cutCourse'] != null) {
        outputRows.add(_infoRow('Cut Course', '${outputs['cutCourse']} mm'));
      }

      if (outputs['gauge'] != null) {
        outputRows.add(_infoRow('Gauge', outputs['gauge']));
      }

      if (outputs['splitGauge'] != null) {
        outputRows.add(_infoRow('Split Gauge', outputs['splitGauge']));
      }
    }

    // Horizontal specific
    else {
      if (outputs['newWidth'] != null) {
        outputRows.add(_infoRow('New Width', '${outputs['newWidth']} mm'));
      }

      if (outputs['lhOverhang'] != null) {
        outputRows.add(_infoRow('LH Overhang', '${outputs['lhOverhang']} mm'));
      }

      if (outputs['rhOverhang'] != null) {
        outputRows.add(_infoRow('RH Overhang', '${outputs['rhOverhang']} mm'));
      }

      if (outputs['cutTile'] != null) {
        outputRows.add(_infoRow('Cut Tile', '${outputs['cutTile']} mm'));
      }

      if (outputs['firstMark'] != null) {
        outputRows.add(_infoRow('First Mark', '${outputs['firstMark']} mm'));
      }

      if (outputs['secondMark'] != null) {
        outputRows.add(_infoRow('Second Mark', '${outputs['secondMark']} mm'));
      }

      if (outputs['marks'] != null) {
        outputRows.add(_infoRow('Marks', outputs['marks']));
      }

      if (outputs['splitMarks'] != null) {
        outputRows.add(_infoRow('Split Marks', outputs['splitMarks']));
      }
    }

    // Warning if any
    if (outputs['warning'] != null) {
      outputRows.add(const SizedBox(height: 8));
      outputRows.add(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                outputs['warning'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ));
    }

    return _buildInfoCard(
      context,
      title: 'Calculation Results',
      content: Column(children: outputRows),
    );
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
