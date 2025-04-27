import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';
import 'package:roofgrid_uk/screens/calculator/vertical_calculator_tab.dart';
import 'package:roofgrid_uk/screens/calculator/horizontal_calculator_tab.dart';
import 'package:roofgrid_uk/widgets/selected_tile_row.dart';

class EnterMeasurementsStep extends StatefulWidget {
  final UserModel user;
  final CalculationTypeSelection calculationType;
  final VerticalInputs initialVerticalInputs;
  final HorizontalInputs initialHorizontalInputs;
  final VoidCallback onChangeType;
  final Function(VerticalInputs, HorizontalInputs) onCalculate;
  final Widget Function(TileSlateType) placeholderImageBuilder;

  const EnterMeasurementsStep({
    super.key,
    required this.user,
    required this.calculationType,
    required this.initialVerticalInputs,
    required this.initialHorizontalInputs,
    required this.onChangeType,
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

  _EnterMeasurementsStepState()
      : _verticalInputs = VerticalInputs(),
        _horizontalInputs = HorizontalInputs();

  @override
  void initState() {
    super.initState();
    _verticalInputs = widget.initialVerticalInputs;
    _horizontalInputs = widget.initialHorizontalInputs;
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

  Widget _buildCustomStep({
    required int index,
    required String title,
    required bool isCompleted,
    required bool isActive,
    required Widget content,
    required double fontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize + 2, // Increased font size
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black,
              ),
            ),
            if (isCompleted) ...[
              const SizedBox(width: 8),
              Text(
                'Completed',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: fontSize - 4,
                ),
              ).animate().fadeIn(duration: 300.ms),
            ],
          ],
        ),
        if (isActive)
          Padding(
            padding: const EdgeInsets.only(left: 32.0), // Align with title
            child: content,
          ),
        if (index < _buildSteps(context).length - 1)
          Container(
            margin: const EdgeInsets.only(left: 11.5),
            width: 1,
            height: 16,
            color: Colors.grey,
          ),
      ],
    );
  }

  List<Map<String, dynamic>> _buildSteps(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final fontSize = isLargeScreen ? 14.0 : 12.0;

    final List<Map<String, dynamic>> steps = [];

    if (widget.calculationType == CalculationTypeSelection.verticalOnly ||
        widget.calculationType == CalculationTypeSelection.both) {
      steps.add({
        'title': 'Vertical Measurements',
        'isCompleted': _isVerticalInputsValid,
        'content': Animate(
          effects: [
            FadeEffect(duration: 300.ms),
            SlideEffect(
              begin: const Offset(-0.2, 0),
              end: Offset.zero,
              duration: 300.ms,
            ),
          ],
          child: VerticalCalculatorTab(
            user: widget.user,
            canUseMultipleRafters: widget.user.isPro,
            canUseAdvancedOptions: widget.user.isPro,
            canExport: widget.user.isPro,
            canAccessDatabase: widget.user.isPro,
            initialInputs: _verticalInputs,
            onInputsChanged: _updateVerticalInputs,
          ),
        ),
        'fontSize': fontSize,
      });
    }

    if (widget.calculationType == CalculationTypeSelection.horizontalOnly ||
        widget.calculationType == CalculationTypeSelection.both) {
      steps.add({
        'title': 'Horizontal Measurements',
        'isCompleted': _isHorizontalInputsValid,
        'content': Animate(
          effects: [
            FadeEffect(duration: 300.ms),
            SlideEffect(
              begin: const Offset(-0.2, 0),
              end: Offset.zero,
              duration: 300.ms,
            ),
          ],
          child: HorizontalCalculatorTab(
            user: widget.user,
            canUseMultipleWidths: widget.user.isPro,
            canUseAdvancedOptions: widget.user.isPro,
            canExport: widget.user.isPro,
            canAccessDatabase: widget.user.isPro,
            initialInputs: _horizontalInputs,
            onInputsChanged: _updateHorizontalInputs,
          ),
        ),
        'fontSize': fontSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 16.0 : 12.0;
    final fontSize = isLargeScreen ? 14.0 : 12.0;

    final steps = _buildSteps(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: padding),
            child: Semantics(
              label: 'Step 3: Enter Your Measurements',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'Step 3: Enter Your Measurements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.0),
            child: SelectedTileRow(
              user: widget.user,
              placeholderImageBuilder: widget.placeholderImageBuilder,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 0.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calculation Type: ${widget.calculationType.toString().split('.').last.replaceAll('Only', '').replaceAll('both', 'Both (Combined)')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: fontSize - 2,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                TextButton(
                  onPressed: widget.onChangeType,
                  child: Text(
                    'Change',
                    style: TextStyle(fontSize: fontSize - 4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...steps.asMap().entries.map((entry) {
                          final index = entry.key;
                          final step = entry.value;
                          return _buildCustomStep(
                            index: index,
                            title: step['title'],
                            isCompleted: step['isCompleted'],
                            isActive: _currentStep == index,
                            content: step['content'],
                            fontSize: step['fontSize'],
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  if (_currentStep > 0) {
                                    setState(() {
                                      _currentStep -= 1;
                                    });
                                  } else {
                                    widget.onChangeType();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(100, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  backgroundColor: Colors.grey,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(
                                  _currentStep == 0 ? 'Back' : 'Previous',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
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
                                    minimumSize: const Size(100, 36),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.9),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  bottom: true,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: padding),
                    child: AnimatedScale(
                      scale: _isCalculateEnabled() ? 1.0 : 0.8,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        onPressed: _isCalculateEnabled()
                            ? () => widget.onCalculate(
                                _verticalInputs, _horizontalInputs)
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          _getCalculateButtonLabel(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
