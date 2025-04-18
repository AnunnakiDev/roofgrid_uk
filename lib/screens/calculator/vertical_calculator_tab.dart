import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/services/results_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VerticalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleRafters;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;

  const VerticalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleRafters,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
  });

  @override
  VerticalCalculatorTabState createState() => VerticalCalculatorTabState();
}

class VerticalCalculatorTabState extends ConsumerState<VerticalCalculatorTab> {
  final List<TextEditingController> _rafterControllers = [
    TextEditingController()
  ];
  final List<String> _rafterNames = ['Rafter 1'];
  double _gutterOverhang = 50.0;
  String _useDryRidge = 'NO';

  @override
  void initState() {
    super.initState();
    if (widget.user.isTrialAboutToExpire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpirationWarning(context);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _rafterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final selectedTile = calcState.selectedTile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Tile: ${selectedTile?.name ?? "None"}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.canAccessDatabase)
                Semantics(
                  label: 'Edit selected tile',
                  child: TextButton(
                    onPressed: () => context.go('/calculator/tile-select'),
                    child: const Text('Edit Tile'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildGutterOverhangSlider(),
          _buildDryRidgeToggle(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rafter Height',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.canUseMultipleRafters)
                Semantics(
                  label: 'Add new rafter input',
                  child: TextButton(
                    onPressed: _addRafter,
                    child: const Text('Add Rafter'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildRafterInputs(),
          if (!widget.canUseMultipleRafters) _buildProFeaturePrompt(),
          if (calcState.verticalResult != null) _buildResultsCard(calcState),
          if (calcState.errorMessage != null)
            _buildErrorMessage(calcState.errorMessage!),
        ],
      ),
    );
  }

  Widget _buildGutterOverhangSlider() {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('Gutter Overhang:')),
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
              },
            ),
          ),
        ),
        SizedBox(width: 50, child: Text('${_gutterOverhang.round()} mm')),
      ],
    );
  }

  Widget _buildDryRidgeToggle() {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('Use Dry Ridge:')),
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
                  },
                ),
              ),
              const Text('Yes'),
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
                  },
                ),
              ),
              const Text('No'),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRafterInputs() {
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
                      onChanged: (value) {
                        setState(() {
                          _rafterNames[i] = value;
                        });
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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

  Widget _buildProFeaturePrompt() {
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
                  ),
                ),
                const Text(
                  'Upgrade to Pro to calculate multiple rafters at once',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go('/subscription'),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(CalculatorState calcState) {
    final result = calcState.verticalResult!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
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
                      ),
                ),
                Text(
                  result.solution,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _resultItem('Input Rafter', '${result.inputRafter} mm'),
                _resultItem('Total Courses', result.totalCourses.toString()),
                _resultItem('Ridge Offset', '${result.ridgeOffset} mm'),
                if (result.underEaveBatten != null)
                  _resultItem(
                      'Under Eave Batten', '${result.underEaveBatten} mm'),
                if (result.eaveBatten != null)
                  _resultItem('Eave Batten', '${result.eaveBatten} mm'),
                _resultItem('1st Batten', '${result.firstBatten} mm'),
                if (result.cutCourse != null)
                  _resultItem('Cut Course', '${result.cutCourse} mm'),
                _resultItem('Gauge', result.gauge),
                if (result.splitGauge != null)
                  _resultItem('Split Gauge', result.splitGauge!),
              ],
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
                    Expanded(child: Text(result.warning!)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                  label: 'Save Calculation',
                  child: OutlinedButton(
                    onPressed:
                        widget.canExport ? () => _saveResult(calcState) : null,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Share Calculation',
                  child: OutlinedButton(
                    onPressed: widget.canExport
                        ? () {}
                        : null, // TODO: Implement share
                    child: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _resultItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: Text(value)),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
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
            onPressed: () => Navigator.of(context).pop(),
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
    });
  }

  void _removeRafter(int index) {
    if (!widget.canUseMultipleRafters || _rafterControllers.length <= 1) return;
    setState(() {
      _rafterControllers[index].dispose();
      _rafterControllers.removeAt(index);
      _rafterNames.removeAt(index);
    });
  }

  Future<void> calculate() async {
    final calculatorState = ref.read(calculatorProvider);
    if (calculatorState.selectedTile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return;
    }

    final List<double> rafterHeights = [];
    final displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final heightText = _rafterControllers[i].text.trim();
      if (heightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a height for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}',
            ),
          ),
        );
        return;
      }
      final double? height = double.tryParse(heightText);
      if (height == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid height value for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}',
            ),
          ),
        );
        return;
      }
      rafterHeights.add(height);
    }

    await ref
        .read(calculatorProvider.notifier)
        .calculateVertical(rafterHeights);
    if (calculatorState.verticalResult != null && widget.canExport) {
      await _saveResult(calculatorState);
    }
  }

  Future<void> _saveResult(CalculatorState calcState) async {
    final result = calcState.verticalResult;
    final tile = calcState.selectedTile;
    if (result == null || tile == null) return;

    final savedResult = SavedResult(
      'Vertical Result',
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      projectName: 'Vertical Calculation ${DateTime.now().toIso8601String()}',
      type: CalculationType.vertical,
      timestamp: DateTime.now(),
      inputs: {
        'rafterHeights': _rafterControllers.map((c) => c.text).toList(),
        'gutterOverhang': _gutterOverhang,
        'useDryRidge': _useDryRidge,
      },
      outputs: result.toJson(),
      tile: tile.toJson(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final resultsService = ResultsService();
      await resultsService.saveResult(widget.user.id, savedResult);
      final resultsBox = Hive.box<SavedResult>('resultsBox');
      await resultsBox.put(savedResult.id, savedResult);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result saved successfully')),
      );
      context.go('/results');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving result: $e')),
      );
    }
  }
}
