import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';

// FutureProvider to handle HiveService initialization
final hiveServiceInitializerProvider = FutureProvider<void>((ref) async {
  await HiveService.init();
});

// Provider for HiveService
final hiveServiceProvider = Provider<HiveService>((ref) {
  final service = HiveService();
  ref.watch(hiveServiceInitializerProvider);
  return service;
});

class HiveService {
  static const String _appStateBoxName = 'appState';
  static const String _lastTileKey = 'lastSelectedTile';
  static const String _devProOverrideKey = 'devProOverride';
  static const String _devForceOfflineKey = 'devForceOffline';
  static Box? _appStateBox;
  static Box<UserModel>? _userBox;
  static Box<TileModel>? _tilesBox;
  static Box<SavedResult>? _resultsBox;
  static Box<Map>? _calculationsBox;
  static Box<Map>? _labourConfigBox;
  static Box<Map>? _labourQuotesBox;
  static Box<Map>? _labourMaterialsBox;
  static bool _isInitialized = false;
  static final Completer<void> _initializationCompleter = Completer<void>();

  HiveService();

  static Box? get appStateBox => _appStateBox;

  static Future<void> init() async {
    if (_isInitialized) {
      return _initializationCompleter.future;
    }

    try {
      _appStateBox = await Hive.openBox(_appStateBoxName);
      _isInitialized = true;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      unawaited(warmSecondaryBoxes());
    } catch (e) {
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// Opens non-critical Hive boxes in parallel after [appState] is ready.
  static Future<void> warmSecondaryBoxes() async {
    await Future.wait([
      ensureUserBox(),
      ensureTilesBox(),
      ensureResultsBox(),
      ensureCalculationsBox(),
      ensureLabourConfigBox(),
      ensureLabourQuotesBox(),
      ensureLabourMaterialsBox(),
    ]);
  }

  static Future<Box<UserModel>> ensureUserBox() async {
    if (_userBox != null) return _userBox!;
    if (Hive.isBoxOpen('userBox')) {
      _userBox = Hive.box<UserModel>('userBox');
      return _userBox!;
    }
    _userBox = await Hive.openBox<UserModel>('userBox');
    return _userBox!;
  }

  static Future<Box<TileModel>> ensureTilesBox() async {
    if (_tilesBox != null) return _tilesBox!;
    if (Hive.isBoxOpen('tilesBox')) {
      _tilesBox = Hive.box<TileModel>('tilesBox');
      return _tilesBox!;
    }
    _tilesBox = await Hive.openBox<TileModel>('tilesBox');
    return _tilesBox!;
  }

  static Future<Box<SavedResult>> ensureResultsBox() async {
    if (_resultsBox != null) return _resultsBox!;
    if (Hive.isBoxOpen('resultsBox')) {
      _resultsBox = Hive.box<SavedResult>('resultsBox');
      return _resultsBox!;
    }
    _resultsBox = await Hive.openBox<SavedResult>('resultsBox');
    return _resultsBox!;
  }

  static Future<Box<Map>> ensureCalculationsBox() async {
    if (_calculationsBox != null) return _calculationsBox!;
    if (Hive.isBoxOpen('calculationsBox')) {
      _calculationsBox = Hive.box<Map>('calculationsBox');
      return _calculationsBox!;
    }
    _calculationsBox = await Hive.openBox<Map>('calculationsBox');
    return _calculationsBox!;
  }

  static Future<Box<Map>> ensureLabourConfigBox() async {
    if (_labourConfigBox != null) return _labourConfigBox!;
    if (Hive.isBoxOpen('labourConfigBox')) {
      _labourConfigBox = Hive.box<Map>('labourConfigBox');
      return _labourConfigBox!;
    }
    _labourConfigBox = await Hive.openBox<Map>('labourConfigBox');
    return _labourConfigBox!;
  }

  static Future<Box<Map>> ensureLabourQuotesBox() async {
    if (_labourQuotesBox != null) return _labourQuotesBox!;
    if (Hive.isBoxOpen('labourQuotesBox')) {
      _labourQuotesBox = Hive.box<Map>('labourQuotesBox');
      return _labourQuotesBox!;
    }
    _labourQuotesBox = await Hive.openBox<Map>('labourQuotesBox');
    return _labourQuotesBox!;
  }

  static Future<Box<Map>> ensureLabourMaterialsBox() async {
    if (_labourMaterialsBox != null) return _labourMaterialsBox!;
    if (Hive.isBoxOpen('labourMaterialsBox')) {
      _labourMaterialsBox = Hive.box<Map>('labourMaterialsBox');
      return _labourMaterialsBox!;
    }
    _labourMaterialsBox = await Hive.openBox<Map>('labourMaterialsBox');
    return _labourMaterialsBox!;
  }

  bool get isInitialized => _isInitialized;

  Future<void> get initializationComplete => _initializationCompleter.future;

  Box<UserModel> get userBox {
    if (_userBox != null) return _userBox!;
    if (Hive.isBoxOpen('userBox')) {
      _userBox = Hive.box<UserModel>('userBox');
      return _userBox!;
    }
    throw Exception(
      'HiveService userBox not ready yet. Call ensureUserBox() first.',
    );
  }

  Box<TileModel> get tilesBox {
    if (_tilesBox != null) return _tilesBox!;
    if (Hive.isBoxOpen('tilesBox')) {
      _tilesBox = Hive.box<TileModel>('tilesBox');
      return _tilesBox!;
    }
    throw Exception(
      'HiveService tilesBox not ready yet. Call ensureTilesBox() first.',
    );
  }

  Box<SavedResult> get resultsBox {
    if (_resultsBox != null) return _resultsBox!;
    if (Hive.isBoxOpen('resultsBox')) {
      _resultsBox = Hive.box<SavedResult>('resultsBox');
      return _resultsBox!;
    }
    throw Exception(
      'HiveService resultsBox not ready yet. Call ensureResultsBox() first.',
    );
  }

  Box<Map> get calculationsBox {
    if (_calculationsBox != null) return _calculationsBox!;
    if (Hive.isBoxOpen('calculationsBox')) {
      _calculationsBox = Hive.box<Map>('calculationsBox');
      return _calculationsBox!;
    }
    throw Exception(
      'HiveService calculationsBox not ready yet. Call ensureCalculationsBox() first.',
    );
  }

  Box<Map> get labourConfigBox {
    if (_labourConfigBox != null) return _labourConfigBox!;
    if (Hive.isBoxOpen('labourConfigBox')) {
      _labourConfigBox = Hive.box<Map>('labourConfigBox');
      return _labourConfigBox!;
    }
    throw Exception(
      'HiveService labourConfigBox not ready yet. Call ensureLabourConfigBox() first.',
    );
  }

  Future<Box<Map>> labourQuotesBox() => ensureLabourQuotesBox();

  Future<Box<Map>> labourMaterialsBox() => ensureLabourMaterialsBox();

  Future<void> saveLastSelectedTile(TileModel? tile) async {
    if (_appStateBox == null) {
      return;
    }
    if (tile == null) {
      await _appStateBox!.delete(_lastTileKey);
    } else {
      await _appStateBox!.put(_lastTileKey, tile.toJson());
    }
  }

  TileModel? getLastSelectedTile() {
    if (_appStateBox == null) {
      return null;
    }
    final tileJson = _appStateBox!.get(_lastTileKey);
    if (tileJson != null) {
      try {
        return TileModel.fromJson(Map<String, dynamic>.from(tileJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  ProOverrideMode getDevProOverride() {
    if (_appStateBox == null || !_appStateBox!.isOpen) {
      return ProOverrideMode.actual;
    }
    final value = _appStateBox!.get(_devProOverrideKey) as String?;
    return ProOverrideMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ProOverrideMode.actual,
    );
  }

  Future<void> saveDevProOverride(ProOverrideMode mode) async {
    if (_appStateBox == null) return;
    await _appStateBox!.put(_devProOverrideKey, mode.name);
  }

  bool getDevForceOffline() {
    if (_appStateBox == null || !_appStateBox!.isOpen) return false;
    return _appStateBox!.get(_devForceOfflineKey, defaultValue: false) as bool;
  }

  Future<void> saveDevForceOffline(bool enabled) async {
    if (_appStateBox == null) return;
    await _appStateBox!.put(_devForceOfflineKey, enabled);
  }

  Future<void> clearLocalDevData() async {
    await ensureTilesBox();
    await ensureResultsBox();
    await tilesBox.clear();
    await resultsBox.clear();
    await calculationsBox.clear();
    if (_appStateBox != null) {
      await _appStateBox!.delete(_lastTileKey);
    }
  }

  Future<int> seedUkTilesLocal(List<TileModel> tiles) async {
    await ensureTilesBox();
    for (final tile in tiles) {
      await tilesBox.put(tile.id, tile);
    }
    return tiles.length;
  }
}