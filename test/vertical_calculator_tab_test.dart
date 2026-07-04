import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/screens/calculator/vertical_calculator_tab.dart';

class _TestCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState();
}

UserModel _proUser() {
  return UserModel(
    id: 'user-1',
    email: 'pro@example.com',
    role: UserRole.pro,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  testWidgets('VerticalCalculatorTab mounts without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: VerticalCalculatorTab(
              user: _proUser(),
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

    expect(find.text('Rafter Measurements'), findsOneWidget);
    expect(find.text('Gutter Overhang'), findsOneWidget);
  });

  testWidgets('Add rafter button appears below measurement inputs',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VerticalCalculatorTab(
                user: _proUser(),
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
      ),
    );

    await tester.pumpAndSettle();

    final addButton = tester.getTopLeft(find.text('Add rafter'));
    final measurementField = tester.getTopLeft(find.text('e.g. 4000'));

    expect(addButton.dy, greaterThan(measurementField.dy));
  });
}