import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_mm_stepper.dart';

class _StepperHarness extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;

  const _StepperHarness({
    required this.initialValue,
    this.min = 0,
    this.max = 100,
  });

  @override
  State<_StepperHarness> createState() => _StepperHarnessState();
}

class _StepperHarnessState extends State<_StepperHarness> {
  late int value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return CalculatorMmStepper(
      value: value,
      min: widget.min,
      max: widget.max,
      onChanged: (next) => setState(() => value = next),
    );
  }
}

Finder _stepperIconButton(IconData icon) {
  return find.descendant(
    of: find.byType(CalculatorMmStepper),
    matching: find.widgetWithIcon(IconButton, icon),
  );
}

void main() {
  testWidgets('CalculatorMmStepper increments and decrements value',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _StepperHarness(initialValue: 10),
        ),
      ),
    );

    await tester.tap(_stepperIconButton(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('11 mm'), findsOneWidget);

    await tester.tap(_stepperIconButton(Icons.remove));
    await tester.pumpAndSettle();
    expect(find.text('10 mm'), findsOneWidget);
  });

  testWidgets('CalculatorMmStepper clamps at min and max', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _StepperHarness(initialValue: 0, min: 0, max: 2),
        ),
      ),
    );

    expect(
      tester.widget<IconButton>(_stepperIconButton(Icons.remove)).onPressed,
      isNull,
    );

    await tester.tap(_stepperIconButton(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(_stepperIconButton(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('2 mm'), findsOneWidget);

    expect(
      tester.widget<IconButton>(_stepperIconButton(Icons.add)).onPressed,
      isNull,
    );
  });

  testWidgets('CalculatorMmStepper opens direct entry dialog', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: _StepperHarness(initialValue: 25),
        ),
      ),
    );

    await tester.tap(find.text('25 mm'));
    await tester.pumpAndSettle();

    expect(find.text('Enter value'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '42');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('42 mm'), findsOneWidget);
  });
}