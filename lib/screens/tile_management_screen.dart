import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/tiles/services/tile_service.dart';

/// Screen for managing tiles - Pro users can view all tiles from the database,
/// while free users can only create and manage their own custom tiles
class TileManagementScreen extends ConsumerStatefulWidget {
  const TileManagementScreen({super.key});

  @override
  ConsumerState<TileManagementScreen> createState() =>
      _TileManagementScreenState();
}

class _TileManagementScreenState extends ConsumerState<TileManagementScreen> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(currentUserProvider);

    // Safety check - redirect if not logged in
    if (authState.userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access this feature'),
        ),
      );
    }

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tile Management'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showTileForm(context, user, null),
                tooltip: 'Add New Tile',
              ),
            ],
          ),
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
        if (tiles.isEmpty) {
          return const Center(
            child: Text('No tiles found. Create your first tile!'),
          );
        }

        return _buildTileList(tiles, user);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Error loading tiles: ${err.toString()}'),
      ),
    );
  }

  /// Content for Free users - can only see and edit their own tiles
  Widget _buildFreeUserContent(UserModel user) {
    // Watch only user's custom tiles
    final tilesAsync = ref.watch(userTilesProvider(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Notice for free users
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.amber.shade100,
          child: const Text(
            'Free users must manually input tile data. Upgrade to Pro to access the complete tile database.',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),

        // User's custom tiles list
        Expanded(
          child: tilesAsync.when(
            data: (tiles) {
              if (tiles.isEmpty) {
                return const Center(
                  child: Text('No custom tiles found. Create your first tile!'),
                );
              }

              return _buildTileList(tiles, user);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Error loading tiles: ${err.toString()}'),
            ),
          ),
        ),
      ],
    );
  }

  /// Build tile list with options to edit/delete
  Widget _buildTileList(List<TileModel> tiles, UserModel user) {
    // Group tiles by material type
    final groupedTiles = <MaterialType, List<TileModel>>{};
    for (final tile in tiles) {
      if (!groupedTiles.containsKey(tile.materialType)) {
        groupedTiles[tile.materialType] = [];
      }
      groupedTiles[tile.materialType]!.add(tile);
    }

    return ListView.builder(
      itemCount: groupedTiles.keys.length,
      itemBuilder: (context, index) {
        final materialType = groupedTiles.keys.elementAt(index);
        final tilesInGroup = groupedTiles[materialType]!;

        return ExpansionTile(
          title: Text(_getMaterialTypeDisplayName(materialType)),
          subtitle: Text('${tilesInGroup.length} tiles'),
          children: tilesInGroup
              .map((tile) => _buildTileListItem(tile, user))
              .toList(),
        );
      },
    );
  }

  /// Build individual tile list item
  Widget _buildTileListItem(TileModel tile, UserModel user) {
    final bool isEditable = tile.createdById == user.id ||
        (user.isPro && tile.createdById == 'system');
    final bool isDeletable = tile.createdById == user.id;

    return ListTile(
      title: Text(tile.name),
      subtitle: Text('${tile.manufacturer} - ${tile.description}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showTileForm(context, user, tile),
              tooltip: 'Edit Tile',
            ),
          if (isDeletable)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteTile(context, tile),
              tooltip: 'Delete Tile',
            ),
        ],
      ),
      onTap: () => _showTileDetails(context, tile),
    );
  }

  /// Show detailed tile information
  void _showTileDetails(BuildContext context, TileModel tile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tile.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Material Type',
                  _getMaterialTypeDisplayName(tile.materialType)),
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Show form to create or edit a tile
  void _showTileForm(
      BuildContext context, UserModel user, TileModel? existingTile) {
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
    MaterialType selectedMaterialType =
        existingTile?.materialType ?? MaterialType.slate;
    bool isCrossBonded = existingTile?.defaultCrossBonded ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Tile' : 'Create New Tile'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Tile Name *'),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    DropdownButtonFormField<MaterialType>(
                      value: selectedMaterialType,
                      decoration:
                          const InputDecoration(labelText: 'Material Type *'),
                      items: MaterialType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getMaterialTypeDisplayName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedMaterialType = value);
                        }
                      },
                    ),
                    TextFormField(
                      controller: manufacturerController,
                      decoration:
                          const InputDecoration(labelText: 'Manufacturer *'),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Manufacturer is required'
                          : null,
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    TextFormField(
                      controller: heightController,
                      decoration: const InputDecoration(
                          labelText: 'Height/Length (mm) *'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Height is required';
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: widthController,
                      decoration: const InputDecoration(
                          labelText: 'Cover Width (mm) *'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Width is required';
                        if (double.tryParse(value!) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: minGaugeController,
                      decoration:
                          const InputDecoration(labelText: 'Min Gauge (mm) *'),
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
                    TextFormField(
                      controller: maxGaugeController,
                      decoration:
                          const InputDecoration(labelText: 'Max Gauge (mm) *'),
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
                    TextFormField(
                      controller: minSpacingController,
                      decoration: const InputDecoration(
                          labelText: 'Min Spacing (mm) *'),
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
                    TextFormField(
                      controller: maxSpacingController,
                      decoration: const InputDecoration(
                          labelText: 'Max Spacing (mm) *'),
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
                    SwitchListTile(
                      title: const Text('Cross Bonded'),
                      value: isCrossBonded,
                      onChanged: (value) {
                        setState(() => isCrossBonded = value);
                      },
                    ),
                    if (isCrossBonded)
                      TextFormField(
                        controller: leftHandTileWidthController,
                        decoration: const InputDecoration(
                            labelText: 'Left Hand Tile Width (mm)'),
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
                  final tileService = ref.read(tileServiceProvider);

                  // Create or update the tile
                  final TileModel tileData = isEditing
                      ? existingTile.copyWith(
                          name: nameController.text,
                          manufacturer: manufacturerController.text,
                          materialType: selectedMaterialType,
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
                        )
                      : TileModel(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: nameController.text,
                          manufacturer: manufacturerController.text,
                          materialType: selectedMaterialType,
                          description: descriptionController.text,
                          isPublic:
                              false, // User-created tiles are private by default
                          isApproved: false,
                          createdById: user.id,
                          createdAt: DateTime.now(),
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
                        );

                  setState(() => _isLoading = true);

                  bool success;
                  if (isEditing) {
                    success = await tileService.updateTile(tileData);
                  } else {
                    success = await tileService.saveTile(tileData);
                  }

                  setState(() => _isLoading = false);

                  if (success && mounted) {
                    Navigator.of(context).pop();
                    // Force refresh providers
                    ref.refresh(userTilesProvider(user.id));
                    if (user.isPro) {
                      ref.refresh(allAvailableTilesProvider(user.id));
                    }
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

  /// Confirm dialog before deleting a tile
  void _confirmDeleteTile(BuildContext context, TileModel tile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tile?'),
        content: Text(
            'Are you sure you want to delete "${tile.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              final tileService = ref.read(tileServiceProvider);
              final user = ref.read(authProvider).user;

              if (user != null) {
                setState(() => _isLoading = true);
                final success = await tileService.deleteTile(tile.id);
                setState(() => _isLoading = false);

                if (success) {
                  ref.refresh(userTilesProvider(user.id));
                  if (user.isPro) {
                    ref.refresh(allAvailableTilesProvider(user.id));
                  }
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
  String _getMaterialTypeDisplayName(MaterialType type) {
    switch (type) {
      case MaterialType.slate:
        return 'Natural Slate';
      case MaterialType.fibreCementSlate:
        return 'Fibre Cement Slate';
      case MaterialType.interlockingTile:
        return 'Interlocking Tile';
      case MaterialType.plainTile:
        return 'Plain Tile';
      case MaterialType.concreteTile:
        return 'Concrete Tile';
      case MaterialType.pantile:
        return 'Pantile';
      case MaterialType.unknown:
        return 'Unknown Type';
    }
  }
}
