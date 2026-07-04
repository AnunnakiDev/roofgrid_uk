import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/screens/calculator/choose_calculation_type_step.dart';
import 'package:roofgrid_uk/widgets/calculator/calculator_step_progress.dart';
import 'package:roofgrid_uk/widgets/calculator_launch_cards.dart';

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
  testWidgets('ChooseCalculationTypeStep fits 420px phone viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorProvider.overrideWith(_TileCalculatorNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ChooseCalculationTypeStep(
              user: _proUser(),
              effectiveIsPro: true,
              onTypeSelected: (_) {},
              onBack: () {},
              placeholderImageBuilder: _placeholder,
            ),
          ),
        ),
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