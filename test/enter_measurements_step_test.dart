import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/screens/calculator/enter_measurements_step.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';

import 'support/calculator_widget_test_harness.dart';

void main() {
  testWidgets('EnterMeasurementsStep verticalOnly renders measurement inputs',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        EnterMeasurementsStep(
          user: proTestUser(),
          effectiveIsPro: true,
          calculationType: CalculationTypeSelection.verticalOnly,
          initialVerticalInputs: VerticalInputs(),
          initialHorizontalInputs: HorizontalInputs(),
          onBackToTileSelect: () {},
          onCalculate: (_, __) {},
          placeholderImageBuilder: calculatorPlaceholderImage,
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Measurements'), findsOneWidget);
    expect(find.text('Vertical set-out'), findsOneWidget);
    expect(find.text('Rafter Measurements'), findsOneWidget);
    expect(find.text('Test Pantile'), findsOneWidget);
    expect(find.text('Selected Tile'), findsNothing);
    expect(find.text('Dry Ridge'), findsOneWidget);
    expect(find.text('Gutter Overhang'), findsOneWidget);
    expect(find.text('Dry Verge'), findsNothing);
    expect(find.text('Abutment Side'), findsNothing);
    expect(find.text('Width Measurements'), findsNothing);
  });

  testWidgets('EnterMeasurementsStep horizontalOnly renders width inputs',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        EnterMeasurementsStep(
          user: proTestUser(),
          effectiveIsPro: true,
          calculationType: CalculationTypeSelection.horizontalOnly,
          initialVerticalInputs: VerticalInputs(),
          initialHorizontalInputs: HorizontalInputs(),
          onBackToTileSelect: () {},
          onCalculate: (_, __) {},
          placeholderImageBuilder: calculatorPlaceholderImage,
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Width Measurements'), findsOneWidget);
    expect(find.text('Dry Verge'), findsOneWidget);
    expect(find.text('Abutment Side'), findsOneWidget);
    expect(find.text('Dry Ridge'), findsNothing);
    expect(find.text('Gutter Overhang'), findsNothing);
    expect(find.text('Rafter Measurements'), findsNothing);
  });

  testWidgets('EnterMeasurementsStep combined shows vertical and horizontal options together',
      (tester) async {
    await tester.pumpWidget(
      wrapCalculatorWidget(
        EnterMeasurementsStep(
          user: proTestUser(),
          effectiveIsPro: true,
          calculationType: CalculationTypeSelection.both,
          initialVerticalInputs: VerticalInputs(),
          initialHorizontalInputs: HorizontalInputs(),
          onBackToTileSelect: () {},
          onCalculate: (_, __) {},
          placeholderImageBuilder: calculatorPlaceholderImage,
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vertical measurements'), findsOneWidget);
    expect(find.text('Horizontal measurements'), findsOneWidget);
    expect(find.text('Rafter Measurements'), findsOneWidget);
    expect(find.text('Width Measurements'), findsOneWidget);
    expect(find.text('Dry Verge'), findsOneWidget);
    expect(find.text('Abutment Side'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('EnterMeasurementsStep combined mode uses section headings only',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 912));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCalculatorWidget(
        EnterMeasurementsStep(
          user: proTestUser(),
          effectiveIsPro: true,
          calculationType: CalculationTypeSelection.both,
          initialVerticalInputs: VerticalInputs(),
          initialHorizontalInputs: HorizontalInputs(),
          onBackToTileSelect: () {},
          onCalculate: (_, __) {},
          placeholderImageBuilder: calculatorPlaceholderImage,
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vertical measurements'), findsOneWidget);
    expect(find.text('Horizontal measurements'), findsOneWidget);
    expect(find.byType(CalculatorStepProgress), findsOneWidget);
  });

  testWidgets('EnterMeasurementsStep rebuilds when calculation type changes',
      (tester) async {
    CalculationTypeSelection type = CalculationTypeSelection.both;

    await tester.pumpWidget(
      wrapCalculatorWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return EnterMeasurementsStep(
              key: ValueKey(type),
              user: proTestUser(),
              effectiveIsPro: true,
              calculationType: type,
              initialVerticalInputs: VerticalInputs(),
              initialHorizontalInputs: HorizontalInputs(),
              onBackToTileSelect: () {},
              onCalculate: (_, __) {},
              placeholderImageBuilder: calculatorPlaceholderImage,
            );
          },
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vertical measurements'), findsOneWidget);
    expect(find.text('Horizontal measurements'), findsOneWidget);

    type = CalculationTypeSelection.verticalOnly;
    await tester.pumpWidget(
      wrapCalculatorWidget(
        EnterMeasurementsStep(
          key: ValueKey(type),
          user: proTestUser(),
          effectiveIsPro: true,
          calculationType: type,
          initialVerticalInputs: VerticalInputs(),
          initialHorizontalInputs: HorizontalInputs(),
          onBackToTileSelect: () {},
          onCalculate: (_, __) {},
          placeholderImageBuilder: calculatorPlaceholderImage,
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rafter Measurements'), findsOneWidget);
    expect(find.text('Horizontal measurements'), findsNothing);
    expect(find.text('Width Measurements'), findsNothing);
    expect(find.text('Dry Verge'), findsNothing);
  });

  testWidgets('EnterMeasurementsStep shows compact context bar when keyboard open',
      (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      wrapCalculatorWidget(
        SizedBox(
          height: 640,
          child: EnterMeasurementsStep(
            user: proTestUser(),
            effectiveIsPro: true,
            calculationType: CalculationTypeSelection.verticalOnly,
            initialVerticalInputs: VerticalInputs(),
            initialHorizontalInputs: HorizontalInputs(),
            onBackToTileSelect: () {},
            onCalculate: (_, __) {},
            placeholderImageBuilder: calculatorPlaceholderImage,
          ),
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Pantile'), findsOneWidget);
    expect(find.text('Vertical set-out'), findsOneWidget);
    expect(find.text('Selected Tile'), findsNothing);
    expect(find.byType(CalculatorStepProgress), findsNothing);
  });
}