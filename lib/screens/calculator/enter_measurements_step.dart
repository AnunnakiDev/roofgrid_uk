import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/screens/calculator/horizontal_calculator_tab.dart';
import 'package:roofgrid_uk/screens/calculator/vertical_calculator_tab.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/layout_utils.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_keyboard_context_bar.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/selected_tile_row.dart';

class EnterMeasurementsStep extends StatefulWidget {
  final UserModel user;
  final bool effectiveIsPro;
  final CalculationTypeSelection calculationType;
  final VerticalInputs initialVerticalInputs;
  final HorizontalInputs initialHorizontalInputs;
  final VoidCallback? onBackToTileSelect;
  final Function(VerticalInputs, HorizontalInputs) onCalculate;
  final Widget Function(TileSlateType) placeholderImageBuilder;

  const EnterMeasurementsStep({
    super.key,
    required this.user,
    required this.effectiveIsPro,
    required this.calculationType,
    required this.initialVerticalInputs,
    required this.initialHorizontalInputs,
    this.onBackToTileSelect,
    required this.onCalculate,
    required this.placeholderImageBuilder,
  });

  @override
  State<EnterMeasurementsStep> createState() => _EnterMeasurementsStepState();
}

class _EnterMeasurementsStepState extends State<EnterMeasurementsStep> {
  int _currentStep = 0;
  VerticalInputs _verticalInputs;
  HorizontalInputs _horizontalInputs;
  bool _isVerticalInputsValid = false;
  bool _isHorizontalInputsValid = false;
  final ScrollController _scrollController = ScrollController();

  _EnterMeasurementsStepState()
      : _verticalInputs = VerticalInputs(),
        _horizontalInputs = HorizontalInputs();

