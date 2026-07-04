import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/tile_access.dart';

class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException(this.message);

  @override
  String toString() => message;
}

class ProPersonalTileEntry {
  final TileModel tile;
  final String userId;
  final String userEmail;

  const ProPersonalTileEntry({
    required this.tile,
    required this.userId,
    required this.userEmail,
  });
}

class TileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTile(TileModel tile) async {
    final personalTile = tile.copyWith(
      isPublic: false,
      isApproved: false,
      updatedAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(personalTile.createdById)
        .collection('tiles')
        .doc(personalTile.id)
        .set(personalTile.toJson());
    await _cacheTile(personalTile);
  }

  Future<void> updateTile(TileModel tile) async {
    await _firestore
        .collection('users')
        .doc(tile.createdById)
        .collection('tiles')
        .doc(tile.id)
        .update(tile.toJson());
    await _cacheTile(tile);
  }

  Future<void> deleteTile(String tileId, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tiles')
        .doc(tileId)
        .delete();
    final tilesBox = await HiveService.ensureTilesBox();
    await tilesBox.delete(tileId);
  }

  Future<void> deleteDefaultTile(String tileId) async {
    await _firestore.collection('tiles').doc(tileId).delete();
    final tilesBox = await HiveService.ensureTilesBox();
    await tilesBox.delete(tileId);
  }

  Future<void> saveTile(TileModel tile) async {
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
    final defaultTile = tile.copyWith(
      isPublic: true,
      isApproved: true,
      updatedAt: DateTime.now(),
    );
    await _firestore.collection('tiles').doc(defaultTile.id).set(defaultTile.toJson());
    await _cacheTile(defaultTile);
  }

  Future<void> promotePersonalTileToDefault(TileModel tile) async {
    await saveToDefaultTiles(tile);
  }

  Future<List<ProPersonalTileEntry>> fetchProPersonalTiles() async {
    final snapshot = await _firestore
        .collectionGroup('tiles')
        .where('isPublic', isEqualTo: false)
        .get();

    final entries = <ProPersonalTileEntry>[];
    final userCache = <String, String>{};

    for (final doc in snapshot.docs) {
      final userId = doc.reference.parent.parent?.id;
      if (userId == null) continue;

      final tile = TileModel.fromFirestore(doc);
      if (!userCache.containsKey(userId)) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final data = userDoc.data();
        final role = data?['role'] as String? ?? 'free';
        if (role == 'admin') continue;
        userCache[userId] = data?['email'] as String? ?? 'Unknown';
      }

      entries.add(
        ProPersonalTileEntry(
          tile: tile,
          userId: userId,
          userEmail: userCache[userId] ?? 'Unknown',
        ),
      );
    }

    return entries;
  }

  Future<List<TileModel>> fetchUserTiles(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('tiles')
        .get();
    final tiles =
        snapshot.docs.map((doc) => TileModel.fromFirestore(doc)).toList();
    for (var tile in tiles) {
      await _cacheTile(tile);
    }
    return tiles;
  }

  Future<List<TileModel>> fetchAllAvailableTiles(String userId) async {
    final isOnline = await isDeviceOnline();
    final tilesBox = await HiveService.ensureTilesBox();

    if (!isOnline) {
      return tilesBox.values.toList();
    }

    final publicSnapshot = await _firestore
        .collection('tiles')
        .where('isPublic', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .get();
    final publicTiles = publicSnapshot.docs
        .map((doc) => TileModel.fromFirestore(doc))
        .toList();

    final userTiles = await fetchUserTiles(userId);

    final allTiles = [...publicTiles, ...userTiles];
    for (var tile in allTiles) {
      await _cacheTile(tile);
    }
    return allTiles;
  }

  Future<void> _cacheTile(TileModel tile) async {
    final tilesBox = await HiveService.ensureTilesBox();
    await tilesBox.put(tile.id, tile);
  }
}

final tileServiceProvider = Provider<TileService>((ref) {
  return TileService();
});

final userTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final authState = ref.watch(authStateStreamProvider);
  if (authState.asData?.value == null) {
    throw UnauthenticatedException('User must be logged in to access tiles');
  }

  final user = ref.read(currentUserProvider).value;
  final devMode = ref.read(developerModeProvider);
  if (user == null || !canSavePersonalTiles(user, devMode)) {
    return [];
  }

  final tileService = ref.read(tileServiceProvider);
  return tileService.fetchUserTiles(userId);
});

final allAvailableTilesProvider =
    FutureProvider.family<List<TileModel>, String>((ref, userId) async {
  final authState = ref.watch(authStateStreamProvider);
  if (authState.asData?.value == null) {
    throw UnauthenticatedException('User must be logged in to access tiles');
  }

  final user = ref.read(currentUserProvider).value;
  final devMode = ref.read(developerModeProvider);
  if (user == null || !canBrowseTileDatabase(user, devMode)) {
    return [];
  }

  final tileService = ref.read(tileServiceProvider);
  return tileService.fetchAllAvailableTiles(userId);
});

final proPersonalTilesProvider = FutureProvider<List<ProPersonalTileEntry>>((ref) async {
  final user = ref.read(currentUserProvider).value;
  if (user == null || !canManageDefaultTiles(user)) {
    return [];
  }

  final tileService = ref.read(tileServiceProvider);
  return tileService.fetchProPersonalTiles();
});