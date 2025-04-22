import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';
import 'package:roofgrid_uk/widgets/tile_selector_widget.dart';
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
          ),
          drawer: const MainDrawer(),
          body: user.isPro
              ? _buildProUserContent(user)
              : _buildFreeUserContent(user),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 3,
            onTap: (index) {
              if (index == 0) context.go('/home');
              if (index == 1) context.go('/calculator/tile-select');
              if (index == 2) context.go('/results');
              if (index == 3) context.go('/tiles');
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
        if (tiles.isEmpty) {
          return _buildPlaceholderContent(context, user);
        }
        return TileSelectorWidget(
          tiles: tiles,
          user: user,
          showAddTileButton: true,
          onTileSelected: (tile) {
            context.push('/calculator/tile-select', extra: {'tile': tile});
          },
        );
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
          return TileSelectorWidget(
            tiles: tiles,
            user: user,
            showAddTileButton: true,
            onTileSelected: (tile) {
              context.push('/calculator/tile-select', extra: {'tile': tile});
            },
          );
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
}
