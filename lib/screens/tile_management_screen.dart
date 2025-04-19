import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/screens/calculator/tile_selector_screen.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TileManagementScreen extends ConsumerStatefulWidget {
  const TileManagementScreen({super.key});

  @override
  ConsumerState<TileManagementScreen> createState() =>
      _TileManagementScreenState();
}

class _TileManagementScreenState extends ConsumerState<TileManagementScreen> {
  bool _isLoading = false;
  TileSlateType? _selectedTileSlateType;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        ref.refresh(allAvailableTilesProvider(
            ref.read(currentUserProvider).value?.id ?? ''));
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(currentUserProvider);

    // Early check for authentication state to prevent provider calls
    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(child: Text('Please log in to access this feature')),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tile Management'),
            leading: Builder(
              builder: (context) => Semantics(
                label: 'Open navigation drawer',
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Open navigation drawer',
                ),
              ),
            ),
            actions: user.isPro
                ? [
                    Semantics(
                      label: 'Add new tile',
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => context.go('/calculator/tile-select'),
                        tooltip: 'Add a new tile',
                      ),
                    ),
                  ]
                : null,
          ),
          drawer: const MainDrawer(),
          body: user.isPro
              ? _buildProUserContent(user)
              : _buildFreeUserContent(user),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 3,
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  context.go('/calculator/tile-select');
                  break;
                case 2:
                  context.go('/results');
                  break;
                case 3:
                  context.go('/tiles');
                  break;
              }
            },
            items: const [
              BottomNavItem(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home),
              BottomNavItem(
                  label: 'Calculator',
                  icon: Icons.calculate_outlined,
                  activeIcon: Icons.calculate),
              BottomNavItem(
                  label: 'Results',
                  icon: Icons.save_outlined,
                  activeIcon: Icons.save),
              BottomNavItem(
                  label: 'Tiles',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading user data',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              Text(error.toString(), style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProUserContent(UserModel user) {
    final tilesAsync = ref.watch(allAvailableTilesProvider(user.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Manage your tile profiles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: tilesAsync.when(
            data: (tiles) {
              if (_isOnline) {
                final tilesBox = Hive.box<TileModel>('tilesBox');
                for (var tile in tiles) {
                  tilesBox.put(tile.id, tile);
                }
              }
              if (!_isOnline) {
                final tilesBox = Hive.box<TileModel>('tilesBox');
                tiles = tilesBox.values.toList();
              }
              if (tiles.isEmpty) {
                return _buildPlaceholderContent(context, user);
              }
              return _buildTileList(tiles, user);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stackTrace) {
              if (err is UnauthenticatedException) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/auth/login');
                });
                return const Center(
                    child: Text('Please log in to access this feature'));
              }
              final tilesBox = Hive.box<TileModel>('tilesBox');
              final tiles = tilesBox.values.toList();
              if (tiles.isNotEmpty) {
                return _buildTileList(tiles, user);
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tiles: $err',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(BuildContext context, UserModel user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tiles Available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Get started by creating your first tile profile.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Semantics(
              label: 'Create new tile',
              child: ElevatedButton(
                onPressed: () => context.go('/calculator/tile-select'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                child: const Text('Create New Tile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeUserContent(UserModel user) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: Container(
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view, size: 80, color: Colors.grey),
                  SizedBox(height: 24),
                  Text(
                    'Tile Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Upgrade to Pro to access tile management features.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Upgrade to Pro',
                  child: ElevatedButton(
                    onPressed: () => context.go('/subscription'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                    child: const Text('Upgrade to Pro'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTileList(List<TileModel> tiles, UserModel user) {
    final groupedTiles = <TileSlateType, List<TileModel>>{};
    for (final tile in tiles) {
      if (!groupedTiles.containsKey(tile.materialType)) {
        groupedTiles[tile.materialType] = [];
      }
      groupedTiles[tile.materialType]!.add(tile);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: groupedTiles.keys.length,
      itemBuilder: (context, index) {
        final tileSlateType = groupedTiles.keys.elementAt(index);
        final tilesInGroup = groupedTiles[tileSlateType]!;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: tilesInGroup.first.image != null &&
                    tilesInGroup.first.image!.isNotEmpty
                ? Image.network(tilesInGroup.first.image!,
                    width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image_not_supported, size: 50),
            title: Text(
              _getTileSlateTypeDisplayName(tileSlateType),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Max Gauge: ${tilesInGroup.first.maxGauge} mm | Cover Width: ${tilesInGroup.first.tileCoverWidth} mm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            children: tilesInGroup
                .map((tile) => _buildTileListItem(tile, user))
                .toList(),
          ),
        ).animate().fadeIn();
      },
    );
  }

  Widget _buildTileListItem(TileModel tile, UserModel user) {
    final isEditable = tile.createdById == user.id ||
        (user.isPro && tile.createdById == 'system');
    final isDeletable = tile.createdById == user.id;
    final canSubmit = !tile.isPublic || !tile.isApproved;
    final isPending = tile.isPublic && !tile.isApproved;
    final canShowSubmitButton = (user.isPro || user.isAdmin) &&
        tile.createdById == user.id &&
        canSubmit;

    return ListTile(
      leading: tile.image != null && tile.image!.isNotEmpty
          ? Image.network(tile.image!, width: 40, height: 40, fit: BoxFit.cover)
          : const Icon(Icons.image_not_supported, size: 40),
      title: Text(tile.name, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(
        '${tile.manufacturer} - ${tile.description}${isPending ? ' (Pending Review)' : ''}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditable)
            Semantics(
              label: 'Edit tile ${tile.name}',
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context
                    .go('/calculator/tile-select', extra: {'tile': tile}),
                tooltip: 'Edit this tile',
              ),
            ),
          if (isDeletable)
            Semantics(
              label: 'Delete tile ${tile.name}',
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDeleteTile(context, tile),
                color: Theme.of(context).colorScheme.error,
                tooltip: 'Delete this tile',
              ),
            ),
          if (canShowSubmitButton)
            Semantics(
              label: isPending
                  ? 'Tile pending review'
                  : 'Submit tile ${tile.name} for review',
              child: IconButton(
                icon: const Icon(Icons.upload),
                onPressed: isPending
                    ? null
                    : () => _submitTileForReview(context, tile, user),
                color: isPending
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
                tooltip: isPending
                    ? 'Tile is pending review'
                    : 'Submit for admin review',
              ),
            ),
        ],
      ),
      onTap: () => _showTileDetails(context, tile),
    );
  }

  void _submitTileForReview(
      BuildContext context, TileModel tile, UserModel user) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot submit tile offline. Please connect to the internet.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tileService = ref.read(tileServiceProvider);
      final updatedTile = tile.copyWith(
        isPublic: true,
        isApproved: false,
        updatedAt: DateTime.now(),
      );
      await tileService.updateTile(updatedTile);
      final tilesBox = Hive.box<TileModel>('tilesBox');
      await tilesBox.put(updatedTile.id, updatedTile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tile submitted for admin review.')),
        );
        ref.refresh(userTilesProvider(user.id));
        ref.refresh(allAvailableTilesProvider(user.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting tile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showTileDetails(BuildContext context, TileModel tile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tile.name,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[300],
                  child: tile.image != null && tile.image!.isNotEmpty
                      ? Image.network(
                          tile.image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              _infoRow('Material Type',
                  _getTileSlateTypeDisplayName(tile.materialType)),
              _infoRow('Manufacturer', tile.manufacturer),
              _infoRow('Height/Length', '${tile.slateTileHeight} mm'),
              _infoRow('Cover Width', '${tile.tileCoverWidth} mm'),
              _infoRow('Min Gauge', '${tile.minGauge} mm'),
              _infoRow('Max Gauge', '${tile.maxGauge} mm'),
              _infoRow('Min Spacing', '${tile.minSpacing} mm'),
              _infoRow('Max Spacing', '${tile.maxSpacing} mm'),
              _infoRow('Cross Bonded', tile.defaultCrossBonded ? 'Yes' : 'No'),
              if (tile.leftHandTileWidth != null && tile.leftHandTileWidth! > 0)
                _infoRow(
                    'Left Hand Tile Width', '${tile.leftHandTileWidth} mm'),
              if (tile.dataSheet != null && tile.dataSheet!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('View Data Sheet:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Semantics(
                        label: 'View data sheet for ${tile.name}',
                        child: ElevatedButton(
                          onPressed: _isOnline
                              ? () async {
                                  final uri = Uri.tryParse(tile.dataSheet!);
                                  if (uri != null && await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Could not open datasheet.')),
                                    );
                                  }
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Cannot open datasheet offline. Please connect to the internet.')),
                                  );
                                },
                          child: const Text('View Data Sheet'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
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
            '$label:',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTile(BuildContext context, TileModel tile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tile?'),
        content: Text(
          'Are you sure you want to delete "${tile.name}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Semantics(
            label: 'Confirm delete tile ${tile.name}',
            child: TextButton(
              onPressed: () async {
                if (!_isOnline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Cannot delete tile offline. Please connect to the internet.')),
                  );
                  return;
                }
                Navigator.of(context).pop();
                final tileService = ref.read(tileServiceProvider);
                final user = ref.read(currentUserProvider).value;
                if (user != null) {
                  setState(() => _isLoading = true);
                  await tileService.deleteTile(tile.id, user.id);
                  final tilesBox = Hive.box<TileModel>('tilesBox');
                  await tilesBox.delete(tile.id);
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ref.refresh(userTilesProvider(user.id));
                    ref.refresh(allAvailableTilesProvider(user.id));
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  String _getTileSlateTypeDisplayName(TileSlateType type) {
    switch (type) {
      case TileSlateType.slate:
        return 'Natural Slate';
      case TileSlateType.fibreCementSlate:
        return 'Fibre Cement Slate';
      case TileSlateType.interlockingTile:
        return 'Interlocking Tile';
      case TileSlateType.plainTile:
        return 'Plain Tile';
      case TileSlateType.concreteTile:
        return 'Concrete Tile';
      case TileSlateType.pantile:
        return 'Pantile';
      case TileSlateType.unknown:
        return 'Unknown Type';
    }
  }
}
