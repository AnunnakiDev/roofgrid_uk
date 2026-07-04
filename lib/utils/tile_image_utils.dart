import 'package:flutter/material.dart';
import 'package:roofgrid_uk/models/tile_model.dart';

/// Bundled placeholder images for each tile material type.
String defaultTileImageAsset(TileSlateType type) {
  switch (type) {
    case TileSlateType.slate:
      return 'assets/images/tiles/natural_slate.jpg';
    case TileSlateType.fibreCementSlate:
      return 'assets/images/tiles/fibre_cement_slate.jpg';
    case TileSlateType.interlockingTile:
      return 'assets/images/tiles/interlocking_tile.jpg';
    case TileSlateType.plainTile:
      return 'assets/images/tiles/plain_tile.png';
    case TileSlateType.concreteTile:
      return 'assets/images/tiles/concrete_tile.jpg';
    case TileSlateType.pantile:
      return 'assets/images/tiles/pantile.png';
    case TileSlateType.unknown:
      return 'assets/images/tiles/unknown_type.jpg';
  }
}

bool isBundledTileImage(String? image) =>
    image != null && image.startsWith('assets/');

bool isBrokenRemoteTileImage(String? image) =>
    image != null &&
    image.isNotEmpty &&
    !isBundledTileImage(image) &&
    (image.contains('example.com') || image.contains('placeholder'));

String? resolvedTileImage(String? image, TileSlateType materialType) {
  if (image == null || image.isEmpty || isBrokenRemoteTileImage(image)) {
    return defaultTileImageAsset(materialType);
  }
  return image;
}

Widget buildTilePreviewImage({
  required String? image,
  required TileSlateType materialType,
  required Widget Function(TileSlateType) placeholderBuilder,
  double width = 40,
  double height = 40,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  final resolved = resolvedTileImage(image, materialType);
  final imageWidget = isBundledTileImage(resolved)
      ? Image.asset(
          resolved!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              placeholderBuilder(materialType),
        )
      : Image.network(
          resolved!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              placeholderBuilder(materialType),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: width,
              height: height,
              child: const CircularProgressIndicator(),
            );
          },
        );

  if (borderRadius == null) return imageWidget;

  return ClipRRect(
    borderRadius: borderRadius,
    child: imageWidget,
  );
}