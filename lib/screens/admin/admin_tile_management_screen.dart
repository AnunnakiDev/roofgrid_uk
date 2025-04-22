import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:roofgrid_uk/widgets/tile_selector_widget.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class AdminTileManagementScreen extends ConsumerStatefulWidget {
  const AdminTileManagementScreen({super.key});

  @override
  ConsumerState<AdminTileManagementScreen> createState() =>
      _AdminTileManagementScreenState();
}

class _AdminTileManagementScreenState
    extends ConsumerState<AdminTileManagementScreen> {
  List<TileModel> _defaultTiles = [];
  List<Map<String, dynamic>> _pendingTiles = [];
  bool _isLoadingTiles = true;

  @override
  void initState() {
    super.initState();
    _fetchTiles();
  }

  Future<void> _fetchTiles() async {
    setState(() {
      _isLoadingTiles = true;
    });
    try {
      // Fetch default tiles (public and approved)
      final defaultTilesSnapshot = await FirebaseFirestore.instance
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      _defaultTiles = defaultTilesSnapshot.docs
          .map((doc) => TileModel.fromFirestore(doc))
          .toList();

      // Fetch pending user-submitted tiles
      final pendingTilesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .get();
      _pendingTiles = [];
      for (var doc in pendingTilesSnapshot.docs) {
        final tile = TileModel.fromFirestore(doc);
        final userId = doc.reference.parent.parent?.id;
        if (userId != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          final user = UserModel.fromFirestore(userDoc);
          _pendingTiles.add({
            'tile': tile,
            'userId': userId,
            'userEmail': user.email ?? 'Unknown',
          });
        }
      }

      setState(() {
        _isLoadingTiles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTiles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tiles: $e')),
      );
    }
  }

  Future<void> _importTilesFromCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final csvString = await file.readAsString();
        final csvRows = const CsvToListConverter().convert(csvString);

        // Validate CSV headers
        final expectedHeaders = [
          'name',
          'manufacturer',
          'materialType',
          'description',
          'slateTileHeight',
          'tileCoverWidth',
          'minGauge',
          'maxGauge',
          'minSpacing',
          'maxSpacing',
          'defaultCrossBonded',
          'leftHandTileWidth',
          'dataSheet',
          'image',
        ];
        if (csvRows.isEmpty || csvRows[0].length < expectedHeaders.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid CSV format')),
          );
          return;
        }

        // Skip the header row
        final tiles = <TileModel>[];
        final now = DateTime.now();
        for (var i = 1; i < csvRows.length; i++) {
          final row = csvRows[i];
          final materialType = TileSlateType.values.firstWhere(
            (type) =>
                type.toString().split('.').last == (row[2]?.toString() ?? ''),
            orElse: () => TileSlateType.unknown,
          );
          final tile = TileModel(
            id: 'kem_${DateTime.now().millisecondsSinceEpoch}_$i',
            name: row[0]?.toString() ?? '',
            manufacturer: row[1]?.toString() ?? '',
            materialType: materialType,
            description: row[3]?.toString() ?? '',
            isPublic: true,
            isApproved: true,
            createdById: 'admin',
            createdAt: now,
            updatedAt: now,
            slateTileHeight: double.tryParse(row[4]?.toString() ?? '0') ?? 0,
            tileCoverWidth: double.tryParse(row[5]?.toString() ?? '0') ?? 0,
            minGauge: double.tryParse(row[6]?.toString() ?? '0') ?? 0,
            maxGauge: double.tryParse(row[7]?.toString() ?? '0') ?? 0,
            minSpacing: double.tryParse(row[8]?.toString() ?? '0') ?? 0,
            maxSpacing: double.tryParse(row[9]?.toString() ?? '0') ?? 0,
            defaultCrossBonded: row[10]?.toString().toLowerCase() == 'true',
            leftHandTileWidth:
                double.tryParse(row[11]?.toString() ?? '') ?? null,
            dataSheet: row[12]?.toString(),
            image: row[13]?.toString(),
          );
          tiles.add(tile);
        }

        // Save tiles to Firestore
        for (var tile in tiles) {
          await FirebaseFirestore.instance
              .collection('tiles')
              .doc(tile.id)
              .set(tile.toJson());
        }

        await _fetchTiles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${tiles.length} tiles')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing tiles: $e')),
      );
    }
  }

  Future<void> _deleteTile(String tileId) async {
    await FirebaseFirestore.instance.collection('tiles').doc(tileId).delete();
    await _fetchTiles();
  }

  Future<void> _approveTile(TileModel tile, String userId) async {
    // Move the tile to the main tiles collection and mark as approved
    final updatedTile = tile.copyWith(
      isApproved: true,
      updatedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance
        .collection('tiles')
        .doc(tile.id)
        .set(updatedTile.toJson());

    // Remove from user's pending tiles
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tiles')
        .doc(tile.id)
        .delete();

    await _fetchTiles();
  }

  Future<void> _denyTile(TileModel tile, String userId) async {
    // Update the tile to mark as not approved and not public
    final updatedTile = tile.copyWith(
      isPublic: false,
      isApproved: false,
      updatedAt: DateTime.now(),
    );
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('tiles')
        .doc(tile.id)
        .set(updatedTile.toJson());

    await _fetchTiles();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tile Management'),
      ),
      body: _isLoadingTiles
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeaderWidget(title: 'Admin Dashboard: Tile Management'),
                  const SizedBox(height: 16),
                  _buildButtonRow(user),
                  const SizedBox(height: 16),
                  const Text(
                    'Default Tiles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TileSelectorWidget(
                    tiles: _defaultTiles,
                    user: user!,
                    showAddTileButton: false,
                    onTileSelected: (tile) {
                      context.go(
                        '/admin/edit-tile/${tile.id}',
                        extra: {
                          'userRole': user.role,
                          'userId': user.id,
                          'tile': tile,
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pending Approvals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _pendingTiles.isEmpty
                      ? const Center(
                          child: Text('No pending tiles for approval'))
                      : TileSelectorWidget(
                          tiles: _pendingTiles
                              .map((tileData) => tileData['tile'] as TileModel)
                              .toList(),
                          user: user,
                          showAddTileButton: false,
                          onTileSelected: (tile) {
                            final tileData = _pendingTiles
                                .firstWhere((data) => data['tile'] == tile);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title:
                                    Text('Manage Pending Tile: ${tile.name}'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('User ID: ${tileData['userId']}'),
                                    Text(
                                        'User Email: ${tileData['userEmail']}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => _approveTile(
                                        tile, tileData['userId'] as String),
                                    child: const Text('Approve',
                                        style: TextStyle(color: Colors.green)),
                                  ),
                                  TextButton(
                                    onPressed: () => _denyTile(
                                        tile, tileData['userId'] as String),
                                    child: const Text('Deny',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildButtonRow(UserModel? user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _importTilesFromCSV,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Import CSV',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (user != null) {
                    context.go(
                      '/admin/add-tile',
                      extra: {
                        'userRole': user.role,
                        'userId': user.id,
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Add New Tile',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: _importTilesFromCSV,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Import CSV',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (user != null) {
                    context.go(
                      '/admin/add-tile',
                      extra: {
                        'userRole': user.role,
                        'userId': user.id,
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Add New Tile',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
  }
}
