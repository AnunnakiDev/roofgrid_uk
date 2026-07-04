import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart';

void main() {
  group('tile_calculation_profile', () {
    test('plain and slate use sets of 3', () {
      final plain = profileForTileType(TileSlateType.plainTile);
      expect(plain.horizontalSetSize, 3);

      final slate = profileForMaterialType('Slate');
      expect(slate.horizontalSetSize, 3);
    });

    test('fibre cement uses under-eave position and sets of 2', () {
      final profile = profileForMaterialType('Fibre Cement Slate');
      expect(profile.horizontalSetSize, 2);

      final datum = resolveVerticalBattenDatum(
        materialType: 'Fibre Cement Slate',
        tileHeight: 600,
        gutterOverhang: 50,
        maxGauge: 255,
      );
      expect(datum.firstGaugeBattenMm, 575);
      expect(datum.eaveBattenMm, 320);
      expect(datum.underEaveBattenPositionMm, 220);
    });

    test('plain tile resolves eave and first gauge battens', () {
      final datum = resolveVerticalBattenDatum(
        materialType: 'Plain Tile',
        tileHeight: 265,
        gutterOverhang: 50,
        maxGauge: 115,
      );
      expect(datum.firstGaugeBattenMm, 200);
      expect(datum.eaveBattenMm, 150);
      expect(datum.underEaveBattenPositionMm, isNull);
    });

    test('profile tiles omit under-eave', () {
      final interlocking = profileForTileType(TileSlateType.interlockingTile);
      expect(interlocking.horizontalSetSize, 2);
      expect(showsUnderEaveBattenForMaterial('Interlocking Tile'), isFalse);

      final datum = resolveVerticalBattenDatum(
        materialType: 'Interlocking Tile',
        tileHeight: 420,
        gutterOverhang: 50,
        maxGauge: 345,
      );
      expect(datum.eaveBattenMm, 345);
      expect(datum.firstGaugeBattenMm, 345);
    });

    test('gaugeBattenStartMm prefers first gauge batten', () {
      const profile = TileCalculationProfile();
      expect(
        profile.gaugeBattenStartMm(eaveBatten: 150, firstGaugeBatten: 200),
        200,
      );
      expect(
        profile.gaugeBattenStartMm(eaveBatten: 210),
        210,
      );
    });

    test('ridge offset bounds and dry/wet starting points', () {
      expect(baseRidgeOffsetMm('NO'), kRidgeOffsetMinMm);
      expect(baseRidgeOffsetMm('YES'), kRidgeOffsetDryMaxMm);
      expect(ridgeOffsetMaxMm('NO'), kRidgeOffsetWetMaxMm);
      expect(ridgeOffsetMaxMm('YES'), kRidgeOffsetDryMaxMm);
      expect(isRidgeOffsetInBounds(25, 'NO'), isTrue);
      expect(isRidgeOffsetInBounds(50, 'NO'), isTrue);
      expect(isRidgeOffsetInBounds(51, 'NO'), isFalse);
      expect(isRidgeOffsetInBounds(65, 'YES'), isTrue);
      expect(isRidgeOffsetInBounds(66, 'YES'), isFalse);
      expect(isRidgeOffsetInBounds(24, 'NO'), isFalse);
    });

    test('resolveHorizontalSetSize uses profile then cover width fallback', () {
      expect(
        resolveHorizontalSetSize(
          materialType: 'Plain Tile',
          tileCoverWidth: 165,
        ),
        3,
      );
      expect(
        resolveHorizontalSetSize(
          materialType: 'Interlocking Tile',
          tileCoverWidth: 330,
        ),
        2,
      );
      expect(
        resolveHorizontalSetSize(
          materialType: null,
          tileCoverWidth: 400,
        ),
        2,
      );
      expect(
        resolveHorizontalSetSize(
          materialType: null,
          tileCoverWidth: 250,
        ),
        3,
      );
    });
  });
}