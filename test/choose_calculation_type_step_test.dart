import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/screens/calculator/choose_calculation_type_step.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/calculator_launch_cards.dart';

import 'support/calculator_widget_test_harness.dart';

void main() {
  testWidgets('ChooseCalculationTypeStep fits 420px phone viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      wrapCalculatorWidget(
        ChooseCalculationTypeStep(
          user: proTestUser(),
          effectiveIsPro: true,
          onTypeSelected: (_) {},
          onBack: () {},
          placeholderImageBuilder: calculatorPlaceholderImage,
        ),
        notifierFactory: TileCalculatorNotifier.new,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CalculatorStepProgress), findsOneWidget);
    expect(find.text('Choose set-out type'), findsOneWidget);
    expect(find.byType(CalculatorLaunchCards), findsOneWidget);
    expect(find.text('Test Pantile'), findsOneWidget);
    expect(find.text('Back to tile'), findsOneWidget);
  });
}