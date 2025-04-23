import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/tile_selector_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TileSelectorScreen extends ConsumerStatefulWidget {
  const TileSelectorScreen({super.key});

  @override
  ConsumerState<TileSelectorScreen> createState() => _TileSelectorScreenState();
}

class _TileSelectorScreenState extends ConsumerState<TileSelectorScreen> {
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
        ref.invalidate(allAvailableTilesProvider(
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
            body: Center(child: Text('User not found. Please sign in again.')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Tile'),
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
          ),
          drawer: const MainDrawer(),
          body: user.isPro
              ? _buildProUserContent(user)
              : _buildFreeUserContent(user),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildProUserContent(UserModel user) {
    final extra =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final TileModel? initialTile = extra?['tile'] as TileModel?;

    final tilesAsync = ref.watch(allAvailableTilesProvider(user.id));
    return tilesAsync.when(
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
        if (initialTile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: AddTileWidget(
                    userRole: user.role,
                    userId: user.id,
                    tile: initialTile,
                    onTileCreated: (updatedTile) {
                      Navigator.pop(context);
                      context.pop(
                          updatedTile); // Use go_router's pop to return the result
                    },
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error showing edit tile dialog: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error editing tile: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          });
        }
        return TileSelectorWidget(
          tiles: tiles,
          user: user,
          onTileSelected: (tile) {
            try {
              context.pop(tile); // Use go_router's pop to return the result
            } catch (e) {
              debugPrint('Error returning selected tile: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error selecting tile: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        if (error is UnauthenticatedException) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/auth/login');
          });
          return const Center(
              child: Text('Please log in to access this feature'));
        }
        final tilesBox = Hive.box<TileModel>('tilesBox');
        final tiles = tilesBox.values.toList();
        if (tiles.isNotEmpty) {
          return TileSelectorWidget(
            tiles: tiles,
            user: user,
            onTileSelected: (tile) {
              try {
                context.pop(tile); // Use go_router's pop to return the result
              } catch (e) {
                debugPrint('Error returning selected tile: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error selecting tile: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
          );
        }
        return Center(
          child: Text(
            'Error loading tiles: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      },
    );
  }

  Widget _buildFreeUserContent(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tile Selection',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade800),
                    const SizedBox(width: 8),
                    Text(
                      'Manual Tile Input',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'As a free user, you can manually input tile details. Upgrade to Pro to access our full tile database.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Add New Tile',
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: AddTileWidget(
                            userRole: user.role,
                            userId: user.id,
                            onTileCreated: (newTile) {
                              Navigator.pop(context);
                              context.pop(newTile); // Return the new tile
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Add New Tile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildUpgradeToProBox(),
        ],
      ),
    );
  }

  Widget _buildUpgradeToProBox() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Text(
                'Pro Feature',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.amber.shade900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to Pro to access our complete tile database with predefined measurements for all standard UK roofing tiles.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Upgrade to Pro',
            child: ElevatedButton(
              onPressed: () => context.go('/subscription'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700),
              child: const Text('Upgrade to Pro'),
            ),
          ),
        ],
      ),
    );
  }
}
