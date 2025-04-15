import 'package:cloud_firestore/cloud_firestore.dart';
import '../../tile_model.dart';

class TileService {
  final FirebaseFirestore _firestore;

  TileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection reference
  CollectionReference<Map<String, dynamic>> get _tilesCollection =>
      _firestore.collection('tiles');

  /// Get all tiles
  Future<List<TileModel>> getAllTiles() async {
    final snapshot =
        await _tilesCollection.where('isApproved', isEqualTo: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TileModel.fromJson(data);
    }).toList();
  }

  /// Get public tiles that are approved
  Future<List<TileModel>> getPublicTiles() async {
    final snapshot = await _tilesCollection
        .where('isPublic', isEqualTo: true)
        .where('isApproved', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TileModel.fromJson(data);
    }).toList();
  }

  /// Get tiles created by a specific user
  Future<List<TileModel>> getUserTiles(String userId) async {
    final snapshot =
        await _tilesCollection.where('createdById', isEqualTo: userId).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return TileModel.fromJson(data);
    }).toList();
  }

  /// Get a tile by ID
  Future<TileModel?> getTileById(String id) async {
    final doc = await _tilesCollection.doc(id).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['id'] = doc.id;
    return TileModel.fromJson(data);
  }

  /// Create a new tile
  Future<TileModel> createTile(TileModel tile) async {
    final docRef = await _tilesCollection.add(tile.toJson());
    return tile.copyWith(id: docRef.id);
  }

  /// Update an existing tile
  Future<void> updateTile(TileModel tile) async {
    await _tilesCollection.doc(tile.id).update(tile.toJson());
  }

  /// Delete a tile
  Future<void> deleteTile(String id) async {
    await _tilesCollection.doc(id).delete();
  }

  /// Submit a tile for approval
  Future<void> submitTileForApproval(TileModel tile) async {
    final updatedTile = tile.copyWith(
      isPublic: true,
      isApproved: false,
    );

    if (tile.id.isEmpty) {
      await createTile(updatedTile);
    } else {
      await updateTile(updatedTile);
    }
  }

  /// Approve a tile (admin only)
  Future<void> approveTile(String id) async {
    await _tilesCollection.doc(id).update({
      'isApproved': true,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Reject a tile (admin only)
  Future<void> rejectTile(String id) async {
    await _tilesCollection.doc(id).update({
      'isApproved': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }
}
