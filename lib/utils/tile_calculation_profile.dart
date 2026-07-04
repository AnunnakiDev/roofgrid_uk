import 'package:roofgrid_uk/models/tile_model.dart';

/// UK site practice bounds for ridge batten offset (mm).
const int kRidgeOffsetMinMm = 25;
const int kRidgeOffsetWetMaxMm = 50;
const int kRidgeOffsetDryMaxMm = 65;

/// @deprecated Use [ridgeOffsetMaxMm] — dry-ridge maximum only.
const int kRidgeOffsetMaxMm = kRidgeOffsetDryMaxMm;

const int kSlateFirstBattenOffsetMm = 25;
const int kPlainFirstBattenOffsetMm = 15;
const int kPlainEaveToFirstGaugeMm = 50;
const int kProfileEaveOffsetMm = 25;

/// Fibre cement under-eave batten sits 100 mm below the eave batten.
const int kFibreCementUnderEaveBelowEaveMm = 100;

/// Eave and first gauge batten positions (mm from fascia top).
class VerticalBattenDatum {
  final int eaveBattenMm;
  final int firstGaugeBattenMm;

  /// Under-eave batten position from fascia top (fibre cement only).
  final int? underEaveBattenPositionMm;

  const VerticalBattenDatum({
    required this.eaveBattenMm,
    required this.firstGaugeBattenMm,
    this.underEaveBattenPositionMm,
  });

  int get gaugeZoneBottomMm => firstGaugeBattenMm;

  int get eaveToFirstGaugeGapMm => firstGaugeBattenMm - eaveBattenMm;
}

/// Installation constants per tile family (BS 5534 / site practice).
class TileCalculationProfile {
  final int? horizontalSetSize;

  const TileCalculationProfile({
    this.horizontalSetSize,
  });

  int gaugeBattenStartMm({
    required int eaveBatten,
    int? underEaveBatten,
    int? firstGaugeBatten,
  }) {
    if (firstGaugeBatten != null) {
      return firstGaugeBatten;
    }
    if (underEaveBatten != null) {
      return eaveBatten + underEaveBatten;
    }
    return eaveBatten;
  }
}

TileCalculationProfile profileForMaterialType(String? materialType) {
  return profileForTileType(parseTileSlateTypeFromString(materialType));
}

TileCalculationProfile profileForTileType(TileSlateType type) {
  switch (type) {
    case TileSlateType.plainTile:
    case TileSlateType.slate:
      return const TileCalculationProfile(horizontalSetSize: 3);
    case TileSlateType.fibreCementSlate:
      return const TileCalculationProfile(horizontalSetSize: 2);
    case TileSlateType.interlockingTile:
    case TileSlateType.concreteTile:
    case TileSlateType.pantile:
      return const TileCalculationProfile(horizontalSetSize: 2);
    case TileSlateType.unknown:
      return const TileCalculationProfile();
  }
}

TileSlateType parseTileSlateTypeFromString(String? materialType) {
  switch (materialType?.trim()) {
    case 'Slate':
      return TileSlateType.slate;
    case 'Fibre Cement Slate':
      return TileSlateType.fibreCementSlate;
    case 'Interlocking Tile':
      return TileSlateType.interlockingTile;
    case 'Plain Tile':
      return TileSlateType.plainTile;
    case 'Concrete Tile':
      return TileSlateType.concreteTile;
    case 'Pantile':
      return TileSlateType.pantile;
    default:
      return TileSlateType.unknown;
  }
}

VerticalBattenDatum resolveVerticalBattenDatum({
  required String? materialType,
  required double tileHeight,
  required double gutterOverhang,
  required double maxGauge,
}) {
  final type = parseTileSlateTypeFromString(materialType);
  final gutter = gutterOverhang.round();
  final height = tileHeight.round();
  final maxG = maxGauge.round();

  switch (type) {
    case TileSlateType.slate:
      final first = height - gutter + kSlateFirstBattenOffsetMm;
      return VerticalBattenDatum(
        eaveBattenMm: first - maxG,
        firstGaugeBattenMm: first,
      );
    case TileSlateType.fibreCementSlate:
      final first = height - gutter + kSlateFirstBattenOffsetMm;
      final eave = first - maxG;
      return VerticalBattenDatum(
        eaveBattenMm: eave,
        firstGaugeBattenMm: first,
        underEaveBattenPositionMm: eave - kFibreCementUnderEaveBelowEaveMm,
      );
    case TileSlateType.plainTile:
      final first = height - gutter - kPlainFirstBattenOffsetMm;
      return VerticalBattenDatum(
        eaveBattenMm: first - kPlainEaveToFirstGaugeMm,
        firstGaugeBattenMm: first,
      );
    case TileSlateType.interlockingTile:
    case TileSlateType.concreteTile:
    case TileSlateType.pantile:
      final eave = height - gutter - kProfileEaveOffsetMm;
      return VerticalBattenDatum(
        eaveBattenMm: eave,
        firstGaugeBattenMm: eave,
      );
    case TileSlateType.unknown:
      final first = height - gutter + kSlateFirstBattenOffsetMm;
      return VerticalBattenDatum(
        eaveBattenMm: first - maxG,
        firstGaugeBattenMm: first,
      );
  }
}

int resolveEaveBattenMm({
  required String? materialType,
  required double tileHeight,
  required double gutterOverhang,
  required double maxGauge,
}) {
  return resolveVerticalBattenDatum(
    materialType: materialType,
    tileHeight: tileHeight,
    gutterOverhang: gutterOverhang,
    maxGauge: maxGauge,
  ).eaveBattenMm;
}

int resolveFirstGaugeBattenMm({
  required String? materialType,
  required double tileHeight,
  required double gutterOverhang,
  required double maxGauge,
}) {
  return resolveVerticalBattenDatum(
    materialType: materialType,
    tileHeight: tileHeight,
    gutterOverhang: gutterOverhang,
    maxGauge: maxGauge,
  ).firstGaugeBattenMm;
}

int ridgeOffsetMaxMm(String useDryRidge) {
  return useDryRidge == 'YES' ? kRidgeOffsetDryMaxMm : kRidgeOffsetWetMaxMm;
}

int baseRidgeOffsetMm(String useDryRidge) {
  return useDryRidge == 'YES' ? kRidgeOffsetDryMaxMm : kRidgeOffsetMinMm;
}

bool isRidgeOffsetInBounds(int ridgeOffsetMm, String useDryRidge) {
  return ridgeOffsetMm >= kRidgeOffsetMinMm &&
      ridgeOffsetMm <= ridgeOffsetMaxMm(useDryRidge);
}

int resolveHorizontalSetSize({
  required String? materialType,
  required double tileCoverWidth,
}) {
  final profile = profileForMaterialType(materialType);
  if (profile.horizontalSetSize != null) {
    return profile.horizontalSetSize!;
  }
  return tileCoverWidth > 300 ? 2 : 3;
}

bool showsUnderEaveBattenForMaterial(String? materialType) {
  if (materialType == null || materialType.isEmpty) return false;
  return parseTileSlateTypeFromString(materialType) ==
      TileSlateType.fibreCementSlate;
}

bool showsUnderEaveBattenForProfile(TileCalculationProfile profile) {
  return false;
}