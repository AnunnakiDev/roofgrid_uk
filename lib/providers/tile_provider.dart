import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

class TileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTile(TileModel tile) async {
    // Save tile in the user's subcollection: tiles/$userId/$tileId
    await _firestore
        .collection('tiles')
        .doc(tile.createdById)
        .collection('tiles')
        .doc(tile.id)
        .set(tile.toJson());
  }

  Future<void> updateTile(TileModel tile) async {
    // Update tile in the user's subcollection: tiles/$userId/$tileId
    await _firestore
        .collection('tiles')
        .doc(tile.createdById)
        .collection('tiles')
        .doc(tile.id)
        .update(tile.toJson());
  }

  Future<void> deleteTile(String tileId, String userId) async {
    // Delete tile from the user's subcollection: tiles/$userId/$tileId
    await _firestore
        .collection('tiles')
        .doc(userId)
        .collection('tiles')
        .doc(tileId)
        .delete();
  }

  Future<void> saveTile(TileModel tile) async {
    // Check if the tile exists to decide between create and update
    final tileDoc = await _firestore
        .collection('tiles')
        .doc(tile.createdById)
        .collection('tiles')
        .doc(tile.id)
        .get();

    if (tileDoc.exists) {
      await updateTile(tile);
    } else {
      await createTile(tile);
    }
  }

  Future<List<TileModel>> fetchUserTiles(String userId) async {
    print('Fetching user tiles for userId: $userId'); // Debug log
    final snapshot = await _firestore
        .collection('tiles')
        .doc(userId)
        .collection('tiles')
        .get();
    return snapshot.docs.map((doc) => TileModel.fromJson(doc.data())).toList();
  }

  Future<List<TileModel>> fetchAllAvailableTiles(String userId) async {
    print('Fetching all available tiles for userId: $userId'); // Debug log
    // Fetch public tiles from the top-level tiles collection
    final publicSnapshot = await _firestore
        .collection('tiles')
        .where('isPublic', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .get();
    final publicTiles = publicSnapshot.docs
        .map((doc) => TileModel.fromJson(doc.data()))
        .toList();

    // Fetch user tiles from the subcollection: tiles/$userId
    final userTiles = await fetchUserTiles(userId);

    return [...publicTiles, ...userTiles];
  }
}

final tileServiceProvider = Provider<TileService>((ref) {
  return TileService();
});

final userTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final tileService = ref.read(tileServiceProvider);
  final user = ref.read(currentUserProvider).value;

  if (user == null || !user.isPro) {
    return []; // Free users have no saved tiles
  }

  return tileService.fetchUserTiles(userId);
});

final allAvailableTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final tileService = ref.read(tileServiceProvider);
  final user = ref.read(currentUserProvider).value;

  if (user == null || !user.isPro) {
    return []; // Free users have no access to the tile database
  }

  return tileService.fetchAllAvailableTiles(userId);
});
