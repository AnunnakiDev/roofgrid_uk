import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';

bool showsUnderEaveBattenForTileType(TileSlateType materialType) {
  return showsUnderEaveBattenForMaterial(_materialTypeString(materialType));
}

String? materialTypeFromTileJson(Map<String, dynamic>? tile) {
  if (tile == null) return null;
  return tile['TileSlateType'] as String? ?? tile['materialType'] as String?;
}

bool shouldShowEaveBatten(VerticalCalculationResult result) {
  return result.eaveBatten != null;
}

/// True when eave and first gauge are different positions (plain, slate, FC).
bool shouldShowDistinctFirstGaugeBatten(VerticalCalculationResult result) {
  final eave = result.eaveBatten;
  if (eave == null) return false;
  return eave != result.firstBatten;
}

bool shouldShowUnderEaveBatten({
  required String? materialType,
  required VerticalCalculationResult result,
}) {
  return showsUnderEaveBattenForMaterial(materialType) &&
      result.underEaveBatten != null;
}

/// First gauge batten position (mm from fascia top).
int gaugeBattenStartMm(
  VerticalCalculationResult result, {
  String? materialType,
}) {
  return result.firstBatten;
}

String _materialTypeString(TileSlateType materialType) {
  switch (materialType) {
    case TileSlateType.slate:
      return 'Slate';
    case TileSlateType.fibreCementSlate:
      return 'Fibre Cement Slate';
    case TileSlateType.interlockingTile:
      return 'Interlocking Tile';
    case TileSlateType.plainTile:
      return 'Plain Tile';
    case TileSlateType.concreteTile:
      return 'Concrete Tile';
    case TileSlateType.pantile:
      return 'Pantile';
    case TileSlateType.unknown:
      return 'Unknown';
  }
}