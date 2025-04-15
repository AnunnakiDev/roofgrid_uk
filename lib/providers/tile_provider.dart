import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';

class TileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTile(TileModel tile) async {
    await _firestore.collection('tiles').doc(tile.id).set(tile.toJson());
  }

  Future<void> updateTile(TileModel tile) async {
    await _firestore.collection('tiles').doc(tile.id).update(tile.toJson());
  }

  Future<void> deleteTile(String tileId, String userId) async {
    await _firestore
        .collection('tiles')
        .doc(tileId)
        .delete(); // Ensure userId matches in the UI logic
  }

  Future<List<TileModel>> fetchUserTiles(String userId) async {
    final snapshot = await _firestore
        .collection('tiles')
        .where('createdById', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => TileModel.fromJson(doc.data())).toList();
  }

  Future<List<TileModel>> fetchAllAvailableTiles(String userId) async {
    // Fetch system tiles (public) and user-created tiles
    final systemSnapshot = await _firestore
        .collection('tiles')
        .where('isPublic', isEqualTo: true)
        .get();
    final userSnapshot = await _firestore
        .collection('tiles')
        .where('createdById', isEqualTo: userId)
        .get();

    final systemTiles = systemSnapshot.docs
        .map((doc) => TileModel.fromJson(doc.data()))
        .toList();
    final userTiles =
        userSnapshot.docs.map((doc) => TileModel.fromJson(doc.data())).toList();

    return [...systemTiles, ...userTiles];
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
