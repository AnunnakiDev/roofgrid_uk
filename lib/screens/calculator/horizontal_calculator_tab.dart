import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/utils/form_validator.dart';
import 'package:roofgrid_uk/widgets/on_off_toggle.dart';

class HorizontalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleWidths;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;
  final HorizontalInputs initialInputs;
  final void Function(HorizontalInputs, bool) onInputsChanged;

  const HorizontalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleWidths,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
    required this.initialInputs,
    required this.onInputsChanged,
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
  bool _isOnline = true;
  List<Color> _widthColors = [];
  bool _isInputsValid = false;

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
    final isValid = FormValidator.validatePositiveNumbers(_widthControllers);
    setState(() {
      _isInputsValid = isValid;
    });

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
      crossBonded: '',
    );
    widget.onInputsChanged(inputs, _isInputsValid);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 12.0 : 8.0;
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
          _buildAbutmentSideSelector(fontSize),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildDryVergeToggle(fontSize)),
              const SizedBox(width: 16),
              Expanded(child: _buildLHTileToggle(fontSize)),
            ],
          ),
          const SizedBox(height: 16),
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
          child: OnOffToggle(
            label: 'Use Dry Verge',
            value: _useDryVerge == 'YES',
            onChanged: (value) {
              setState(() {
                _useDryVerge = value ? 'YES' : 'NO';
              });
              ref
                  .read(calculatorProvider.notifier)
                  .setUseDryVerge(_useDryVerge);
              _validateInputs();
            },
            fontSize: fontSize - 2,
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
              isDense: true,
              underline: const SizedBox(),
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
                _validateInputs();
              },
              style: TextStyle(
                  fontSize: fontSize - 2,
                  color: Theme.of(context).textTheme.bodyMedium?.color),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
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
          child: OnOffToggle(
            label: 'Use Left Hand Tile',
            value: _useLHTile == 'YES',
            onChanged: (value) {
              setState(() {
                _useLHTile = value ? 'YES' : 'NO';
              });
              ref.read(calculatorProvider.notifier).setUseLHTile(_useLHTile);
              _validateInputs();
            },
            fontSize: fontSize - 2,
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
          padding: const EdgeInsets.only(bottom: 8.0),
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
                        _validateInputs();
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
                      border: const OutlineInputBorder(),
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
    _validateInputs();
  }

  void _removeWidth(int index) {
    if (!widget.canUseMultipleWidths || _widthControllers.length <= 1) return;
    setState(() {
      _widthControllers[index].dispose();
      _widthControllers.removeAt(index);
      _widthNames.removeAt(index);
      _widthColors.removeAt(index);
    });
    _validateInputs();
  }
}
