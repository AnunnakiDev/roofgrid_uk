import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/utils/tile_image_utils.dart';

void main() {
  group('tile_image_utils', () {
    test('defaultTileImageAsset returns bundled asset per material type', () {
      expect(
        defaultTileImageAsset(TileSlateType.plainTile),
        'assets/images/tiles/plain_tile.png',
      );
      expect(
        defaultTileImageAsset(TileSlateType.slate),
        'assets/images/tiles/natural_slate.jpg',
      );
    });

    test('resolvedTileImage replaces broken remote URLs', () {
      expect(
        resolvedTileImage(
          'http://example.com/image.jpg',
          TileSlateType.plainTile,
        ),
        'assets/images/tiles/plain_tile.png',
      );
    });

    test('resolvedTileImage keeps valid bundled assets', () {
      const asset = 'assets/images/tiles/concrete_tile.jpg';
      expect(
        resolvedTileImage(asset, TileSlateType.concreteTile),
        asset,
      );
    });

    test('isBundledTileImage identifies asset paths', () {
      expect(isBundledTileImage('assets/images/tiles/pantile.png'), isTrue);
      expect(isBundledTileImage('https://roofgrid.uk/tile.png'), isFalse);
    });
  });
}