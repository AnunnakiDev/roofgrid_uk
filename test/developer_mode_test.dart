import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/uk_tile_seeder.dart';

UserModel _adminUser({required bool isPro}) {
  final now = DateTime.now();
  return UserModel(
    id: 'admin-1',
    email: 'hgwarner1307@gmail.com',
    role: UserRole.admin,
    createdAt: now,
    proTrialEndDate: isPro ? now.add(const Duration(days: 5)) : now.subtract(const Duration(days: 1)),
    proTrialStartDate: now.subtract(const Duration(days: 20)),
  );
}

void main() {
  group('resolveEffectiveIsPro', () {
    test('admin with actual override always has pro access', () {
      final user = _adminUser(isPro: false);
      const devMode = DeveloperModeState(proOverride: ProOverrideMode.actual);
      expect(resolveEffectiveIsPro(user, devMode), isTrue);
    });

    test('admin with pro override still has pro access', () {
      final user = _adminUser(isPro: false);
      const devMode = DeveloperModeState(proOverride: ProOverrideMode.pro);
      expect(resolveEffectiveIsPro(user, devMode), isTrue);
    });

    test('admin can force free locally', () {
      final user = _adminUser(isPro: true);
      const devMode = DeveloperModeState(proOverride: ProOverrideMode.free);
      expect(resolveEffectiveIsPro(user, devMode), isFalse);
    });

    test('non-admin ignores dev override', () {
      final user = UserModel(
        id: 'free-1',
        role: UserRole.free,
        createdAt: DateTime.now(),
      );
      const devMode = DeveloperModeState(proOverride: ProOverrideMode.pro);
      expect(resolveEffectiveIsPro(user, devMode), isFalse);
    });
  });

  group('force offline override', () {
    tearDown(() {
      setForceOfflineOverride(false);
    });

    test('isOnlineFromResults returns false when forced offline', () {
      setForceOfflineOverride(true);
      expect(isOnlineFromResults([ConnectivityResult.wifi]), isFalse);
    });

    test('isDeviceOnline returns false when forced offline', () async {
      setForceOfflineOverride(true);
      expect(await isDeviceOnline(), isFalse);
    });
  });

  group('uk tile seeder', () {
    test('builds standard UK tile profiles', () {
      final tiles = buildUkSeedTiles('user-1');
      expect(tiles.length, greaterThanOrEqualTo(4));
      expect(tiles.map((t) => t.name), contains('Natural Slate'));
      expect(tiles.map((t) => t.name), contains('Clay Plain Tile'));
    });
  });
}