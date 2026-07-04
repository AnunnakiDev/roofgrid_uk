import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/widgets/tile_selector_widget.dart';

class _TestDeveloperModeNotifier extends DeveloperModeNotifier {
  @override
  DeveloperModeState build() => const DeveloperModeState();
}

TileModel _sampleTile() {
  final now = DateTime(2026, 1, 1);
  return TileModel(
    id: 'tile-1',
    name: 'Test Tile',
    manufacturer: 'Test Co',
    materialType: TileSlateType.plainTile,
    description: 'Test description',
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

UserModel _proUser({bool trialActive = true}) {
  final now = DateTime(2026, 1, 1);
  return UserModel(
    id: 'user-1',
    email: 'pro@example.com',
    role: UserRole.pro,
    createdAt: now,
    proTrialStartDate: trialActive ? now : null,
    proTrialEndDate: trialActive ? now.add(const Duration(days: 14)) : null,
  );
}

void main() {
  testWidgets('TileSelectorWidget embedded in scroll view lays out without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => Stream.value(_proUser()),
          ),
          developerModeProvider.overrideWith(_TestDeveloperModeNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TileSelectorWidget(
                tiles: [_sampleTile()],
                user: _proUser(),
                embeddedInScrollView: true,
                showAddTileButton: false,
                onTileSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Tile'), findsOneWidget);
  });
}