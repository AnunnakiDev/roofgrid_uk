import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/utils/form_validator.dart';
import 'package:roofgrid_uk/widgets/on_off_toggle.dart';

class VerticalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleRafters;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;
  final VerticalInputs initialInputs;
  final void Function(VerticalInputs, bool) onInputsChanged;

  const VerticalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleRafters,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
    required this.initialInputs,
    required this.onInputsChanged,
  });

  @override
  VerticalCalculatorTabState createState() => VerticalCalculatorTabState();
}

class VerticalCalculatorTabState extends ConsumerState<VerticalCalculatorTab> {
  late List<TextEditingController> _rafterControllers;
  late List<String> _rafterNames;
  late double _gutterOverhang;
  late String _useDryRidge;
  bool _isOnline = true;
  List<Color> _rafterColors = [];
  bool _isInputsValid = false;

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

    // Validate initial inputs
    _validateInputs();
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

  void _validateInputs() {
    final isValid = FormValidator.validatePositiveNumbers(_rafterControllers);
    setState(() {
      _isInputsValid = isValid;
    });

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
    widget.onInputsChanged(inputs, _isInputsValid);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 16.0 : 12.0;
    final fontSize = isLargeScreen ? 14.0 : 12.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
          ),
          const SizedBox(height: 8),
          _buildDryRidgeToggle(fontSize),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gutter Overhang',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _gutterOverhang,
                  min: 0.0,
                  max: 100.0,
                  divisions: 100,
                  label: '${_gutterOverhang.round()} mm',
                  onChanged: (value) {
                    setState(() {
                      _gutterOverhang = value;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setGutterOverhang(value);
                    _validateInputs();
                  },
                ),
              ),
              Text(
                '${_gutterOverhang.round()} mm',
                style: TextStyle(fontSize: fontSize - 2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rafter Measurements',
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
        ],
      ),
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
          child: OnOffToggle(
            label: 'Use Dry Ridge',
            value: _useDryRidge == 'YES',
            onChanged: (value) {
              setState(() {
                _useDryRidge = value ? 'YES' : 'NO';
              });
              ref
                  .read(calculatorProvider.notifier)
                  .setUseDryRidge(_useDryRidge);
              _validateInputs();
            },
            fontSize: fontSize - 2,
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
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              if (widget.canUseMultipleRafters) ...[
                Expanded(
                  flex: 4, // Wider name box
                  child: Semantics(
                    label: 'Rafter Name ${i + 1}',
                    child: TextField(
                      controller: TextEditingController(text: _rafterNames[i]),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12), // Same height as number box
                      ),
                      style: TextStyle(fontSize: fontSize - 2),
                      onChanged: (value) {
                        setState(() {
                          _rafterNames[i] = value.isNotEmpty
                              ? value
                              : 'Rafter ${i + 1}'; // Default name if empty
                        });
                        _validateInputs();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex:
                    widget.canUseMultipleRafters ? 3 : 8, // Smaller number box
                child: Semantics(
                  label: 'Rafter Measurement ${i + 1}',
                  child: TextField(
                    controller: _rafterControllers[i],
                    decoration: InputDecoration(
                      labelText: widget.canUseMultipleRafters
                          ? null
                          : 'Rafter Height in mm',
                      hintText: 'e.g., 4000',
                      suffixText: 'mm',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12), // Reduced height
                    ),
                    style: TextStyle(fontSize: fontSize - 2),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      _validateInputs();
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
      margin: const EdgeInsets.symmetric(vertical: 8),
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
    _validateInputs();
  }

  void _removeRafter(int index) {
    if (!widget.canUseMultipleRafters || _rafterControllers.length <= 1) return;
    setState(() {
      _rafterControllers[index].dispose();
      _rafterControllers.removeAt(index);
      _rafterNames.removeAt(index);
      _rafterColors.removeAt(index);
    });
    _validateInputs();
  }
}
