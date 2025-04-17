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
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Screen for managing tiles - Pro users can view all tiles from the database,
/// while free users see a greyed-out section with an "Upgrade to Pro" CTA
class TileManagementScreen extends ConsumerStatefulWidget {
  const TileManagementScreen({super.key});

  @override
  ConsumerState<TileManagementScreen> createState() =>
      _TileManagementScreenState();
}

class _TileManagementScreenState extends ConsumerState<TileManagementScreen> {
  bool _isLoading = false;
  TileSlateType? _selectedTileSlateType;
  File? _imageFile;
  File? _dataSheetFile;
  String? _imageUrl;
  String? _dataSheetUrl;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Check connectivity on init
    _checkConnectivity();
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        // Refresh tiles when going online
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

    // Safety check - redirect if not logged in
    if (!authState.isAuthenticated) {
      print('User is not authenticated'); // Debug log
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access this feature'),
        ),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          print('User is null'); // Debug log
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        print(
            'User authenticated: ${user.id}, Role: ${user.role}, IsAdmin: ${user.isAdmin}'); // Debug log
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tile Management'),
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
            actions: user.isPro
                ? [
                    Tooltip(
                      message: 'Add a new tile',
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showTileForm(context, user, null),
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
            currentIndex: 3, // Tiles is the fourth item (index 3)
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                  break;
                case 1:
                  context.go('/calculator');
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
                activeIcon: Icons.home,
              ),
              BottomNavItem(
                label: 'Calculator',
                icon: Icons.calculate_outlined,
                activeIcon: Icons.calculate,
              ),
              BottomNavItem(
                label: 'Results',
                icon: Icons.save_outlined,
                activeIcon: Icons.save,
              ),
              BottomNavItem(
                label: 'Tiles',
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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

  /// Content for Pro users - can see and edit all tiles
  Widget _buildProUserContent(UserModel user) {
    // Watch all available tiles including system and user-created tiles
    final tilesAsync = ref.watch(allAvailableTilesProvider(user.id));

    return tilesAsync.when(
      data: (tiles) {
        // Sync tiles to Hive if online
        if (_isOnline) {
          final tilesBox = Hive.box<TileModel>('tilesBox');
          for (var tile in tiles) {
            tilesBox.put(tile.id, tile);
          }
          print("Synced ${tiles.length} tiles to Hive");
        }

        // Use Hive if offline
        if (!_isOnline) {
          final tilesBox = Hive.box<TileModel>('tilesBox');
          tiles = tilesBox.values.toList();
          print("Offline: Loaded ${tiles.length} tiles from Hive");
        }

        if (tiles.isEmpty) {
          return _buildPlaceholderContent(context, user);
        }

        return _buildTileList(tiles, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stackTrace) {
        // Fallback to Hive if Firestore fails
        final tilesBox = Hive.box<TileModel>('tilesBox');
        final tiles = tilesBox.values.toList();
        if (tiles.isNotEmpty) {
          print(
              "Error loading tiles from Firestore, using Hive: ${tiles.length} tiles");
          return _buildTileList(tiles, user);
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading tiles: ${err.toString()}',
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

  /// Placeholder content for Pro users when no tiles are available
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
            Tooltip(
              message: 'Add a new tile',
              child: ElevatedButton.icon(
                onPressed: () => _showTileForm(context, user, null),
                icon: const Icon(Icons.add),
                label: const Text('Create New Tile'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Content for Free users - greyed out with an "Upgrade to Pro" CTA
  Widget _buildFreeUserContent(UserModel user) {
    return Stack(
      children: [
        // Greyed-out content
        Opacity(
          opacity: 0.5,
          child: Container(
            color: Colors.grey[300],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.grid_view,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Tile Management',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
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
        // CTA overlay
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: 'Unlock tile management features',
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/subscription');
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Upgrade to Pro'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build tile list with options to edit/delete
  Widget _buildTileList(List<TileModel> tiles, UserModel user) {
    // Group tiles by material type
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              _getTileSlateTypeDisplayName(tileSlateType),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(
              '${tilesInGroup.length} tiles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            children: tilesInGroup
                .map((tile) => _buildTileListItem(tile, user))
                .toList(),
          ),
        );
      },
    );
  }

  /// Build individual tile list item
  Widget _buildTileListItem(TileModel tile, UserModel user) {
    final bool isEditable = tile.createdById == user.id ||
        (user.isPro && tile.createdById == 'system');
    final bool isDeletable = tile.createdById == user.id;
    final bool canSubmit = !tile.isPublic ||
        !tile.isApproved; // Show Submit button if not public/approved
    final bool isPending =
        tile.isPublic && !tile.isApproved; // Tile is pending review
    final bool canShowSubmitButton = (user.isPro || user.isAdmin) &&
        tile.createdById == user.id &&
        canSubmit;

    // Debug log to check why Submit button might not be showing
    print('Tile ${tile.name}: canSubmit=$canSubmit, isPending=$isPending, '
        'canShowSubmitButton=$canShowSubmitButton, user.isPro=${user.isPro}, '
        'user.isAdmin=${user.isAdmin}, tile.isPublic=${tile.isPublic}, '
        'tile.isApproved=${tile.isApproved}, tile.createdById=${tile.createdById}, user.id=${user.id}');

    return ListTile(
      title: Text(
        tile.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
            Tooltip(
              message: 'Edit this tile',
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showTileForm(context, user, tile),
              ),
            ),
          if (isDeletable)
            Tooltip(
              message: 'Delete this tile',
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDeleteTile(context, tile),
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          if (canShowSubmitButton) // Show Submit for Pro/Admin user's own tiles
            Tooltip(
              message: isPending
                  ? 'Tile is pending review'
                  : 'Submit for admin review',
              child: IconButton(
                icon: const Icon(Icons.upload),
                onPressed: isPending
                    ? null // Disable if pending review
                    : () => _submitTileForReview(context, tile, user),
                color: isPending
                    ? Colors.grey
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      onTap: () => _showTileDetails(context, tile),
    );
  }

  /// Submit a tile for admin review
  void _submitTileForReview(
      BuildContext context, TileModel tile, UserModel user) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot submit tile offline. Please connect to the internet.'),
        ),
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

      // Update Hive
      final tilesBox = Hive.box<TileModel>('tilesBox');
      await tilesBox.put(updatedTile.id, updatedTile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tile submitted for admin review.'),
          ),
        );
        // Refresh the tile list
        ref.refresh(userTilesProvider(user.id));
        ref.refresh(allAvailableTilesProvider(user.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting tile: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show detailed tile information
  void _showTileDetails(BuildContext context, TileModel tile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tile.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Placeholder for tile image
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
                      : const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
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
                      const Text(
                        'View Data Sheet:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isOnline
                            ? () async {
                                final uri = Uri.tryParse(tile.dataSheet!);
                                if (uri != null) {
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Could not open datasheet. Try opening in browser.'),
                                      ),
                                    );
                                    // Fallback to browser
                                    if (await canLaunchUrl(
                                        Uri.parse('https://www.google.com'))) {
                                      await launchUrl(
                                          Uri.parse('https://www.google.com'),
                                          mode: LaunchMode.externalApplication);
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Invalid datasheet URL.'),
                                    ),
                                  );
                                }
                              }
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Cannot open datasheet offline. Please connect to the internet.'),
                                  ),
                                );
                              },
                        child: const Text('View Data Sheet'),
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

  /// Helper for displaying info rows in the details dialog
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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

  /// Show form to create or edit a tile
  void _showTileForm(
      BuildContext context, UserModel user, TileModel? existingTile) {
    if (!user.isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upgrade to Pro to save and manage tiles.'),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final isEditing = existingTile != null;

    // Form controllers
    final nameController =
        TextEditingController(text: existingTile?.name ?? '');
    final manufacturerController =
        TextEditingController(text: existingTile?.manufacturer ?? '');
    final descriptionController =
        TextEditingController(text: existingTile?.description ?? '');
    final heightController = TextEditingController(
        text: existingTile?.slateTileHeight.toString() ?? '');
    final widthController = TextEditingController(
        text: existingTile?.tileCoverWidth.toString() ?? '');
    final minGaugeController =
        TextEditingController(text: existingTile?.minGauge.toString() ?? '');
    final maxGaugeController =
        TextEditingController(text: existingTile?.maxGauge.toString() ?? '');
    final minSpacingController =
        TextEditingController(text: existingTile?.minSpacing.toString() ?? '');
    final maxSpacingController =
        TextEditingController(text: existingTile?.maxSpacing.toString() ?? '');
    final leftHandTileWidthController = TextEditingController(
      text: existingTile?.leftHandTileWidth?.toString() ?? '0',
    );

    // Current values
    _selectedTileSlateType = existingTile?.materialType ?? TileSlateType.slate;
    bool isCrossBonded = existingTile?.defaultCrossBonded ?? false;

    // Initialize file states
    _imageFile = isEditing && existingTile?.image != null
        ? File(existingTile!.image!)
        : null;
    _dataSheetFile = isEditing && existingTile?.dataSheet != null
        ? File(existingTile!.dataSheet!)
        : null;
    _imageUrl = existingTile?.image;
    _dataSheetUrl = existingTile?.dataSheet;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'Edit Tile' : 'Create New Tile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              minWidth: 300,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Tile Name *',
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TileSlateType>(
                        value: _selectedTileSlateType,
                        decoration: const InputDecoration(
                          labelText: 'Material Type *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: TileSlateType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTileSlateTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedTileSlateType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: manufacturerController,
                        label: 'Manufacturer *',
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Manufacturer is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: heightController,
                        label: 'Height/Length (mm) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Height is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: widthController,
                        label: 'Cover Width (mm) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Width is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: minGaugeController,
                        label: 'Min Gauge (mm) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Min gauge is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: maxGaugeController,
                        label: 'Max Gauge (mm) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Max gauge is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: minSpacingController,
                        label: 'Min Spacing (mm) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Min spacing is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: maxSpacingController,
                        label: 'Max Spacing (mm) *',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Max spacing is required';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Cross Bonded'),
                        value: isCrossBonded,
                        onChanged: (value) {
                          setState(() => isCrossBonded = value);
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                      if (isCrossBonded) ...[
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: leftHandTileWidthController,
                          label: 'Left Hand Tile Width (mm)',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (double.tryParse(value) == null) {
                                return 'Invalid number';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Image upload field
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _imageFile != null
                                  ? 'Image: ${_imageFile!.path.split('/').last}'
                                  : 'No image selected',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (result != null &&
                                  result.files.single.path != null) {
                                setState(() {
                                  _imageFile = File(result.files.single.path!);
                                });
                              }
                            },
                            child: const Text('Upload Image'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Datasheet upload field
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dataSheetFile != null
                                  ? 'DataSheet: ${_dataSheetFile!.path.split('/').last}'
                                  : 'No datasheet selected',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );
                              if (result != null &&
                                  result.files.single.path != null) {
                                setState(() {
                                  _dataSheetFile =
                                      File(result.files.single.path!);
                                });
                              }
                            },
                            child: const Text('Upload DataSheet (PDF)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (!_isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Cannot save tile offline. Please connect to the internet.'),
                      ),
                    );
                    return;
                  }

                  final tileService = ref.read(tileServiceProvider);

                  // Upload image and datasheet if selected
                  if (_imageFile != null) {
                    final storageRef = FirebaseStorage.instance.ref().child(
                        'tiles/${user.id}/${_imageFile!.path.split('/').last}');
                    await storageRef.putFile(_imageFile!);
                    _imageUrl = await storageRef.getDownloadURL();
                    print('Image URL: $_imageUrl'); // Debug log
                  }

                  if (_dataSheetFile != null) {
                    final storageRef = FirebaseStorage.instance.ref().child(
                        'tiles/${user.id}/${_dataSheetFile!.path.split('/').last}');
                    await storageRef.putFile(_dataSheetFile!);
                    _dataSheetUrl = await storageRef.getDownloadURL();
                    print('DataSheet URL: $_dataSheetUrl'); // Debug log
                  }

                  // Create or update the tile
                  final TileModel tileData = isEditing
                      ? existingTile!.copyWith(
                          name: nameController.text,
                          manufacturer: manufacturerController.text,
                          materialType: _selectedTileSlateType!,
                          description: descriptionController.text,
                          slateTileHeight: double.parse(heightController.text),
                          tileCoverWidth: double.parse(widthController.text),
                          minGauge: double.parse(minGaugeController.text),
                          maxGauge: double.parse(maxGaugeController.text),
                          minSpacing: double.parse(minSpacingController.text),
                          maxSpacing: double.parse(maxSpacingController.text),
                          defaultCrossBonded: isCrossBonded,
                          leftHandTileWidth: isCrossBonded &&
                                  leftHandTileWidthController.text.isNotEmpty
                              ? double.parse(leftHandTileWidthController.text)
                              : null,
                          updatedAt: DateTime.now(),
                          image: _imageUrl,
                          dataSheet: _dataSheetUrl,
                        )
                      : TileModel(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameController.text,
                          manufacturer: manufacturerController.text,
                          materialType: _selectedTileSlateType!,
                          description: descriptionController.text,
                          isPublic: false,
                          isApproved: false,
                          createdById: user.id,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                          slateTileHeight: double.parse(heightController.text),
                          tileCoverWidth: double.parse(widthController.text),
                          minGauge: double.parse(minGaugeController.text),
                          maxGauge: double.parse(maxGaugeController.text),
                          minSpacing: double.parse(minSpacingController.text),
                          maxSpacing: double.parse(maxSpacingController.text),
                          defaultCrossBonded: isCrossBonded,
                          leftHandTileWidth: isCrossBonded &&
                                  leftHandTileWidthController.text.isNotEmpty
                              ? double.parse(leftHandTileWidthController.text)
                              : null,
                          image: _imageUrl,
                          dataSheet: _dataSheetUrl,
                        );

                  setState(() => _isLoading = true);

                  if (isEditing) {
                    await tileService.updateTile(tileData);
                  } else {
                    await tileService.createTile(tileData);
                  }

                  // Update Hive
                  final tilesBox = Hive.box<TileModel>('tilesBox');
                  await tilesBox.put(tileData.id, tileData);

                  setState(() => _isLoading = false);

                  if (mounted) {
                    Navigator.of(context).pop();
                    // Force refresh providers
                    ref.refresh(userTilesProvider(user.id));
                    ref.refresh(allAvailableTilesProvider(user.id));
                  }
                }
              },
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build styled text fields for the form
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  /// Confirm dialog before deleting a tile
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
          TextButton(
            onPressed: () async {
              if (!_isOnline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Cannot delete tile offline. Please connect to the internet.'),
                  ),
                );
                return;
              }

              Navigator.of(context).pop();

              final tileService = ref.read(tileServiceProvider);
              final user = ref.read(currentUserProvider).value;

              if (user != null) {
                setState(() => _isLoading = true);
                await tileService.deleteTile(tile.id, user.id);
                // Remove from Hive
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
        ],
      ),
    );
  }

  /// Helper to get a display-friendly name for material types
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