  @override
  void initState() {
    super.initState();
    _verticalInputs = widget.initialVerticalInputs;
    _horizontalInputs = widget.initialHorizontalInputs;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateVerticalInputs(VerticalInputs inputs, bool isValid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _verticalInputs = inputs;
        _isVerticalInputsValid = isValid;
      });
    });
  }

  void _updateHorizontalInputs(HorizontalInputs inputs, bool isValid) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _horizontalInputs = inputs;
        _isHorizontalInputsValid = isValid;
      });
    });
  }

  bool get _isCombinedMode =>
      widget.calculationType == CalculationTypeSelection.both;

  bool _isStepExpanded(int index) {
    return _isCombinedMode || _currentStep == index;
  }

  Widget _buildMeasurementSection({
    required int index,
    required String title,
    required bool isCompleted,
    required bool isActive,
    required Widget content,
    required bool isNarrow,
  }) {
    if (!isActive) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    if (_isCombinedMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isNarrow ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isCompleted)
                  Text(
                    'Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: content,
    );
  }

  List<Map<String, dynamic>> _buildSteps(BuildContext context) {
    final List<Map<String, dynamic>> steps = [];

    if (widget.calculationType == CalculationTypeSelection.verticalOnly ||
        widget.calculationType == CalculationTypeSelection.both) {
      steps.add({
        'title': measurementStepTitle(
          widget.calculationType,
          isVerticalStep: true,
        ),
        'isCompleted': _isVerticalInputsValid,
        'content': VerticalCalculatorTab(
            user: widget.user,
            canUseMultipleRafters: widget.effectiveIsPro,
            canUseAdvancedOptions: widget.effectiveIsPro,
            canExport: widget.effectiveIsPro,
            canAccessDatabase: widget.effectiveIsPro,
            initialInputs: _verticalInputs,
            onInputsChanged: _updateVerticalInputs,
          ),
      });
    }

    if (widget.calculationType == CalculationTypeSelection.horizontalOnly ||
        widget.calculationType == CalculationTypeSelection.both) {
      steps.add({
        'title': measurementStepTitle(
          widget.calculationType,
          isVerticalStep: false,
        ),
        'isCompleted': _isHorizontalInputsValid,
        'content': HorizontalCalculatorTab(
            user: widget.user,
            canUseMultipleWidths: widget.effectiveIsPro,
            canUseAdvancedOptions: widget.effectiveIsPro,
            canExport: widget.effectiveIsPro,
            canAccessDatabase: widget.effectiveIsPro,
            initialInputs: _horizontalInputs,
            onInputsChanged: _updateHorizontalInputs,
          ),
      });
    }

    return steps;
  }

  bool _canProceed() {
    if (_currentStep == 0) {
      if (widget.calculationType == CalculationTypeSelection.verticalOnly ||
          widget.calculationType == CalculationTypeSelection.both) {
        return _isVerticalInputsValid;
      }
    }
    if (_currentStep == 1 &&
        widget.calculationType == CalculationTypeSelection.both) {
      return _isHorizontalInputsValid;
    }
    return true;
  }

  bool _isCalculateEnabled() {
    if (widget.calculationType == CalculationTypeSelection.verticalOnly) {
      return _isVerticalInputsValid;
    } else if (widget.calculationType ==
        CalculationTypeSelection.horizontalOnly) {
      return _isHorizontalInputsValid;
    } else {
      return _isVerticalInputsValid && _isHorizontalInputsValid;
    }
  }

  String _getCalculateButtonLabel() {
    return 'Calculate';
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = isNarrowLayout(context);
    final padding = isNarrow ? 12.0 : 16.0;
    final fontSize = isNarrow ? 12.0 : 14.0;

    final steps = _buildSteps(context);
    // Scaffold removes viewInsets from MediaQuery when resizing for the keyboard.
    final keyboardInset = View.of(context).viewInsets.bottom;
    final keyboardOpen = keyboardInset > 0;

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        children: [
          if (keyboardOpen)
            CalculatorKeyboardContextBar(
              calculationType: widget.calculationType,
            )
          else
            Padding(
              padding: EdgeInsets.only(top: padding, bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CalculatorStepProgress(
                    currentStep: CalculatorFlowStep.enterMeasurements,
                    compact: isNarrow,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    calculationTypeLabel(widget.calculationType),
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: keyboardInset + 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return _buildMeasurementSection(
                            index: index,
                            title: step['title'],
                            isCompleted: step['isCompleted'],
                            isActive: _isStepExpanded(index),
                            isNarrow: isNarrow,
                            content: step['content'],
                          );
                        }),
                        if (!_isCombinedMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_currentStep > 0 ||
                                    widget.onBackToTileSelect != null)
                                  OutlinedButton(
                                    onPressed: () {
                                      if (_currentStep > 0) {
                                        setState(() {
                                          _currentStep -= 1;
                                        });
                                      } else {
                                        widget.onBackToTileSelect?.call();
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(110, 48),
                                    ),
                                    child: Text(
                                      _currentStep == 0 ? 'Back' : 'Previous',
                                    ),
                                  )
                                else
                                  const SizedBox(width: 110),
                                if (_currentStep < steps.length - 1)
                                  ElevatedButton(
                                    onPressed: _canProceed()
                                        ? () {
                                            setState(() {
                                              _currentStep += 1;
                                            });
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(110, 48),
                                    ),
                                    child: const Text('Continue'),
                                  ),
                              ],
                            ),
                          )
                        else if (widget.onBackToTileSelect != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton(
                                onPressed: widget.onBackToTileSelect,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(110, 48),
                                ),
                                child: const Text('Back'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!keyboardOpen)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      color: colorScheme.surface,
                    ),
                    child: SelectedTileRow(
                      user: widget.user,
                      effectiveIsPro: widget.effectiveIsPro,
                      compact: true,
                      placeholderImageBuilder: widget.placeholderImageBuilder,
                    ),
                  ),
                SafeArea(
                  top: false,
                  bottom: true,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: keyboardOpen ? padding : 4,
                      bottom: padding,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isCalculateEnabled()
                          ? () => widget.onCalculate(
                                _verticalInputs,
                                _horizontalInputs,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      icon: const Icon(Icons.calculate_rounded),
                      label: Text(
                        _getCalculateButtonLabel(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
