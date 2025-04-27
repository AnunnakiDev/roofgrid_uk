import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/screens/calculator/calculator_screen.dart';

class SelectCalculationTypeStep extends StatefulWidget {
  final ValueChanged<CalculationTypeSelection> onTypeSelected;

  const SelectCalculationTypeStep({
    super.key,
    required this.onTypeSelected,
  });

  @override
  State<SelectCalculationTypeStep> createState() =>
      _SelectCalculationTypeStepState();
}

class _SelectCalculationTypeStepState extends State<SelectCalculationTypeStep> {
  CalculationTypeSelection? _calculationType;

  void _updateCalculationType(CalculationTypeSelection? value) {
    // Defer the setState call until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _calculationType = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 12.0 : 8.0;
    final fontSize = isLargeScreen ? 14.0 : 12.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Semantics(
            label: 'Step 2: Select Calculation Type',
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Text(
                'Step 2: Select Calculation Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    100, // Adjust based on header and button height
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'What type of calculation would you like to perform?',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<CalculationTypeSelection>(
                        title: Text('Vertical Only',
                            style: TextStyle(fontSize: fontSize - 2)),
                        subtitle: Text(
                          'Calculate batten spacing based on rafter heights',
                          style: TextStyle(fontSize: fontSize - 4),
                        ),
                        value: CalculationTypeSelection.verticalOnly,
                        groupValue: _calculationType,
                        onChanged: _updateCalculationType,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<CalculationTypeSelection>(
                        title: Text('Horizontal Only',
                            style: TextStyle(fontSize: fontSize - 2)),
                        subtitle: Text(
                          'Calculate tile spacing based on widths',
                          style: TextStyle(fontSize: fontSize - 4),
                        ),
                        value: CalculationTypeSelection.horizontalOnly,
                        groupValue: _calculationType,
                        onChanged: _updateCalculationType,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      RadioListTile<CalculationTypeSelection>(
                        title: Text('Both (Combined)',
                            style: TextStyle(fontSize: fontSize - 2)),
                        subtitle: Text(
                          'Calculate a full roof layout with both vertical and horizontal measurements',
                          style: TextStyle(fontSize: fontSize - 4),
                        ),
                        value: CalculationTypeSelection.both,
                        groupValue: _calculationType,
                        onChanged: _updateCalculationType,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: AnimatedScale(
                          scale: _calculationType == null ? 0.8 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: _calculationType == null
                                ? null
                                : () {
                                    widget.onTypeSelected(_calculationType!);
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(150, 40),
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
                            child: const Text(
                              'Next',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Ensure space at the bottom
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
