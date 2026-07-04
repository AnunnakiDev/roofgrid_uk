import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/uk_tile_seeder.dart';

class DeveloperModeState {
  final ProOverrideMode proOverride;
  final bool forceOffline;

  const DeveloperModeState({
    this.proOverride = ProOverrideMode.actual,
    this.forceOffline = false,
  });

  DeveloperModeState copyWith({
    ProOverrideMode? proOverride,
    bool? forceOffline,
  }) {
    return DeveloperModeState(
      proOverride: proOverride ?? this.proOverride,
      forceOffline: forceOffline ?? this.forceOffline,
    );
  }
}

/// Resolves effective Pro status with optional admin dev override.
bool resolveEffectiveIsPro(UserModel? user, DeveloperModeState devMode) {
  if (user == null) return false;
  if (user.isAdmin) {
    if (devMode.proOverride == ProOverrideMode.free) return false;
    return true;
  }
  return user.isPro;
}

final developerModeProvider =
    NotifierProvider<DeveloperModeNotifier, DeveloperModeState>(
  DeveloperModeNotifier.new,
);

final effectiveIsProProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  final devMode = ref.watch(developerModeProvider);
  return resolveEffectiveIsPro(user, devMode);
});

class DeveloperModeNotifier extends Notifier<DeveloperModeState> {
  @override
  DeveloperModeState build() {
    final hive = ref.watch(hiveServiceProvider);
    final loaded = _loadFromHive(hive);
    _syncConnectivityOverride(loaded.forceOffline);
    return loaded;
  }

  DeveloperModeState _loadFromHive(HiveService hive) {
    return DeveloperModeState(
      proOverride: hive.getDevProOverride(),
      forceOffline: hive.getDevForceOffline(),
    );
  }

  void _syncConnectivityOverride(bool forceOffline) {
    setForceOfflineOverride(forceOffline);
  }

  Future<void> setProOverride(ProOverrideMode mode) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.saveDevProOverride(mode);
    state = state.copyWith(proOverride: mode);
  }

  Future<void> setForceOffline(bool enabled) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.saveDevForceOffline(enabled);
    setForceOfflineOverride(enabled);
    state = state.copyWith(forceOffline: enabled);
  }

  Future<void> resetLocalData() async {
    final hive = ref.read(hiveServiceProvider);
    await hive.clearLocalDevData();
    final userId = ref.read(currentUserProvider).value?.id;
    if (userId != null) {
      ref.invalidate(userTilesProvider(userId));
      ref.invalidate(allAvailableTilesProvider(userId));
    }
  }

  Future<int> seedUkTiles() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return 0;
    final hive = ref.read(hiveServiceProvider);
    final tiles = buildUkSeedTiles(user.id);
    final count = await hive.seedUkTilesLocal(tiles);
    ref.invalidate(userTilesProvider(user.id));
    ref.invalidate(allAvailableTilesProvider(user.id));
    return count;
  }
}