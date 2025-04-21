import 'package:hive_flutter/hive_flutter.dart';
import 'package:roofgrid_uk/models/tile_model.dart';

class HiveService {
  static const String _appStateBoxName = 'appState';
  static const String _lastTileKey = 'lastSelectedTile';
  static late Box _appStateBox;

  static Future<void> init() async {
    _appStateBox = await Hive.openBox(_appStateBoxName);
  }

  Future<void> saveLastSelectedTile(TileModel? tile) async {
    if (tile == null) {
      await _appStateBox.delete(_lastTileKey);
    } else {
      await _appStateBox.put(_lastTileKey, tile.toJson());
    }
  }

  TileModel? getLastSelectedTile() {
    final tileJson = _appStateBox.get(_lastTileKey);
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
