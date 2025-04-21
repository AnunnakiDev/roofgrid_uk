import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/screens/result_visualization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HorizontalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleWidths;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;
  final HorizontalInputs initialInputs;
  final void Function(HorizontalInputs) onInputsChanged;
  final Future<void> Function(Map<String, dynamic>, String) saveResultCallback;

  const HorizontalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleWidths,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
    required this.initialInputs,
    required this.onInputsChanged,
    required this.saveResultCallback,
  });

  @override
  HorizontalCalculatorTabState createState() => HorizontalCalculatorTabState();
}

class HorizontalCalculatorTabState
    extends ConsumerState<HorizontalCalculatorTab> {
  late List<TextEditingController> _widthControllers;
  late List<String> _widthNames;
  late String _useDryVerge;
  late String _abutmentSide;
  late String _useLHTile;
  late String _crossBonded;
  bool _isOnline = true;
  final GlobalKey _resultsKey = GlobalKey(); // For auto-scrolling
  List<Map<String, dynamic>> _inputs = []; // Store inputs after calculation
  Map<String, dynamic>?
      _lastCalculationData; // Store last calculation for saving
  List<Color> _widthColors = []; // Colors for each width

  @override
  void initState() {
    super.initState();
    // Initialize inputs from widget.initialInputs
    _widthControllers = widget.initialInputs.widths.isNotEmpty
        ? widget.initialInputs.widths
            .map((entry) =>
                TextEditingController(text: entry['value'].toString()))
            .toList()
        : [TextEditingController()];
    _widthNames = widget.initialInputs.widths.isNotEmpty
        ? widget.initialInputs.widths
            .map((entry) => entry['label'] as String)
            .toList()
        : ['Width 1'];
    _useDryVerge = widget.initialInputs.useDryVerge;
    _abutmentSide = widget.initialInputs.abutmentSide;
    _useLHTile = widget.initialInputs.useLHTile;
    _crossBonded = widget.initialInputs.crossBonded;

    // Assign colors to each width
    _widthColors = _widthNames
        .asMap()
        .entries
        .map((entry) => _getColorForIndex(entry.key))
        .toList();

    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
    });
    if (widget.user.isTrialAboutToExpire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpirationWarning(context);
      });
    }

    // Notify parent of initial inputs
    _updateParentInputs();
  }

  Color _getColorForIndex(int index) {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _updateParentInputs() {
    final inputs = HorizontalInputs(
      widths: _widthControllers.asMap().entries.map((entry) {
        final index = entry.key;
        final controller = entry.value;
        return {
          'label': _widthNames[index],
          'value': double.tryParse(controller.text) ?? 0.0,
        };
      }).toList(),
      useDryVerge: _useDryVerge,
      abutmentSide: _abutmentSide,
      useLHTile: _useLHTile,
      crossBonded: _crossBonded,
    );
    widget.onInputsChanged(inputs);
  }

  @override
  void dispose() {
    for (final controller in _widthControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final selectedTile = calcState.selectedTile;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 24.0 : 16.0;
    final fontSize = isLargeScreen ? 16.0 : 14.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Selected Tile: ${selectedTile?.name ?? "None"}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.canAccessDatabase)
                Semantics(
                  label: 'Edit selected tile',
                  child: TextButton(
                    onPressed: () => context.go('/calculator/tile-select'),
                    child: Text(
                      'Edit Tile',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
          ),
          const SizedBox(height: 8),
          _buildDryVergeToggle(fontSize),
          _buildAbutmentSideSelector(fontSize),
          _buildLHTileToggle(fontSize),
          _buildCrossBondedToggle(fontSize),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Width Measurements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
              ),
              if (widget.canUseMultipleWidths)
                Semantics(
                  label: 'Add new width input',
                  child: TextButton(
                    onPressed: _addWidth,
                    child: Text(
                      'Add Width',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildWidthInputs(fontSize),
          if (!widget.canUseMultipleWidths) _buildProFeaturePrompt(fontSize),
          if (calcState.horizontalResult != null)
            _buildResultsCard(calcState, fontSize),
          if (calcState.errorMessage != null)
            _buildErrorMessage(calcState.errorMessage!, fontSize),
        ],
      ),
    );
  }

  Widget _buildDryVergeToggle(double fontSize) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Use Dry Verge:',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Semantics(
                label: 'Use Dry Verge Yes',
                child: Radio<String>(
                  value: 'YES',
                  groupValue: _useDryVerge,
                  onChanged: (value) {
                    setState(() {
                      _useDryVerge = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setUseDryVerge(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('Yes', style: TextStyle(fontSize: fontSize - 2)),
              const SizedBox(width: 16),
              Semantics(
                label: 'Use Dry Verge No',
                child: Radio<String>(
                  value: 'NO',
                  groupValue: _useDryVerge,
                  onChanged: (value) {
                    setState(() {
                      _useDryVerge = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setUseDryVerge(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('No', style: TextStyle(fontSize: fontSize - 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbutmentSideSelector(double fontSize) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Abutment Side:',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
        Expanded(
          flex: 5,
          child: Semantics(
            label: 'Abutment Side Selector',
            child: DropdownButton<String>(
              value: _abutmentSide,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'NONE', child: Text('None')),
                DropdownMenuItem(value: 'LEFT', child: Text('Left')),
                DropdownMenuItem(value: 'RIGHT', child: Text('Right')),
                DropdownMenuItem(value: 'BOTH', child: Text('Both')),
              ],
              onChanged: (value) {
                setState(() {
                  _abutmentSide = value!;
                });
                ref.read(calculatorProvider.notifier).setAbutmentSide(value!);
                _updateParentInputs();
              },
              style: TextStyle(fontSize: fontSize - 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLHTileToggle(double fontSize) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Use Left Hand Tile:',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Semantics(
                label: 'Use Left Hand Tile Yes',
                child: Radio<String>(
                  value: 'YES',
                  groupValue: _useLHTile,
                  onChanged: (value) {
                    setState(() {
                      _useLHTile = value!;
                    });
                    ref.read(calculatorProvider.notifier).setUseLHTile(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('Yes', style: TextStyle(fontSize: fontSize - 2)),
              const SizedBox(width: 16),
              Semantics(
                label: 'Use Left Hand Tile No',
                child: Radio<String>(
                  value: 'NO',
                  groupValue: _useLHTile,
                  onChanged: (value) {
                    setState(() {
                      _useLHTile = value!;
                    });
                    ref.read(calculatorProvider.notifier).setUseLHTile(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('No', style: TextStyle(fontSize: fontSize - 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCrossBondedToggle(double fontSize) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Cross Bonded:',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Semantics(
                label: 'Cross Bonded Yes',
                child: Radio<String>(
                  value: 'YES',
                  groupValue: _crossBonded,
                  onChanged: (value) {
                    setState(() {
                      _crossBonded = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setCrossBonded(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('Yes', style: TextStyle(fontSize: fontSize - 2)),
              const SizedBox(width: 16),
              Semantics(
                label: 'Cross Bonded No',
                child: Radio<String>(
                  value: 'NO',
                  groupValue: _crossBonded,
                  onChanged: (value) {
                    setState(() {
                      _crossBonded = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setCrossBonded(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('No', style: TextStyle(fontSize: fontSize - 2)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWidthInputs(double fontSize) {
    final List<Widget> widthInputs = [];
    final int displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      widthInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (widget.canUseMultipleWidths) ...[
                Expanded(
                  flex: 3,
                  child: Semantics(
                    label: 'Width Name ${i + 1}',
                    child: TextField(
                      controller: TextEditingController(text: _widthNames[i]),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      style: TextStyle(fontSize: fontSize - 2),
                      onChanged: (value) {
                        setState(() {
                          _widthNames[i] = value.isNotEmpty
                              ? value
                              : 'Width ${i + 1}'; // Default name if empty
                        });
                        _updateParentInputs();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.canUseMultipleWidths ? 5 : 8,
                child: Semantics(
                  label: 'Width Measurement ${i + 1}',
                  child: TextField(
                    controller: _widthControllers[i],
                    decoration: InputDecoration(
                      labelText:
                          widget.canUseMultipleWidths ? null : 'Width in mm',
                      hintText: 'e.g., 4000',
                      suffixText: 'mm',
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: fontSize - 2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      _updateParentInputs();
                    },
                  ),
                ),
              ),
              if (widget.canUseMultipleWidths &&
                  _widthControllers.length > 1) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: 'Remove Width ${i + 1}',
                  child: IconButton(
                    onPressed: () => _removeWidth(i),
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: 'Remove width',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return widthInputs;
  }

  Widget _buildProFeaturePrompt(double fontSize) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).colorScheme.secondaryContainer),
      ),
      child: Row(
        children: [
          Icon(
            Icons.workspace_premium,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Feature',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: fontSize - 2,
                  ),
                ),
                Text(
                  'Upgrade to Pro to calculate multiple widths at once',
                  style: TextStyle(fontSize: fontSize - 4),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/subscription'),
            child: Text(
              'Upgrade',
              style: TextStyle(fontSize: fontSize - 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(CalculatorState calcState, double fontSize) {
    final result = calcState.horizontalResult!;
    final widths = _inputs; // Use stored inputs

    // Create a temporary SavedResult for visualization with color mapping
    final tempSavedResult = SavedResult(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      projectName: 'Temporary Result',
      type: CalculationType.horizontal,
      timestamp: DateTime.now(),
      inputs: {
        'widths': _inputs,
        'useDryVerge': _useDryVerge,
        'abutmentSide': _abutmentSide,
        'useLHTile': _useLHTile,
        'crossBonded': _crossBonded,
        'widthColors':
            _widthColors.map((color) => color.value.toString()).toList(),
      },
      outputs: result.toJson(),
      tile: calcState.selectedTile?.toJson() ?? {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return Card(
      key: _resultsKey, // For auto-scrolling
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Horizontal Calculation Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                ),
                Text(
                  result.solution,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
            const Divider(),
            // Text Results
            if (widths.length <= 1) ...[
              // Single width, display directly
              _buildSingleResult(result, fontSize),
            ] else ...[
              // Multiple widths, use PageView for swipeable results
              SizedBox(
                height: 300, // Adjust based on content
                child: PageView.builder(
                  itemCount: widths.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _widthColors[index].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _widthColors[index]),
                          ),
                          child: Text(
                            _widthNames[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _widthColors[index],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSingleResult(result, fontSize),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Visualization as Thumbnail
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 3.0,
                      child: ResultVisualization(result: tempSavedResult),
                    ),
                  ),
                );
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ResultVisualization(result: tempSavedResult),
              ),
            ),
            if (result.warning != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
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
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: 'Share Calculation',
                  child: OutlinedButton(
                    onPressed: widget.canExport
                        ? () {}
                        : null, // TODO: Implement share
                    child: Text(
                      'Share',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
                if (widget.user.isPro)
                  Semantics(
                    label: 'Save Calculation Result',
                    child: ElevatedButton(
                      onPressed: _lastCalculationData != null
                          ? () => _promptSaveResult(
                              _lastCalculationData!, 'horizontal')
                          : null,
                      child: const Text('Save Result'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  void _promptSaveResult(Map<String, dynamic> calculationData, String type) {
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
            onPressed: () async {
              if (projectNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a project name'),
                  ),
                );
                return;
              }
              final updatedCalculationData =
                  Map<String, dynamic>.from(calculationData);
              updatedCalculationData['projectName'] =
                  projectNameController.text.trim();
              await widget.saveResultCallback(updatedCalculationData, type);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleResult(
      HorizontalCalculationResult result, double fontSize) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      children: [
        _resultItem('Width', '${result.width} mm', fontSize),
        _resultItem('New Width', '${result.newWidth} mm', fontSize),
        if (result.lhOverhang != null)
          _resultItem('LH Overhang', '${result.lhOverhang} mm', fontSize),
        if (result.rhOverhang != null)
          _resultItem('RH Overhang', '${result.rhOverhang} mm', fontSize),
        if (result.cutTile != null)
          _resultItem('Cut Tile', '${result.cutTile} mm', fontSize),
        _resultItem('First Mark', '${result.firstMark} mm', fontSize),
        if (result.secondMark != null)
          _resultItem('Second Mark', '${result.secondMark} mm', fontSize),
        _resultItem('Marks', result.marks, fontSize),
        if (result.splitMarks != null)
          _resultItem('Split Marks', result.splitMarks!, fontSize),
      ],
    );
  }

  Widget _resultItem(String label, String value, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message, double fontSize) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
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
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontSize: fontSize - 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrialExpirationWarning(BuildContext context) {
    final remainingDays = widget.user.remainingTrialDays;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro Trial Expiring Soon'),
        content: Text(
          'Your Pro trial will expire in $remainingDays ${remainingDays == 1 ? 'day' : 'days'}. '
          'Upgrade now to keep access to all Pro features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/subscription');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _addWidth() {
    if (!widget.canUseMultipleWidths) return;
    setState(() {
      _widthControllers.add(TextEditingController());
      _widthNames.add('Width ${_widthControllers.length}');
      _widthColors.add(_getColorForIndex(_widthControllers.length - 1));
    });
    _updateParentInputs();
  }

  void _removeWidth(int index) {
    if (!widget.canUseMultipleWidths || _widthControllers.length <= 1) return;
    setState(() {
      _widthControllers[index].dispose();
      _widthControllers.removeAt(index);
      _widthNames.removeAt(index);
      _widthColors.removeAt(index);
    });
    _updateParentInputs();
  }

  Future<Map<String, dynamic>?> calculate() async {
    debugPrint('Starting calculate in HorizontalCalculatorTab');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return null;
    }

    final List<double> widths = [];
    final displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final widthText = _widthControllers[i].text.trim();
      debugPrint('Width $i text: $widthText');
      if (widthText.isEmpty) {
        debugPrint('Empty width for width $i');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a width for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}',
            ),
          ),
        );
        return null;
      }
      final double? width = double.tryParse(widthText);
      if (width == null) {
        debugPrint('Invalid width value for width $i: $widthText');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid width value for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}',
            ),
          ),
        );
        return null;
      }
      widths.add(width);
    }

    debugPrint('Widths: $widths');
    final result =
        await ref.read(calculatorProvider.notifier).calculateHorizontal(widths);
    debugPrint('Result from calculateHorizontal in tab: $result');

    // Prepare inputs to include in the saved result
    final inputs = widths
        .asMap()
        .entries
        .map((entry) => {
              'label': _widthNames[entry.key],
              'value': entry.value,
            })
        .toList();
    setState(() {
      _inputs = inputs; // Store inputs for display
      _lastCalculationData = result; // Store for saving
    });
    _updateParentInputs();

    return result;
  }

  // Getter for width names to pass to CalculatorScreen
  List<String> get widthNames => _widthNames;

  // Getter for inputs to pass to CalculatorScreen for saving
  Map<String, dynamic> get inputs => {
        'widths': _inputs,
        'useDryVerge': _useDryVerge,
        'abutmentSide': _abutmentSide,
        'useLHTile': _useLHTile,
        'crossBonded': _crossBonded,
      };

  // Getter for results key for auto-scrolling
  GlobalKey get resultsKey => _resultsKey;
}
