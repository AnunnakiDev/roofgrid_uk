import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/navigation/home_back_button.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/tile_selector_widget.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

class AdminTileManagementScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const AdminTileManagementScreen({super.key, this.initialTab});

  @override
  ConsumerState<AdminTileManagementScreen> createState() =>
      _AdminTileManagementScreenState();
}

class _AdminTileManagementScreenState
    extends ConsumerState<AdminTileManagementScreen> {
  List<TileModel> _defaultTiles = [];
  bool _isLoadingTiles = true;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _proTilesSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchDefaultTiles();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProTilesSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sectionContext = _proTilesSectionKey.currentContext;
      if (sectionContext != null && sectionContext.mounted) {
        Scrollable.ensureVisible(
          sectionContext,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchDefaultTiles() async {
    setState(() => _isLoadingTiles = true);
    try {
      final defaultTilesSnapshot = await FirebaseFirestore.instance
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      _defaultTiles = defaultTilesSnapshot.docs
          .map((doc) => TileModel.fromFirestore(doc))
          .toList();

      setState(() => _isLoadingTiles = false);
      ref.invalidate(proPersonalTilesProvider);
      if (widget.initialTab == 'pending' || widget.initialTab == 'pro') {
        _scrollToProTilesSection();
      }
    } catch (e) {
      setState(() => _isLoadingTiles = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tiles: $e')),
        );
      }
    }
  }

  void _openDefaultTileDialog({
    required UserModel user,
    TileModel? tile,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: AddTileWidget(
          userRole: user.role,
          userId: user.id,
          tile: tile,
          forceSaveDestination: 'Default',
          onTileCreated: (_) => _fetchDefaultTiles(),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDefaultTile(TileModel tile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete default tile?'),
        content: Text('Remove "${tile.name}" from the default catalogue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(tileServiceProvider).deleteDefaultTile(tile.id);
    await _fetchDefaultTiles();
  }

  Future<void> _promoteProTile(ProPersonalTileEntry entry) async {
    await ref.read(tileServiceProvider).promotePersonalTileToDefault(entry.tile);
    ref.invalidate(proPersonalTilesProvider);
    await _fetchDefaultTiles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${entry.tile.name}" to default tiles')),
      );
    }
  }

  Future<void> _deleteProTile(ProPersonalTileEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete pro user tile?'),
        content: Text(
          'Delete "${entry.tile.name}" from ${entry.userEmail}\'s personal tiles?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(tileServiceProvider)
        .deleteTile(entry.tile.id, entry.userId);
    ref.invalidate(proPersonalTilesProvider);
  }

  Future<void> _importTilesFromCSV() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final csvRows = const CsvToListConverter().convert(csvString);

      const expectedHeaders = [
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

      final tiles = <TileModel>[];
      final now = DateTime.now();
      for (var i = 1; i < csvRows.length; i++) {
        final row = csvRows[i];
        final materialType = TileSlateType.values.firstWhere(
          (type) =>
              type.toString().split('.').last == (row[2]?.toString() ?? ''),
          orElse: () => TileSlateType.unknown,
        );
        tiles.add(
          TileModel(
            id: 'csv_${DateTime.now().millisecondsSinceEpoch}_$i',
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
            leftHandTileWidth: double.tryParse(row[11]?.toString() ?? ''),
            dataSheet: row[12]?.toString(),
            image: row[13]?.toString(),
          ),
        );
      }

      final tileService = ref.read(tileServiceProvider);
      for (final tile in tiles) {
        await tileService.saveToDefaultTiles(tile);
      }

      await _fetchDefaultTiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${tiles.length} tiles')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing tiles: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final proTilesAsync = ref.watch(proPersonalTilesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding =
        isLargeScreen ? const EdgeInsets.all(24.0) : const EdgeInsets.all(16.0);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tile Management'),
        actions: const [HomeBackButton()],
      ),
      drawer: const MainDrawer(),
      body: _isLoadingTiles
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: _scrollController,
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
                    user: user,
                    showAddTileButton: false,
                    showSectionHeaders: false,
                    embeddedInScrollView: true,
                    onTileSelected: (tile) => _openDefaultTileDialog(
                      user: user,
                      tile: tile,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    key: _proTilesSectionKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pro User Tiles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        proTilesAsync.when(
                          data: (entries) {
                            if (entries.isEmpty) {
                              return const Center(
                                child: Text('No pro personal tiles found'),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return ListTile(
                                  title: Text(entry.tile.name),
                                  subtitle: Text(
                                    '${entry.tile.manufacturer} · ${entry.userEmail}',
                                  ),
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            _promoteProTile(entry),
                                        child: const Text('Add to default'),
                                      ),
                                      TextButton(
                                        onPressed: () => _deleteProTile(entry),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (error, _) => Text(
                            'Error loading pro tiles: $error',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildButtonRow(UserModel user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    final importButton = ElevatedButton(
      onPressed: _importTilesFromCSV,
      child: const Text('Import CSV'),
    );
    final addButton = ElevatedButton(
      onPressed: () => _openDefaultTileDialog(user: user),
      child: const Text('Add Default Tile'),
    );

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          importButton,
          const SizedBox(height: 8),
          addButton,
        ],
      );
    }

    return Row(
      children: [
        importButton,
        const SizedBox(width: 8),
        addButton,
      ],
    );
  }
}