import 'package:roofgrid_uk/models/tile_model.dart';

/// Cross bonded setting derived from tile catalogue data.
String crossBondedFromTile(TileModel tile) {
  return tile.defaultCrossBonded ? 'YES' : 'NO';
}

/// Prefers a saved cross-bonded snapshot, falling back to tile spec.
String resolveCrossBonded({String? saved, required TileModel tile}) {
  if (saved == 'YES' || saved == 'NO') {
    return saved!;
  }
  return crossBondedFromTile(tile);
}

/// Read-only label for calculator context (not an editable input).
String crossBondedDisplayLabel(TileModel? tile) {
  if (tile == null) {
    return 'Select a tile';
  }
  return tile.defaultCrossBonded ? 'Yes (from tile spec)' : 'No (from tile spec)';
}

/// LH tile is disabled when any abutment is set (calc forces it off).
bool isLeftHandTileEnabled(String abutmentSide) {
  return abutmentSide == 'NONE';
}