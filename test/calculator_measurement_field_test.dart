import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_measurement_field.dart';

void main() {
  testWidgets('CalculatorMeasurementField focuses without throwing',
      (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalculatorMeasurementField(
            controller: controller,
            semanticsLabel: 'Rafter Measurement 1',
            labelText: 'Rafter height',
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    expect(controller, isNotNull);

    controller.dispose();
  });
}