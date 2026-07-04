import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/screens/calculator/enter_measurements_step.dart';

TileModel _sampleTile() {
  final now = DateTime(2026, 1, 1);
  return TileModel(
    id: 'tile-1',
    name: 'Test Pantile',
    manufacturer: 'Test Co',
    materialType: TileSlateType.pantile,
    description: 'Test',
    isPublic: true,
    isApproved: true,
    createdById: 'admin',
    createdAt: now,
    updatedAt: now,
    slateTileHeight: 300,
    tileCoverWidth: 250,
    minGauge: 100,
    maxGauge: 120,
    minSpacing: 5,
    maxSpacing: 10,
    defaultCrossBonded: false,
  );
}

class _TileCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState(selectedTile: _sampleTile());
}

UserModel _proUser() {
  return UserModel(
    id: 'user-1',
    email: 'pro@example.com',
    role: UserRole.pro,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget _placeholder(TileSlateType type) => const Icon(Icons.image);

void main() {
  testWidgets('EnterMeasurementsStep verticalOnly renders measurement inputs',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TileCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EnterMeasurementsStep(
              user: _proUser(),
              effectiveIsPro: true,
              calculationType: CalculationTypeSelection.verticalOnly,
              initialVerticalInputs: VerticalInputs(),
              initialHorizontalInputs: HorizontalInputs(),
              onBackToTileSelect: () {},
              onCalculate: (_, __) {},
              placeholderImageBuilder: _placeholder,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Measurements'), findsOneWidget);
    expect(find.text('Vertical set-out'), findsOneWidget);
    expect(find.text('Rafter measurements'), findsOneWidget);
    expect(find.text('Selected Tile'), findsOneWidget);
    expect(find.text('Dry Ridge'), findsOneWidget);
    expect(find.text('Gutter Overhang'), findsOneWidget);
    expect(find.text('Dry Verge'), findsNothing);
    expect(find.text('Abutment Side'), findsNothing);
    expect(find.text('Width Measurements'), findsNothing);
  });

  testWidgets('EnterMeasurementsStep horizontalOnly renders width inputs',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TileCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EnterMeasurementsStep(
              user: _proUser(),
              effectiveIsPro: true,
              calculationType: CalculationTypeSelection.horizontalOnly,
              initialVerticalInputs: VerticalInputs(),
              initialHorizontalInputs: HorizontalInputs(),
              onBackToTileSelect: () {},
              onCalculate: (_, __) {},
              placeholderImageBuilder: _placeholder,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Width measurements'), findsOneWidget);
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
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TileCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EnterMeasurementsStep(
              user: _proUser(),
              effectiveIsPro: true,
              calculationType: CalculationTypeSelection.both,
              initialVerticalInputs: VerticalInputs(),
              initialHorizontalInputs: HorizontalInputs(),
              onBackToTileSelect: () {},
              onCalculate: (_, __) {},
              placeholderImageBuilder: _placeholder,
            ),
          ),
        ),
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

  testWidgets('EnterMeasurementsStep rebuilds when calculation type changes',
      (tester) async {
    CalculationTypeSelection type = CalculationTypeSelection.both;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TileCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return EnterMeasurementsStep(
                  key: ValueKey(type),
                  user: _proUser(),
                  effectiveIsPro: true,
                  calculationType: type,
                  initialVerticalInputs: VerticalInputs(),
                  initialHorizontalInputs: HorizontalInputs(),
                  onBackToTileSelect: () {},
                  onCalculate: (_, __) {},
                  placeholderImageBuilder: _placeholder,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Vertical measurements'), findsOneWidget);
    expect(find.text('Horizontal measurements'), findsOneWidget);

    type = CalculationTypeSelection.verticalOnly;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TileCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: EnterMeasurementsStep(
              key: ValueKey(type),
              user: _proUser(),
              effectiveIsPro: true,
              calculationType: type,
              initialVerticalInputs: VerticalInputs(),
              initialHorizontalInputs: HorizontalInputs(),
              onBackToTileSelect: () {},
              onCalculate: (_, __) {},
              placeholderImageBuilder: _placeholder,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Rafter measurements'), findsOneWidget);
    expect(find.text('Horizontal measurements'), findsNothing);
    expect(find.text('Width Measurements'), findsNothing);
    expect(find.text('Dry Verge'), findsNothing);
  });
}