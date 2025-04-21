import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/custom_expansion_tile.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
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
  List<TileModel> _filteredDefaultTiles = [];
  List<Map<String, dynamic>> _pendingTiles = [];
  List<Map<String, dynamic>> _filteredPendingTiles = [];
  bool _isLoadingTiles = true;
  String _searchQuery = '';
  String _searchField = 'Name'; // Default search field
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _filteredDefaultTiles = List.from(_defaultTiles);

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
      _filteredPendingTiles = List.from(_pendingTiles);

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

  void _filterTiles(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.isEmpty) {
        _filteredDefaultTiles = List.from(_defaultTiles);
        _filteredPendingTiles = List.from(_pendingTiles);
      } else {
        final queryLower = _searchQuery.toLowerCase();
        // Filter default tiles
        _filteredDefaultTiles = _defaultTiles.where((tile) {
          switch (_searchField) {
            case 'Name':
              return tile.name.toLowerCase().contains(queryLower);
            case 'Manufacturer':
              return tile.manufacturer.toLowerCase().contains(queryLower);
            case 'Material Type':
              return tile.materialTypeString.toLowerCase().contains(queryLower);
            default:
              return false;
          }
        }).toList();

        // Filter pending tiles
        _filteredPendingTiles = _pendingTiles.where((tileData) {
          final tile = tileData['tile'] as TileModel;
          final userEmail = tileData['userEmail'] as String;
          switch (_searchField) {
            case 'Name':
              return tile.name.toLowerCase().contains(queryLower);
            case 'Manufacturer':
              return tile.manufacturer.toLowerCase().contains(queryLower);
            case 'Material Type':
              return tile.materialTypeString.toLowerCase().contains(queryLower);
            case 'User Email':
              return userEmail.toLowerCase().contains(queryLower);
            default:
              return false;
          }
        }).toList();
      }
    });
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
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  const Text(
                    'Default Tiles',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildButtonRow(user),
                  const SizedBox(height: 16),
                  _filteredDefaultTiles.isEmpty
                      ? const Center(child: Text('No default tiles found'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredDefaultTiles.length,
                          itemBuilder: (context, index) {
                            final tile = _filteredDefaultTiles[index];
                            return _buildTileCard(
                              tile: tile,
                              index: index,
                              isPending: false,
                              user: user,
                            );
                          },
                        ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pending Approvals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _filteredPendingTiles.isEmpty
                      ? const Center(
                          child: Text('No pending tiles for approval'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredPendingTiles.length,
                          itemBuilder: (context, index) {
                            final tileData = _filteredPendingTiles[index];
                            final tile = tileData['tile'] as TileModel;
                            return _buildTileCard(
                              tile: tile,
                              index: index,
                              isPending: true,
                              userId: tileData['userId'],
                              userEmail: tileData['userEmail'],
                              user: user,
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return isSmallScreen
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _filterTiles,
                decoration: InputDecoration(
                  hintText: 'Search by $_searchField',
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                              _filterTiles('');
                            });
                          },
                          tooltip: 'Clear search',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _searchField,
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _searchField = value!;
                    _searchQuery = '';
                    _searchController.clear();
                    _filterTiles('');
                  });
                },
                items: ['Name', 'Manufacturer', 'Material Type', 'User Email']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterTiles,
                  decoration: InputDecoration(
                    hintText: 'Search by $_searchField',
                    hintStyle: const TextStyle(fontSize: 14),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                                _filterTiles('');
                              });
                            },
                            tooltip: 'Clear search',
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _searchField,
                onChanged: (value) {
                  setState(() {
                    _searchField = value!;
                    _searchQuery = '';
                    _searchController.clear();
                    _filterTiles('');
                  });
                },
                items: ['Name', 'Manufacturer', 'Material Type', 'User Email']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
              ),
            ],
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

  Widget _buildTileCard({
    required TileModel tile,
    required int index,
    required bool isPending,
    String? userId,
    String? userEmail,
    UserModel? user,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: CustomExpansionTile(
        leading: tile.image != null && tile.image!.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(tile.image!),
                radius: 24,
                onBackgroundImageError: (exception, stackTrace) =>
                    const Icon(Icons.broken_image),
              )
            : CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: 24,
                child: Text(
                  tile.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        title: Text(
          tile.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        subtitle: Text(
          '${tile.materialTypeString} | ${tile.manufacturer}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPending) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  if (user != null) {
                    context.go(
                      '/admin/edit-tile/${tile.id}',
                      extra: {
                        'userRole': user.role,
                        'userId': user.id,
                        'tile': tile,
                      },
                    );
                  }
                },
                tooltip: 'Edit Tile',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteTile(tile.id),
                tooltip: 'Delete Tile',
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _approveTile(tile, userId!),
                tooltip: 'Approve Tile',
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _denyTile(tile, userId!),
                tooltip: 'Deny Tile',
              ),
            ],
          ],
        ),
        animationIndex: index,
        children: [
          Text(
            'Tile Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _infoRow('Material Type', tile.materialTypeString),
          _infoRow('Manufacturer', tile.manufacturer),
          _infoRow('Description', tile.description),
          Row(
            children: [
              Expanded(
                  child:
                      _infoRow('Height/Length', '${tile.slateTileHeight} mm')),
              const SizedBox(width: 8),
              Expanded(
                  child: _infoRow('Cover Width', '${tile.tileCoverWidth} mm')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _infoRow('Min Gauge', '${tile.minGauge} mm')),
              const SizedBox(width: 8),
              Expanded(child: _infoRow('Max Gauge', '${tile.maxGauge} mm')),
            ],
          ),
          Row(
            children: [
              Expanded(child: _infoRow('Min Spacing', '${tile.minSpacing} mm')),
              const SizedBox(width: 8),
              Expanded(child: _infoRow('Max Spacing', '${tile.maxSpacing} mm')),
            ],
          ),
          _infoRow('Cross Bonded', tile.defaultCrossBonded ? 'Yes' : 'No'),
          if (tile.leftHandTileWidth != null && tile.leftHandTileWidth! > 0)
            _infoRow('Left Hand Tile Width', '${tile.leftHandTileWidth} mm'),
          if (tile.dataSheet != null && tile.dataSheet!.isNotEmpty)
            _infoRow('Data Sheet', tile.dataSheet!),
          if (tile.image != null && tile.image!.isNotEmpty)
            _infoRow('Image URL', tile.image!),
          if (isPending) ...[
            const SizedBox(height: 16),
            Text(
              'Submitted By',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            _infoRow('User ID', userId!),
            _infoRow('User Email', userEmail!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
