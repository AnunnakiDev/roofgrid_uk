import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/screens/calculator/vertical_calculator_tab.dart';

import 'support/calculator_widget_test_harness.dart';

void main() {
  testWidgets('VerticalCalculatorTab mounts without throwing', (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        VerticalCalculatorTab(
          user: proTestUser(),
          canUseMultipleRafters: true,
          canUseAdvancedOptions: true,
          canExport: true,
          canAccessDatabase: true,
          initialInputs: VerticalInputs(),
          onInputsChanged: (_, __) {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rafter Measurements'), findsOneWidget);
    expect(find.text('Gutter Overhang'), findsOneWidget);
  });

  testWidgets('Add rafter button appears in section header trailing',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        SingleChildScrollView(
          child: VerticalCalculatorTab(
            user: proTestUser(),
            canUseMultipleRafters: true,
            canUseAdvancedOptions: true,
            canExport: true,
            canAccessDatabase: true,
            initialInputs: VerticalInputs(),
            onInputsChanged: (_, __) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final addButton = tester.getTopLeft(find.text('Add rafter'));
    final measurementField = tester.getTopLeft(find.text('e.g. 4000'));

    expect(addButton.dy, lessThan(measurementField.dy));
    expect(addButton.dx, greaterThan(measurementField.dx));
  });

  testWidgets('narrow layout stacks dry ridge and gutter overhang options',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(420, 900)),
          child: SingleChildScrollView(
            child: VerticalCalculatorTab(
              user: proTestUser(),
              canUseMultipleRafters: true,
              canUseAdvancedOptions: true,
              canExport: true,
              canAccessDatabase: true,
              initialInputs: VerticalInputs(),
              onInputsChanged: (_, __) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final dryRidge = tester.getTopLeft(find.text('Dry Ridge'));
    final gutter = tester.getTopLeft(find.text('Gutter Overhang'));

    expect(gutter.dy, greaterThan(dryRidge.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('free users see compact pro prompt on narrow layout', (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(420, 900)),
          child: VerticalCalculatorTab(
            user: freeTestUser(),
            canUseMultipleRafters: false,
            canUseAdvancedOptions: false,
            canExport: false,
            canAccessDatabase: false,
            initialInputs: VerticalInputs(),
            onInputsChanged: (_, __) {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pro: multiple rafters at once'), findsOneWidget);
    expect(find.text('Pro Feature'), findsNothing);
  });
}