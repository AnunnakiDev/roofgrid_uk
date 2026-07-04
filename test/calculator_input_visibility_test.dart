import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/utils/calculator_input_visibility.dart';

TileModel _tile({required bool defaultCrossBonded}) {
  return TileModel(
    id: 'tile-1',
    name: 'Test Tile',
    manufacturer: 'Test',
    materialType: TileSlateType.plainTile,
    description: 'Test tile',
    isPublic: true,
    isApproved: true,
    createdById: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    slateTileHeight: 265,
    tileCoverWidth: 165,
    minGauge: 85,
    maxGauge: 115,
    minSpacing: 1,
    maxSpacing: 7,
    defaultCrossBonded: defaultCrossBonded,
  );
}

void main() {
  group('calculator_input_visibility', () {
    test('crossBondedFromTile maps catalogue default to YES/NO', () {
      expect(crossBondedFromTile(_tile(defaultCrossBonded: true)), 'YES');
      expect(crossBondedFromTile(_tile(defaultCrossBonded: false)), 'NO');
    });

    test('resolveCrossBonded prefers saved value over tile default', () {
      expect(
        resolveCrossBonded(saved: 'NO', tile: _tile(defaultCrossBonded: true)),
        'NO',
      );
      expect(
        resolveCrossBonded(saved: null, tile: _tile(defaultCrossBonded: true)),
        'YES',
      );
    });



    test('isLeftHandTileEnabled only allows NONE abutment', () {
      expect(isLeftHandTileEnabled('NONE'), isTrue);
      expect(isLeftHandTileEnabled('LEFT'), isFalse);
      expect(isLeftHandTileEnabled('RIGHT'), isFalse);
      expect(isLeftHandTileEnabled('BOTH'), isFalse);
    });
  });
}