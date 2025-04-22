import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';

// FutureProvider to handle HiveService initialization
final hiveServiceInitializerProvider = FutureProvider<void>((ref) async {
  await HiveService.init();
});

// Provider for HiveService
final hiveServiceProvider = Provider<HiveService>((ref) {
  final service = HiveService();
  // Ensure initialization is complete before returning the service
  ref.watch(hiveServiceInitializerProvider);
  return service;
});

class HiveService {
  static const String _appStateBoxName = 'appState';
  static const String _lastTileKey = 'lastSelectedTile';
  static Box? _appStateBox;
  static Box<UserModel>? _userBox;
  static Box<TileModel>? _tilesBox;
  static Box<SavedResult>? _resultsBox;
  static Box<Map>? _calculationsBox;
  static bool _isInitialized = false;
  static final Completer<void> _initializationCompleter = Completer<void>();

  HiveService();

  static Future<void> init() async {
    // Check if already initialized to prevent multiple completions
    if (_isInitialized) {
      return _initializationCompleter.future;
    }

    try {
      _appStateBox = await Hive.openBox(_appStateBoxName);
      _userBox = await Hive.openBox<UserModel>('userBox');
      _tilesBox = await Hive.openBox<TileModel>('tilesBox');
      _resultsBox = await Hive.openBox<SavedResult>('resultsBox');
      _calculationsBox = await Hive.openBox<Map>('calculationsBox');
      _isInitialized = true;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      print("HiveService initialized successfully");
    } catch (e) {
      print("Error initializing HiveService: $e");
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  bool get isInitialized => _isInitialized;

  Future<void> get initializationComplete => _initializationCompleter.future;

  Box<UserModel> get userBox {
    if (_userBox == null) {
      throw Exception(
          "HiveService userBox not initialized. Call init() first.");
    }
    return _userBox!;
  }

  Box<TileModel> get tilesBox {
    if (_tilesBox == null) {
      throw Exception(
          "HiveService tilesBox not initialized. Call init() first.");
    }
    return _tilesBox!;
  }

  Box<SavedResult> get resultsBox {
    if (_resultsBox == null) {
      throw Exception(
          "HiveService resultsBox not initialized. Call init() first.");
    }
    return _resultsBox!;
  }

  Box<Map> get calculationsBox {
    if (_calculationsBox == null) {
      throw Exception(
          "HiveService calculationsBox not initialized. Call init() first.");
    }
    return _calculationsBox!;
  }

  Future<void> saveLastSelectedTile(TileModel? tile) async {
    if (_appStateBox == null) {
      print("HiveService appStateBox not initialized, skipping save");
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
      print("HiveService appStateBox not initialized, returning null");
      return null;
    }
    final tileJson = _appStateBox!.get(_lastTileKey);
    if (tileJson != null) {
      try {
        return TileModel.fromJson(Map<String, dynamic>.from(tileJson));
      } catch (e) {
        print('Error loading last selected tile: $e');
        return null;
      }
    }
    return null;
  }
}
