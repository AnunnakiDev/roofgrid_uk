import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/screens/result_visualization.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VerticalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleRafters;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;
  final VerticalInputs initialInputs;
  final void Function(VerticalInputs) onInputsChanged;
  final Future<void> Function(Map<String, dynamic>, String) saveResultCallback;

  const VerticalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleRafters,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
    required this.initialInputs,
    required this.onInputsChanged,
    required this.saveResultCallback,
  });

  @override
  VerticalCalculatorTabState createState() => VerticalCalculatorTabState();
}

class VerticalCalculatorTabState extends ConsumerState<VerticalCalculatorTab>
    with SingleTickerProviderStateMixin {
  late List<TextEditingController> _rafterControllers;
  late List<String> _rafterNames;
  late double _gutterOverhang;
  late String _useDryRidge;
  final GlobalKey _resultsKey = GlobalKey(); // For auto-scrolling
  List<Map<String, dynamic>> _inputs = []; // Store inputs after calculation
  Map<String, dynamic>?
      _lastCalculationData; // Store last calculation for saving
  List<Color> _rafterColors = []; // Colors for each rafter

  @override
  void initState() {
    super.initState();
    // Initialize inputs from widget.initialInputs
    _rafterControllers = widget.initialInputs.rafterHeights.isNotEmpty
        ? widget.initialInputs.rafterHeights
            .map((entry) =>
                TextEditingController(text: entry['value'].toString()))
            .toList()
        : [TextEditingController()];
    _rafterNames = widget.initialInputs.rafterHeights.isNotEmpty
        ? widget.initialInputs.rafterHeights
            .map((entry) => entry['label'] as String)
            .toList()
        : ['Rafter 1'];
    _gutterOverhang = widget.initialInputs.gutterOverhang;
    _useDryRidge = widget.initialInputs.useDryRidge;

    // Assign colors to each rafter
    _rafterColors = _rafterNames
        .asMap()
        .entries
        .map((entry) => _getColorForIndex(entry.key))
        .toList();

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

  @override
  void dispose() {
    for (final controller in _rafterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateParentInputs() {
    final inputs = VerticalInputs(
      rafterHeights: _rafterControllers.asMap().entries.map((entry) {
        final index = entry.key;
        final controller = entry.value;
        return {
          'label': _rafterNames[index],
          'value': double.tryParse(controller.text) ?? 0.0,
        };
      }).toList(),
      gutterOverhang: _gutterOverhang,
      useDryRidge: _useDryRidge,
    );
    widget.onInputsChanged(inputs);
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
          _buildGutterOverhangSlider(fontSize),
          _buildDryRidgeToggle(fontSize),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rafter Height',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
              ),
              if (widget.canUseMultipleRafters)
                Semantics(
                  label: 'Add new rafter input',
                  child: TextButton(
                    onPressed: _addRafter,
                    child: Text(
                      'Add Rafter',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildRafterInputs(fontSize),
          if (!widget.canUseMultipleRafters) _buildProFeaturePrompt(fontSize),
          if (calcState.verticalResult != null)
            _buildResultsCard(calcState, fontSize),
          if (calcState.errorMessage != null)
            _buildErrorMessage(calcState.errorMessage!, fontSize),
        ],
      ),
    );
  }

  Widget _buildGutterOverhangSlider(double fontSize) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Gutter Overhang:',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
        Expanded(
          flex: 5,
          child: Semantics(
            label: 'Gutter Overhang Slider',
            child: Slider(
              value: _gutterOverhang,
              min: 25.0,
              max: 75.0,
              divisions: 10,
              label: '${_gutterOverhang.round()} mm',
              onChanged: (value) {
                setState(() {
                  _gutterOverhang = value;
                });
                ref.read(calculatorProvider.notifier).setGutterOverhang(value);
                _updateParentInputs();
              },
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${_gutterOverhang.round()} mm',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
      ],
    );
  }

  Widget _buildDryRidgeToggle(double fontSize) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Use Dry Ridge:',
            style: TextStyle(fontSize: fontSize - 2),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Semantics(
                label: 'Use Dry Ridge Yes',
                child: Radio<String>(
                  value: 'YES',
                  groupValue: _useDryRidge,
                  onChanged: (value) {
                    setState(() {
                      _useDryRidge = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setUseDryRidge(value!);
                    _updateParentInputs();
                  },
                ),
              ),
              Text('Yes', style: TextStyle(fontSize: fontSize - 2)),
              const SizedBox(width: 16),
              Semantics(
                label: 'Use Dry Ridge No',
                child: Radio<String>(
                  value: 'NO',
                  groupValue: _useDryRidge,
                  onChanged: (value) {
                    setState(() {
                      _useDryRidge = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setUseDryRidge(value!);
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

  List<Widget> _buildRafterInputs(double fontSize) {
    final List<Widget> rafterInputs = [];
    final int displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      rafterInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (widget.canUseMultipleRafters) ...[
                Expanded(
                  flex: 3,
                  child: Semantics(
                    label: 'Rafter Name ${i + 1}',
                    child: TextField(
                      controller: TextEditingController(text: _rafterNames[i]),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      style: TextStyle(fontSize: fontSize - 2),
                      onChanged: (value) {
                        setState(() {
                          _rafterNames[i] = value.isNotEmpty
                              ? value
                              : 'Rafter ${i + 1}'; // Default name if empty
                        });
                        _updateParentInputs();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.canUseMultipleRafters ? 5 : 8,
                child: Semantics(
                  label: 'Rafter Height ${i + 1}',
                  child: TextField(
                    controller: _rafterControllers[i],
                    decoration: InputDecoration(
                      labelText: widget.canUseMultipleRafters
                          ? null
                          : 'Rafter height in mm',
                      hintText: 'e.g., 6000',
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
              if (widget.canUseMultipleRafters &&
                  _rafterControllers.length > 1) ...[
                const SizedBox(width: 8),
                Semantics(
                  label: 'Remove Rafter ${i + 1}',
                  child: IconButton(
                    onPressed: () => _removeRafter(i),
                    icon: const Icon(Icons.delete_outline),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: 'Remove rafter',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return rafterInputs;
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
                  'Upgrade to Pro to calculate multiple rafters at once',
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
    final result = calcState.verticalResult!;
    final rafterHeights = _inputs; // Use stored inputs

    // Create a temporary SavedResult for visualization with color mapping
    final tempSavedResult = SavedResult(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      projectName: 'Temporary Result',
      type: CalculationType.vertical,
      timestamp: DateTime.now(),
      inputs: {
        'rafterHeights': _inputs,
        'gutterOverhang': _gutterOverhang,
        'useDryRidge': _useDryRidge,
        'rafterColors':
            _rafterColors.map((color) => color.value.toString()).toList(),
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
                  'Vertical Calculation Results',
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
            if (rafterHeights.length <= 1) ...[
              // Single rafter, display directly
              _buildSingleResult(result, fontSize),
            ] else ...[
              // Multiple rafters, use PageView for swipeable results
              SizedBox(
                height: 300, // Adjust based on content
                child: PageView.builder(
                  itemCount: rafterHeights.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _rafterColors[index].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _rafterColors[index]),
                          ),
                          child: Text(
                            _rafterNames[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: _rafterColors[index],
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
                              _lastCalculationData!, 'vertical')
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

  Widget _buildSingleResult(VerticalCalculationResult result, double fontSize) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      children: [
        _resultItem('Input Rafter', '${result.inputRafter} mm', fontSize),
        _resultItem('Total Courses', result.totalCourses.toString(), fontSize),
        _resultItem('Ridge Offset', '${result.ridgeOffset} mm', fontSize),
        if (result.underEaveBatten != null)
          _resultItem(
              'Under Eave Batten', '${result.underEaveBatten} mm', fontSize),
        if (result.eaveBatten != null)
          _resultItem('Eave Batten', '${result.eaveBatten} mm', fontSize),
        _resultItem('1st Batten', '${result.firstBatten} mm', fontSize),
        if (result.cutCourse != null)
          _resultItem('Cut Course', '${result.cutCourse} mm', fontSize),
        _resultItem('Gauge', result.gauge, fontSize),
        if (result.splitGauge != null)
          _resultItem('Split Gauge', result.splitGauge!, fontSize),
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

  void _addRafter() {
    if (!widget.canUseMultipleRafters) return;
    setState(() {
      _rafterControllers.add(TextEditingController());
      _rafterNames.add('Rafter ${_rafterControllers.length}');
      _rafterColors.add(_getColorForIndex(_rafterControllers.length - 1));
    });
    _updateParentInputs();
  }

  void _removeRafter(int index) {
    if (!widget.canUseMultipleRafters || _rafterControllers.length <= 1) return;
    setState(() {
      _rafterControllers[index].dispose();
      _rafterControllers.removeAt(index);
      _rafterNames.removeAt(index);
      _rafterColors.removeAt(index);
    });
    _updateParentInputs();
  }

  Future<Map<String, dynamic>?> calculate() async {
    debugPrint('Starting calculate in VerticalCalculatorTab');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return null;
    }

    final List<double> rafterHeights = [];
    final displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final heightText = _rafterControllers[i].text.trim();
      debugPrint('Rafter $i height text: $heightText');
      if (heightText.isEmpty) {
        debugPrint('Empty height for rafter $i');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a height for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}',
            ),
          ),
        );
        return null;
      }
      final double? height = double.tryParse(heightText);
      if (height == null) {
        debugPrint('Invalid height value for rafter $i: $heightText');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid height value for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}',
            ),
          ),
        );
        return null;
      }
      rafterHeights.add(height);
    }

    debugPrint('Rafter heights: $rafterHeights');
    final result = await ref
        .read(calculatorProvider.notifier)
        .calculateVertical(rafterHeights);
    debugPrint('Result from calculateVertical in tab: $result');

    // Prepare inputs to include in the saved result
    final inputs = rafterHeights
        .asMap()
        .entries
        .map((entry) => {
              'label': _rafterNames[entry.key],
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

  // Getter for rafter names to pass to CalculatorScreen
  List<String> get rafterNames => _rafterNames;

  // Getter for inputs to pass to CalculatorScreen for saving
  Map<String, dynamic> get inputs => {
        'rafterHeights': _inputs,
        'gutterOverhang': _gutterOverhang,
        'useDryRidge': _useDryRidge,
      };

  // Getter for results key for auto-scrolling
  GlobalKey get resultsKey => _resultsKey;
}
