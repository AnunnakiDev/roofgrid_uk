import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/screens/calculator/horizontal_calculator_tab.dart';

import 'support/calculator_widget_test_harness.dart';

void main() {
  testWidgets('HorizontalCalculatorTab mounts without throwing', (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        HorizontalCalculatorTab(
          user: proTestUser(),
          canUseMultipleWidths: true,
          canUseAdvancedOptions: true,
          canExport: true,
          canAccessDatabase: true,
          initialInputs: HorizontalInputs(),
          onInputsChanged: (_, __) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Width Measurements'), findsOneWidget);
    expect(find.text('Abutment Side'), findsOneWidget);
  });

  testWidgets('Add width button appears in section header trailing',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        SingleChildScrollView(
          child: HorizontalCalculatorTab(
            user: proTestUser(),
            canUseMultipleWidths: true,
            canUseAdvancedOptions: true,
            canExport: true,
            canAccessDatabase: true,
            initialInputs: HorizontalInputs(),
            onInputsChanged: (_, __) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = tester.getTopLeft(find.text('Add width'));
    final measurementField = tester.getTopLeft(find.text('e.g. 4000'));

    expect(addButton.dy, lessThan(measurementField.dy));
    expect(addButton.dx, greaterThan(measurementField.dx));
  });

  testWidgets('narrow layout stacks dry verge and left hand tile options',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(420, 900)),
          child: SingleChildScrollView(
            child: HorizontalCalculatorTab(
              user: proTestUser(),
              canUseMultipleWidths: true,
              canUseAdvancedOptions: true,
              canExport: true,
              canAccessDatabase: true,
              initialInputs: HorizontalInputs(),
              onInputsChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dryVerge = tester.getTopLeft(find.text('Dry Verge'));
    final lhTile = tester.getTopLeft(find.text('Left Hand Tile'));

    expect(lhTile.dy, greaterThan(dryVerge.dy));
    expect(tester.takeException(), isNull);
  });
}