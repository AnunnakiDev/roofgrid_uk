import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/form_validator.dart';
import 'package:roofgrid_uk/utils/calculator_input_colors.dart';
import 'package:roofgrid_uk/utils/keyboard_scroll_utils.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_input_section.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_mm_stepper.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_measurement_field.dart';
import 'package:roofgrid_uk/widgets/calculator/schematic_preview_strip.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
        .map((entry) => calculatorInputColorForIndex(entry.key))
        .toList();

    _checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _isOnline = isOnlineFromResults(result);
      });
    });

    if (widget.user.isTrialAboutToExpire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpirationWarning(context);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calculatorProvider.notifier).hydrateCalculatorOptionsFromInputs(
            vertical: widget.initialInputs,
          );
      _validateInputs();
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await isDeviceOnline();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
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
    _connectivitySubscription?.cancel();
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

    final rafterValues = _rafterControllers
        .map((controller) => double.tryParse(controller.text) ?? 0)
        .toList();

    final dense = !isLargeScreen;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, dense ? 8 : padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalculatorInputSection(
            title: 'Rafter Measurements',
            helperText: 'Measure from top of fascia to ridge.',
            dense: dense,
            trailing: widget.canUseMultipleRafters
                ? Semantics(
                    label: 'Add new rafter input',
                    child: TextButton.icon(
                      onPressed: _addRafter,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add rafter'),
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildRafterInputs(fontSize),
                const SizedBox(height: 12),
                SchematicPreviewStrip(
                  axis: SchematicPreviewAxis.verticalBatten,
                  dimensionsMm: rafterValues,
                ),
              ],
            ),
          ),
          SizedBox(height: dense ? 10 : 14),
          CalculatorInputSection(
            title: 'Options',
            dense: dense,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildDryRidgeToggle(fontSize)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildGutterOverhangControl(fontSize)),
                ],
              ),
            ),
          ),
          if (!widget.canUseMultipleRafters) _buildProFeaturePrompt(fontSize),
        ],
      ),
    );
  }

  Widget _buildDryRidgeToggle(double fontSize) {
    return CalculatorOptionTile(
      title: 'Dry Ridge',
      subtitle: 'Use dry ridge allowance',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Enabled', style: TextStyle(fontSize: fontSize - 1)),
          OnOffToggle(
            label: 'Use Dry Ridge',
            value: _useDryRidge == 'YES',
            onChanged: (value) {
              setState(() {
                _useDryRidge = value ? 'YES' : 'NO';
              });
              ref.read(calculatorProvider.notifier).setUseDryRidge(_useDryRidge);
              _validateInputs();
            },
            fontSize: fontSize - 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGutterOverhangControl(double fontSize) {
    return CalculatorOptionTile(
      title: 'Gutter Overhang',
      child: CalculatorMmStepper(
        value: _gutterOverhang.round(),
        semanticsLabel: 'Gutter overhang',
        onChanged: (value) {
          setState(() {
            _gutterOverhang = value.toDouble();
          });
          ref
              .read(calculatorProvider.notifier)
              .setGutterOverhang(value.toDouble());
          _validateInputs();
        },
      ),
    );
  }

  List<Widget> _buildRafterInputs(double fontSize) {
    final List<Widget> rafterInputs = [];
    final int displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final accent = calculatorInputColorFromTheme(context, i);

      rafterInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accent, width: 3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.canUseMultipleRafters) ...[
                    Expanded(
                      flex: 4,
                      child: Semantics(
                        label: 'Rafter Name ${i + 1}',
                        child: TextField(
                          controller:
                              TextEditingController(text: _rafterNames[i]),
                          decoration: const InputDecoration(
                            labelText: 'Label',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                          style: TextStyle(fontSize: fontSize),
                          onTap: () => ensureFieldVisible(context),
                          onChanged: (value) {
                            setState(() {
                              _rafterNames[i] = value.isNotEmpty
                                  ? value
                                  : 'Rafter ${i + 1}';
                            });
                            _validateInputs();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: widget.canUseMultipleRafters ? 3 : 1,
                    child: CalculatorMeasurementField(
                      controller: _rafterControllers[i],
                      semanticsLabel: 'Rafter Measurement ${i + 1}',
                      labelText: widget.canUseMultipleRafters
                          ? null
                          : 'Rafter height',
                      accentColor:
                          widget.canUseMultipleRafters ? accent : null,
                      onChanged: (_) => _validateInputs(),
                    ),
                  ),
                  if (widget.canUseMultipleRafters &&
                      _rafterControllers.length > 1) ...[
                    const SizedBox(width: 4),
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
            Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
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
      _rafterColors.add(
          calculatorInputColorForIndex(_rafterControllers.length - 1));
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
