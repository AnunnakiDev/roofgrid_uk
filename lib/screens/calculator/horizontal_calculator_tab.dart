import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/services/results_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class HorizontalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleWidths;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;

  const HorizontalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleWidths,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
  });

  @override
  HorizontalCalculatorTabState createState() => HorizontalCalculatorTabState();
}

class HorizontalCalculatorTabState
    extends ConsumerState<HorizontalCalculatorTab> {
  final List<TextEditingController> _widthControllers = [
    TextEditingController()
  ];
  final List<String> _widthNames = ['Width 1'];
  String _useDryVerge = 'NO';
  String _abutmentSide = 'NONE';
  String _useLHTile = 'NO';
  String _crossBonded = 'NO';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
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
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
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
          _buildDryVergeToggle(),
          _buildAbutmentSideSelector(),
          _buildLHTileToggle(),
          _buildCrossBondedToggle(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Width Measurements',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.canUseMultipleWidths)
                Semantics(
                  label: 'Add new width input',
                  child: TextButton(
                    onPressed: _addWidth,
                    child: const Text('Add Width'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildWidthInputs(),
          if (!widget.canUseMultipleWidths) _buildProFeaturePrompt(),
          if (calcState.horizontalResult != null) _buildResultsCard(calcState),
          if (calcState.errorMessage != null)
            _buildErrorMessage(calcState.errorMessage!),
        ],
      ),
    );
  }

  Widget _buildDryVergeToggle() {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('Use Dry Verge:')),
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
                  },
                ),
              ),
              const Text('Yes'),
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

  Widget _buildAbutmentSideSelector() {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('Abutment Side:')),
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
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLHTileToggle() {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('Use Left Hand Tile:')),
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
                  },
                ),
              ),
              const Text('Yes'),
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

  Widget _buildCrossBondedToggle() {
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('Cross Bonded:')),
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
                  },
                ),
              ),
              const Text('Yes'),
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

  List<Widget> _buildWidthInputs() {
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
                      onChanged: (value) {
                        setState(() {
                          _widthNames[i] = value;
                        });
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                  'Upgrade to Pro to calculate multiple widths at once',
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
    final result = calcState.horizontalResult!;
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
                  'Horizontal Calculation Results',
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
                _resultItem('Width', '${result.width} mm'),
                _resultItem('New Width', '${result.newWidth} mm'),
                if (result.lhOverhang != null)
                  _resultItem('LH Overhang', '${result.lhOverhang} mm'),
                if (result.rhOverhang != null)
                  _resultItem('RH Overhang', '${result.rhOverhang} mm'),
                if (result.cutTile != null)
                  _resultItem('Cut Tile', '${result.cutTile} mm'),
                _resultItem('First Mark', '${result.firstMark} mm'),
                if (result.secondMark != null)
                  _resultItem('Second Mark', '${result.secondMark} mm'),
                _resultItem('Marks', result.marks),
                if (result.splitMarks != null)
                  _resultItem('Split Marks', result.splitMarks!),
              ],
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

  void _addWidth() {
    if (!widget.canUseMultipleWidths) return;
    setState(() {
      _widthControllers.add(TextEditingController());
      _widthNames.add('Width ${_widthControllers.length}');
    });
  }

  void _removeWidth(int index) {
    if (!widget.canUseMultipleWidths || _widthControllers.length <= 1) return;
    setState(() {
      _widthControllers[index].dispose();
      _widthControllers.removeAt(index);
      _widthNames.removeAt(index);
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

    final List<double> widths = [];
    final displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final widthText = _widthControllers[i].text.trim();
      if (widthText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a width for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}',
            ),
          ),
        );
        return;
      }
      final double? width = double.tryParse(widthText);
      if (width == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid width value for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}',
            ),
          ),
        );
        return;
      }
      widths.add(width);
    }

    await ref.read(calculatorProvider.notifier).calculateHorizontal(widths);
    if (calculatorState.horizontalResult != null && widget.canExport) {
      await _saveResult(calculatorState);
    }
  }

  Future<void> _saveResult(CalculatorState calcState) async {
    final result = calcState.horizontalResult;
    final tile = calcState.selectedTile;
    if (result == null || tile == null) return;

    final savedResult = SavedResult(
      'Horizontal Result',
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.user.id,
      projectName: 'Horizontal Calculation ${DateTime.now().toIso8601String()}',
      type: CalculationType.horizontal,
      timestamp: DateTime.now(),
      inputs: {
        'widths': _widthControllers.map((c) => c.text).toList(),
        'useDryVerge': _useDryVerge,
        'abutmentSide': _abutmentSide,
        'useLHTile': _useLHTile,
        'crossBonded': _crossBonded,
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
