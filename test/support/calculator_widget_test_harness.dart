import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/calculator/services/calculation_service.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';

/// Shared sample tile for calculator wizard widget tests.
TileModel sampleCalculatorTile() {
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

UserModel proTestUser() {
  return UserModel(
    id: 'user-1',
    email: 'pro@example.com',
    role: UserRole.pro,
    createdAt: DateTime(2026, 1, 1),
  );
}

UserModel freeTestUser() {
  return UserModel(
    id: 'user-2',
    email: 'free@example.com',
    role: UserRole.free,
    createdAt: DateTime(2026, 1, 1),
  );
}

Widget calculatorPlaceholderImage(TileSlateType type) => const Icon(Icons.image);

/// Notifier with empty state — for tab mount tests.
class EmptyCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState();
}

/// Notifier preloaded with [sampleCalculatorTile].
class TileCalculatorNotifier extends CalculatorNotifier {
  @override
  CalculatorState build() => CalculatorState(selectedTile: sampleCalculatorTile());
}

/// Riverpod container with Firebase/Hive isolated calculation service.
ProviderContainer createCalculatorTestContainer({
  CalculatorNotifier Function()? notifierFactory,
}) {
  return ProviderContainer(
    overrides: [
      calculationServiceProvider.overrideWithValue(CalculationService.forTesting()),
      calculatorProvider.overrideWith(
        notifierFactory ?? EmptyCalculatorNotifier.new,
      ),
    ],
  );
}

/// Wraps a calculator widget with standard test providers and MaterialApp.
Widget wrapCalculatorWidget(
  Widget child, {
  CalculatorNotifier Function()? notifierFactory,
}) {
  return ProviderScope(
    overrides: [
      calculationServiceProvider.overrideWithValue(CalculationService.forTesting()),
      calculatorProvider.overrideWith(
        notifierFactory ?? EmptyCalculatorNotifier.new,
      ),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}