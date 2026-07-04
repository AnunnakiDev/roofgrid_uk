import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/screens/calculator/horizontal_calculator_tab.dart';

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
  testWidgets('HorizontalCalculatorTab mounts without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: HorizontalCalculatorTab(
              user: _proUser(),
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

    expect(find.text('Width Measurements'), findsOneWidget);
    expect(find.text('Abutment Side'), findsOneWidget);
  });

  testWidgets('Add width button appears in section header trailing',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HorizontalCalculatorTab(
                user: _proUser(),
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
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TestCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(420, 900)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: HorizontalCalculatorTab(
                  user: _proUser(),
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