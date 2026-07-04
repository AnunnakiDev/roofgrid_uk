import 'package:roofgrid_uk/models/developer_mode_config.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';

bool canBrowseTileDatabase(UserModel? user, DeveloperModeState devMode) {
  return resolveEffectiveIsPro(user, devMode);
}

bool canSavePersonalTiles(UserModel? user, DeveloperModeState devMode) {
  return resolveEffectiveIsPro(user, devMode);
}

bool canManageDefaultTiles(UserModel? user) {
  return user?.isAdmin ?? false;
}

bool canUseManualTileInput(UserModel? user) {
  return user != null;
}

bool isDefaultCatalogueTile(TileModel tile) {
  return tile.isPublic && tile.isApproved;
}

bool canEditTileInList({
  required TileModel tile,
  required UserModel user,
  required bool effectiveIsPro,
}) {
  if (user.isAdmin) return true;
  if (!effectiveIsPro) return false;
  if (isDefaultCatalogueTile(tile)) return false;
  return tile.createdById == user.id;
}

bool canAddTilesInList({
  required UserModel user,
  required bool effectiveIsPro,
}) {
  return effectiveIsPro || user.isAdmin;
}

List<TileModel> partitionDefaultTiles(List<TileModel> tiles) {
  return tiles.where(isDefaultCatalogueTile).toList();
}

List<TileModel> partitionPersonalTiles(List<TileModel> tiles, String userId) {
  return tiles
      .where((tile) => !isDefaultCatalogueTile(tile) && tile.createdById == userId)
      .toList();
}