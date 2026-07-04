import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/form_validator.dart';
import 'package:roofgrid_uk/utils/calculator_input_colors.dart';
import 'package:roofgrid_uk/utils/keyboard_scroll_utils.dart';
import 'package:roofgrid_uk/utils/calculator_input_visibility.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_input_section.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_measurement_field.dart';
import 'package:roofgrid_uk/widgets/calculator/schematic_preview_strip.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

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
    if (!isLeftHandTileEnabled(_abutmentSide)) {
      _useLHTile = 'NO';
    }

    // Assign colors to each width
    _widthColors = _widthNames
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
            horizontal: widget.initialInputs,
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
      crossBonded: ref.read(calculatorProvider).crossBonded,
    );
    widget.onInputsChanged(inputs, _isInputsValid);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    for (final controller in _widthControllers) {
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
    final selectedTile =
        ref.watch(calculatorProvider.select((state) => state.selectedTile));
    ref.listen(
      calculatorProvider.select((state) => state.crossBonded),
      (previous, next) {
        if (previous != next) {
          _validateInputs();
        }
      },
    );

    final widthValues = _widthControllers
        .map((controller) => double.tryParse(controller.text) ?? 0)
        .toList();

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalculatorInputSection(
            title: 'Options',
            child: Column(
              children: [
                _buildAbutmentSideSelector(fontSize),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildDryVergeToggle(fontSize)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildLHTileToggle(fontSize)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _buildCrossBondedInfo(fontSize, selectedTile),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CalculatorInputSection(
            title: 'Width Measurements',
            helperText: 'Measure verge to verge before overhangs are added.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildWidthInputs(fontSize),
                if (widget.canUseMultipleWidths) ...[
                  const SizedBox(height: 4),
                  Semantics(
                    label: 'Add new width input',
                    child: TextButton.icon(
                      onPressed: _addWidth,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add width'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SchematicPreviewStrip(
                  axis: SchematicPreviewAxis.horizontalCourse,
                  dimensionsMm: widthValues,
                ),
              ],
            ),
          ),
          if (!widget.canUseMultipleWidths) _buildProFeaturePrompt(fontSize),
        ],
      ),
    );
  }

  Widget _buildDryVergeToggle(double fontSize) {
    return CalculatorOptionTile(
      title: 'Dry Verge',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Enabled', style: TextStyle(fontSize: fontSize - 1)),
          OnOffToggle(
            label: 'Use Dry Verge',
            value: _useDryVerge == 'YES',
            onChanged: (value) {
              setState(() {
                _useDryVerge = value ? 'YES' : 'NO';
              });
              ref.read(calculatorProvider.notifier).setUseDryVerge(_useDryVerge);
              _validateInputs();
            },
            fontSize: fontSize - 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAbutmentSideSelector(double fontSize) {
    return CalculatorOptionTile(
      title: 'Abutment Side',
      child: Semantics(
        label: 'Abutment Side Selector',
        child: DropdownButtonFormField<String>(
          value: _abutmentSide,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'NONE', child: Text('None')),
            DropdownMenuItem(value: 'LEFT', child: Text('Left')),
            DropdownMenuItem(value: 'RIGHT', child: Text('Right')),
            DropdownMenuItem(value: 'BOTH', child: Text('Both')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _abutmentSide = value;
              if (!isLeftHandTileEnabled(value)) {
                _useLHTile = 'NO';
              }
            });
            ref.read(calculatorProvider.notifier).setAbutmentSide(value);
            if (!isLeftHandTileEnabled(value)) {
              ref.read(calculatorProvider.notifier).setUseLHTile('NO');
            }
            _validateInputs();
          },
        ),
      ),
    );
  }

  Widget _buildLHTileToggle(double fontSize) {
    final lhTileEnabled = isLeftHandTileEnabled(_abutmentSide);

    return Opacity(
      opacity: lhTileEnabled ? 1 : 0.5,
      child: CalculatorOptionTile(
        title: 'Left Hand Tile',
        subtitle: lhTileEnabled ? null : 'Requires left or both abutment',
        child: IgnorePointer(
          ignoring: !lhTileEnabled,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Enabled', style: TextStyle(fontSize: fontSize - 1)),
              OnOffToggle(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrossBondedInfo(double fontSize, TileModel? selectedTile) {
    return CalculatorOptionTile(
      title: 'Cross Bonded',
      child: Text(
        crossBondedDisplayLabel(selectedTile),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  List<Widget> _buildWidthInputs(double fontSize) {
    final List<Widget> widthInputs = [];
    final int displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final accent = calculatorInputColorFromTheme(context, i);

      widthInputs.add(
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
                  if (widget.canUseMultipleWidths) ...[
                    Expanded(
                      flex: 4,
                      child: Semantics(
                        label: 'Width Name ${i + 1}',
                        child: TextField(
                          controller:
                              TextEditingController(text: _widthNames[i]),
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
                              _widthNames[i] = value.isNotEmpty
                                  ? value
                                  : 'Width ${i + 1}';
                            });
                            _validateInputs();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: widget.canUseMultipleWidths ? 3 : 1,
                    child: CalculatorMeasurementField(
                      controller: _widthControllers[i],
                      semanticsLabel: 'Width Measurement ${i + 1}',
                      labelText:
                          widget.canUseMultipleWidths ? null : 'Width',
                      accentColor: widget.canUseMultipleWidths ? accent : null,
                      onChanged: (_) => _validateInputs(),
                    ),
                  ),
                  if (widget.canUseMultipleWidths &&
                      _widthControllers.length > 1) ...[
                    const SizedBox(width: 4),
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
      _widthColors.add(
          calculatorInputColorForIndex(_widthControllers.length - 1));
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
