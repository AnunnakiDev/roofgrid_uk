import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/tile_access.dart';

UserModel _user({
  required UserRole role,
  bool trialActive = false,
}) {
  final now = DateTime.now();
  return UserModel(
    id: 'user-1',
    email: 'user@example.com',
    role: role,
    createdAt: now,
    proTrialStartDate: trialActive ? now.subtract(const Duration(days: 1)) : null,
    proTrialEndDate: trialActive ? now.add(const Duration(days: 10)) : null,
  );
}

TileModel _tile({
  required String id,
  required String createdById,
  bool isPublic = false,
  bool isApproved = false,
}) {
  final now = DateTime.now();
  return TileModel(
    id: id,
    name: 'Tile $id',
    manufacturer: 'Generic',
    materialType: TileSlateType.slate,
    description: 'Test tile',
    isPublic: isPublic,
    isApproved: isApproved,
    createdById: createdById,
    createdAt: now,
    updatedAt: now,
    slateTileHeight: 500,
    tileCoverWidth: 250,
    minGauge: 195,
    maxGauge: 210,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: false,
  );
}

void main() {
  group('resolveEffectiveIsPro', () {
    test('admin without subscription is always pro unless dev forces free', () {
      final admin = _user(role: UserRole.admin);
      const devMode = DeveloperModeState(proOverride: ProOverrideMode.actual);
      expect(resolveEffectiveIsPro(admin, devMode), isTrue);
    });

    test('admin can force free locally for testing', () {
      final admin = _user(role: UserRole.admin);
      const devMode = DeveloperModeState(proOverride: ProOverrideMode.free);
      expect(resolveEffectiveIsPro(admin, devMode), isFalse);
    });
  });

  group('tile access helpers', () {
    const devMode = DeveloperModeState();

    test('free user cannot browse tile database', () {
      final user = _user(role: UserRole.free);
      expect(canBrowseTileDatabase(user, devMode), isFalse);
      expect(canSavePersonalTiles(user, devMode), isFalse);
      expect(canUseManualTileInput(user), isTrue);
    });

    test('pro trial user can browse and save personal tiles', () {
      final user = _user(role: UserRole.pro, trialActive: true);
      expect(canBrowseTileDatabase(user, devMode), isTrue);
      expect(canSavePersonalTiles(user, devMode), isTrue);
      expect(canManageDefaultTiles(user), isFalse);
    });

    test('admin can manage default tiles', () {
      final admin = _user(role: UserRole.admin);
      expect(canManageDefaultTiles(admin), isTrue);
      expect(canBrowseTileDatabase(admin, devMode), isTrue);
    });

    test('pro can edit personal tile but not default catalogue tile', () {
      final user = _user(role: UserRole.pro, trialActive: true);
      final personal = _tile(id: 'p1', createdById: user.id);
      final defaultTile = _tile(
        id: 'd1',
        createdById: 'admin',
        isPublic: true,
        isApproved: true,
      );

      expect(
        canEditTileInList(
          tile: personal,
          user: user,
          effectiveIsPro: true,
        ),
        isTrue,
      );
      expect(
        canEditTileInList(
          tile: defaultTile,
          user: user,
          effectiveIsPro: true,
        ),
        isFalse,
      );
    });

    test('partitions default and personal tiles', () {
      final userId = 'user-1';
      final tiles = [
        _tile(id: 'd1', createdById: 'admin', isPublic: true, isApproved: true),
        _tile(id: 'p1', createdById: userId),
        _tile(id: 'p2', createdById: userId),
      ];

      expect(partitionDefaultTiles(tiles).map((t) => t.id), ['d1']);
      expect(partitionPersonalTiles(tiles, userId).map((t) => t.id), ['p1', 'p2']);
    });
  });
}