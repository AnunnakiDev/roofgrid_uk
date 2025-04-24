import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/models/user_model.dart';

// Custom exception for unauthenticated access
class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException(this.message);

  @override
  String toString() => message;
}

class TileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTile(TileModel tile) async {
    print('Creating tile: ${tile.id} for user: ${tile.createdById}');
    await _firestore
        .collection('users')
        .doc(tile.createdById)
        .collection('tiles')
        .doc(tile.id)
        .set(tile.toJson());
    // Cache in Hive
    final tilesBox = Hive.box<TileModel>('tilesBox');
    await tilesBox.put(tile.id, tile);
  }

  Future<void> updateTile(TileModel tile) async {
    print('Updating tile: ${tile.id} for user: ${tile.createdById}');
    await _firestore
        .collection('users')
        .doc(tile.createdById)
        .collection('tiles')
        .doc(tile.id)
        .update(tile.toJson());
    // Update Hive
    final tilesBox = Hive.box<TileModel>('tilesBox');
    await tilesBox.put(tile.id, tile);
  }

  Future<void> deleteTile(String tileId, String userId) async {
    print('Deleting tile: $tileId for user: $userId');
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tiles')
        .doc(tileId)
        .delete();
    // Remove from Hive
    final tilesBox = Hive.box<TileModel>('tilesBox');
    await tilesBox.delete(tileId);
  }

  Future<void> saveTile(TileModel tile) async {
    print('Saving tile: ${tile.id} for user: ${tile.createdById}');
    final tileDoc = await _firestore
        .collection('users')
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

  Future<void> saveToDefaultTiles(TileModel tile) async {
    print('Saving tile to default tiles: ${tile.id}');
    await _firestore.collection('tiles').doc(tile.id).set(tile.toJson());
    // Cache in Hive
    final tilesBox = Hive.box<TileModel>('tilesBox');
    await tilesBox.put(tile.id, tile);
  }

  Future<List<TileModel>> fetchUserTiles(String userId) async {
    print('Fetching user tiles for userId: $userId');
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tiles')
        .get();
    final tiles =
        snapshot.docs.map((doc) => TileModel.fromJson(doc.data())).toList();
    // Cache in Hive
    final tilesBox = Hive.box<TileModel>('tilesBox');
    for (var tile in tiles) {
      await tilesBox.put(tile.id, tile);
    }
    return tiles;
  }

  Future<List<TileModel>> fetchAllAvailableTiles(String userId) async {
    print('Fetching all available tiles for userId: $userId');
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;
    final tilesBox = Hive.box<TileModel>('tilesBox');

    if (!isOnline) {
      print('Offline: Returning cached tiles from Hive');
      return tilesBox.values.toList();
    }

    // Fetch public tiles from the main tiles collection
    final publicSnapshot = await _firestore
        .collection('tiles')
        .where('isPublic', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .get();
    final publicTiles = publicSnapshot.docs
        .map((doc) => TileModel.fromJson(doc.data()))
        .toList();

    // Fetch user tiles from the subcollection: users/$userId/tiles
    final userTiles = await fetchUserTiles(userId);

    final allTiles = [...publicTiles, ...userTiles];
    // Cache all tiles in Hive
    for (var tile in allTiles) {
      await tilesBox.put(tile.id, tile);
    }
    print(
        'Fetched ${allTiles.length} tiles (public: ${publicTiles.length}, user: ${userTiles.length})');
    return allTiles;
  }
}

final tileServiceProvider = Provider<TileService>((ref) {
  return TileService();
});

final userTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final authState = ref.watch(authStateStreamProvider);
  print('userTilesProvider: Checking auth state for userId: $userId');
  if (authState.asData?.value == null) {
    print('userTilesProvider: User not authenticated, throwing exception');
    throw UnauthenticatedException('User must be logged in to access tiles');
  }

  final user = ref.read(currentUserProvider).value;
  if (user == null || (!user.isPro && user.role != UserRole.admin)) {
    print('userTilesProvider: User is not Pro or Admin, returning empty list');
    return []; // Free users have no saved tiles
  }

  print('userTilesProvider: Fetching tiles for userId: $userId');
  final tileService = ref.read(tileServiceProvider);
  return tileService.fetchUserTiles(userId);
});

final allAvailableTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final authState = ref.watch(authStateStreamProvider);
  print('allAvailableTilesProvider: Checking auth state for userId: $userId');
  if (authState.asData?.value == null) {
    print(
        'allAvailableTilesProvider: User not authenticated, throwing exception');
    throw UnauthenticatedException('User must be logged in to access tiles');
  }

  final user = ref.read(currentUserProvider).value;
  if (user == null || (!user.isPro && user.role != UserRole.admin)) {
    print(
        'allAvailableTilesProvider: User is not Pro or Admin, returning empty list');
    return []; // Free users have no access to the tile database
  }

  print('allAvailableTilesProvider: Fetching all tiles for userId: $userId');
  final tileService = ref.read(tileServiceProvider);
  return tileService.fetchAllAvailableTiles(userId);
});
