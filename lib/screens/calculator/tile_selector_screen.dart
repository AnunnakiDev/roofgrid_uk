import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/providers/tile_provider.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class TileSelectorScreen extends ConsumerStatefulWidget {
  const TileSelectorScreen({super.key});

  @override
  ConsumerState<TileSelectorScreen> createState() => _TileSelectorScreenState();
}

class _TileSelectorScreenState extends ConsumerState<TileSelectorScreen> {
  String _searchQuery = '';
  TileSlateType? _selectedFilter;
  bool _isLoading = false;
  File? _imageFile;
  File? _dataSheetFile;
  String? _imageUrl;
  String? _dataSheetUrl;
  bool _isOnline = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        ref.invalidate(
            allAvailableTilesProvider(ref.read(currentUserProvider).value!.id));
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final extra =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final TileModel? initialTile = extra?['tile'] as TileModel?;

    return Scaffold(
      appBar: AppBar(
        title: Text(initialTile != null ? 'Edit Tile' : 'Select Tile'),
        actions: [
          if (userAsync.value?.isPro == true && initialTile == null)
            Semantics(
              label: 'Create new tile',
              child: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showEditTileDialog(context, null),
                tooltip: 'Create New Tile',
              ),
            ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text('User not found. Please sign in again.'));
          }
          return user.isPro
              ? _buildProUserContent(user, initialTile)
              : _buildFreeUserContent(user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ),
    );
  }

  Widget _buildProUserContent(UserModel user, TileModel? initialTile) {
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
        final filteredTiles = tiles.where((tile) {
          final matchesSearch =
              tile.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  tile.manufacturer
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
          final matchesFilter =
              _selectedFilter == null || tile.materialType == _selectedFilter;
          return matchesSearch && matchesFilter;
        }).toList();
        if (initialTile != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEditTileDialog(context, initialTile);
          });
        }
        return Column(
          children: [
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTiles.length,
                itemBuilder: (context, index) {
                  final tile = filteredTiles[index];
                  return _buildTileCard(tile, user);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        final tilesBox = Hive.box<TileModel>('tilesBox');
        final tiles = tilesBox.values.toList();
        if (tiles.isNotEmpty) {
          return _buildTileList(tiles, user);
        }
        return Center(
          child: Text('Error loading tiles: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Semantics(
        label: 'Search tiles',
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search by name or manufacturer',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    tooltip: 'Clear search',
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide:
                  BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TileSlateType.values.map<Widget>((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Semantics(
                label: 'Filter by ${_getTileSlateTypeDisplayName(type)}',
                child: FilterChip(
                  label: Text(_getTileSlateTypeDisplayName(type)),
                  selected: _selectedFilter == type,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? type : null;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: _selectedFilter == type
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTileList(List<TileModel> tiles, UserModel user) {
    final filteredTiles = tiles.where((tile) {
      final matchesSearch = tile.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          tile.manufacturer.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == null || tile.materialType == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
    return ListView.builder(
      itemCount: filteredTiles.length,
      itemBuilder: (context, index) {
        final tile = filteredTiles[index];
        return _buildTileCard(tile, user);
      },
    );
  }

  Widget _buildTileCard(TileModel tile, UserModel user) {
    String placeholderImagePath;
    switch (tile.materialType) {
      case TileSlateType.slate:
        placeholderImagePath = 'assets/images/tiles/natural_slate';
        break;
      case TileSlateType.fibreCementSlate:
        placeholderImagePath = 'assets/images/tiles/fibre_cement_slate';
        break;
      case TileSlateType.interlockingTile:
        placeholderImagePath = 'assets/images/tiles/interlocking_tile';
        break;
      case TileSlateType.plainTile:
        placeholderImagePath = 'assets/images/tiles/plain_tile';
        break;
      case TileSlateType.concreteTile:
        placeholderImagePath = 'assets/images/tiles/concrete_tile';
        break;
      case TileSlateType.pantile:
        placeholderImagePath = 'assets/images/tiles/pantile';
        break;
      case TileSlateType.unknown:
      default:
        placeholderImagePath = 'assets/images/tiles/unknown_type';
        break;
    }

    // Try PNG first, then JPG
    Widget placeholderImage() {
      try {
        return Image.asset(
          '$placeholderImagePath.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              '$placeholderImagePath.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/tiles/unknown_type.png',
                  fit: BoxFit.cover,
                );
              },
            );
          },
        );
      } catch (e) {
        return Image.asset(
          'assets/images/tiles/unknown_type.png',
          fit: BoxFit.cover,
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.grey[200],
          ),
          child: tile.image != null && tile.image!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    tile.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        placeholderImage(),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: placeholderImage(),
                ),
        ),
        title: Text(
          tile.name,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Material Type: ${_getTileSlateTypeDisplayName(tile.materialType)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Max Gauge: ${tile.maxGauge} mm | Cover Width: ${tile.tileCoverWidth} mm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'Edit tile ${tile.name}',
              child: ElevatedButton(
                onPressed: () => _showEditTileDialog(context, tile),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: Theme.of(context).textTheme.labelMedium,
                ),
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              label: 'Select tile ${tile.name}',
              child: ElevatedButton(
                onPressed: () {
                  ref.read(calculatorProvider.notifier).setTile(tile);
                  context.go('/calculator/main');
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: Theme.of(context).textTheme.labelMedium,
                ),
                child: const Text('Select'),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _infoRow('Material Type',
                    _getTileSlateTypeDisplayName(tile.materialType)),
                _infoRow('Manufacturer', tile.manufacturer),
                _infoRow('Description', tile.description),
                _infoRow('Height/Length', '${tile.slateTileHeight} mm'),
                _infoRow('Cover Width', '${tile.tileCoverWidth} mm'),
                _infoRow('Min Gauge', '${tile.minGauge} mm'),
                _infoRow('Max Gauge', '${tile.maxGauge} mm'),
                _infoRow('Min Spacing', '${tile.minSpacing} mm'),
                _infoRow('Max Spacing', '${tile.maxSpacing} mm'),
                _infoRow(
                    'Cross Bonded', tile.defaultCrossBonded ? 'Yes' : 'No'),
                if (tile.leftHandTileWidth != null &&
                    tile.leftHandTileWidth! > 0)
                  _infoRow(
                      'Left Hand Tile Width', '${tile.leftHandTileWidth} mm'),
                if (tile.dataSheet != null && tile.dataSheet!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Data Sheet',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Semantics(
                          label: 'View data sheet for ${tile.name}',
                          child: TextButton(
                            onPressed: () => _launchURL(tile.dataSheet!),
                            child: const Text('View'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeUserContent(UserModel user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manual Tile Input (Free User)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildManualTileInputs(user),
          const SizedBox(height: 24),
          _buildUpgradeToProBox(),
        ],
      ),
    );
  }

  Widget _buildManualTileInputs(UserModel user) {
    final formKey = GlobalKey<FormState>();
    final heightController = TextEditingController();
    final widthController = TextEditingController();
    final minGaugeController = TextEditingController();
    final maxGaugeController = TextEditingController();
    final minSpacingController = TextEditingController();
    final maxSpacingController = TextEditingController();

    return Form(
      key: formKey,
      child: Column(
        children: [
          Semantics(
            label: 'Tile Height or Length in millimeters',
            child: TextFormField(
              controller: heightController,
              decoration: const InputDecoration(
                labelText: 'Tile Height/Length (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Tile Cover Width in millimeters',
            child: TextFormField(
              controller: widthController,
              decoration: const InputDecoration(
                labelText: 'Tile Cover Width (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Minimum Gauge in millimeters',
            child: TextFormField(
              controller: minGaugeController,
              decoration: const InputDecoration(
                labelText: 'Min Gauge (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Maximum Gauge in millimeters',
            child: TextFormField(
              controller: maxGaugeController,
              decoration: const InputDecoration(
                labelText: 'Max Gauge (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Minimum Spacing in millimeters',
            child: TextFormField(
              controller: minSpacingController,
              decoration: const InputDecoration(
                labelText: 'Min Spacing (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Maximum Spacing in millimeters',
            child: TextFormField(
              controller: maxSpacingController,
              decoration: const InputDecoration(
                labelText: 'Max Spacing (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            label: 'Confirm tile specifications',
            child: ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final tempTile = TileModel(
                    id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    name: 'Temporary Tile',
                    manufacturer: 'Manual Input',
                    materialType: TileSlateType.unknown,
                    description: 'Manually entered tile specifications',
                    isPublic: false,
                    isApproved: false,
                    createdById: user.id,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                    slateTileHeight:
                        double.tryParse(heightController.text) ?? 0,
                    tileCoverWidth: double.tryParse(widthController.text) ?? 0,
                    minGauge: double.tryParse(minGaugeController.text) ?? 0,
                    maxGauge: double.tryParse(maxGaugeController.text) ?? 0,
                    minSpacing: double.tryParse(minSpacingController.text) ?? 0,
                    maxSpacing: double.tryParse(maxSpacingController.text) ?? 0,
                    defaultCrossBonded: false,
                  );
                  ref.read(calculatorProvider.notifier).setTile(tempTile);
                  context.go('/calculator/main');
                }
              },
              child: const Text('Confirm'),
            ),
          ),
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

  void _showEditTileDialog(BuildContext context, TileModel? tile) {
    final isEditing = tile != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: tile?.name ?? '');
    final manufacturerController =
        TextEditingController(text: tile?.manufacturer ?? '');
    final descriptionController =
        TextEditingController(text: tile?.description ?? '');
    final heightController =
        TextEditingController(text: tile?.slateTileHeight.toString() ?? '');
    final widthController =
        TextEditingController(text: tile?.tileCoverWidth.toString() ?? '');
    final minGaugeController =
        TextEditingController(text: tile?.minGauge.toString() ?? '');
    final maxGaugeController =
        TextEditingController(text: tile?.maxGauge.toString() ?? '');
    final minSpacingController =
        TextEditingController(text: tile?.minSpacing.toString() ?? '');
    final maxSpacingController =
        TextEditingController(text: tile?.maxSpacing.toString() ?? '');
    final leftHandTileWidthController =
        TextEditingController(text: tile?.leftHandTileWidth?.toString() ?? '');
    TileSlateType materialType = tile?.materialType ?? TileSlateType.slate;
    bool crossBonded = tile?.defaultCrossBonded ?? false;
    _imageFile = null;
    _dataSheetFile = null;
    _imageUrl = tile?.image;
    _dataSheetUrl = tile?.dataSheet;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing ? 'Edit Tile' : 'Create New Tile',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              minWidth: 300,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Tile Name',
                      child: TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tile Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Name is required' : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Material Type',
                      child: DropdownButtonFormField<TileSlateType>(
                        value: materialType,
                        decoration: const InputDecoration(
                          labelText: 'Material Type *',
                          border: OutlineInputBorder(),
                        ),
                        items: TileSlateType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTileSlateTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => materialType = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Manufacturer',
                      child: TextFormField(
                        controller: manufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturer *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Manufacturer is required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Description',
                      child: TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Height or Length in millimeters',
                      child: TextFormField(
                        controller: heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height/Length (mm) *',
                          border: OutlineInputBorder(),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Cover Width in millimeters',
                      child: TextFormField(
                        controller: widthController,
                        decoration: const InputDecoration(
                          labelText: 'Cover Width (mm) *',
                          border: OutlineInputBorder(),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Minimum Gauge in millimeters',
                      child: TextFormField(
                        controller: minGaugeController,
                        decoration: const InputDecoration(
                          labelText: 'Min Gauge (mm) *',
                          border: OutlineInputBorder(),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Maximum Gauge in millimeters',
                      child: TextFormField(
                        controller: maxGaugeController,
                        decoration: const InputDecoration(
                          labelText: 'Max Gauge (mm) *',
                          border: OutlineInputBorder(),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Minimum Spacing in millimeters',
                      child: TextFormField(
                        controller: minSpacingController,
                        decoration: const InputDecoration(
                          labelText: 'Min Spacing (mm) *',
                          border: OutlineInputBorder(),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Maximum Spacing in millimeters',
                      child: TextFormField(
                        controller: maxSpacingController,
                        decoration: const InputDecoration(
                          labelText: 'Max Spacing (mm) *',
                          border: OutlineInputBorder(),
                        ),
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
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Cross Bonded',
                      child: CheckboxListTile(
                        title: const Text('Cross Bonded'),
                        value: crossBonded,
                        onChanged: (value) {
                          setState(() {
                            crossBonded = value ?? false;
                          });
                        },
                      ),
                    ),
                    if (crossBonded) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        label: 'Left Hand Tile Width in millimeters',
                        child: TextFormField(
                          controller: leftHandTileWidthController,
                          decoration: const InputDecoration(
                            labelText: 'Left Hand Tile Width (mm)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _imageFile != null
                                ? 'Image: ${_imageFile!.path.split('/').last}'
                                : _imageUrl != null
                                    ? 'Image: ${_imageUrl!.split('/').last}'
                                    : 'No image selected',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Semantics(
                          label: 'Upload tile image',
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await FilePicker.platform
                                  .pickFiles(type: FileType.image);
                              if (result != null &&
                                  result.files.single.path != null) {
                                setState(() {
                                  _imageFile = File(result.files.single.path!);
                                });
                              }
                            },
                            child: const Text('Upload Image'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _dataSheetFile != null
                                ? 'DataSheet: ${_dataSheetFile!.path.split('/').last}'
                                : _dataSheetUrl != null
                                    ? 'DataSheet: ${_dataSheetUrl!.split('/').last}'
                                    : 'No datasheet selected',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Semantics(
                          label: 'Upload tile datasheet',
                          child: ElevatedButton(
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            Semantics(
              label: isEditing ? 'Update tile' : 'Create tile',
              child: TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!_isOnline) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Cannot save tile offline. Please connect to the internet.')),
                      );
                      return;
                    }
                    setState(() => _isLoading = true);
                    try {
                      final tileService = ref.read(tileServiceProvider);
                      final user = ref.read(currentUserProvider).value!;
                      if (_imageFile != null) {
                        final storageRef = FirebaseStorage.instance.ref().child(
                            'tiles/${user.id}/${_imageFile!.path.split('/').last}');
                        await storageRef.putFile(_imageFile!);
                        _imageUrl = await storageRef.getDownloadURL();
                      }
                      if (_dataSheetFile != null) {
                        final storageRef = FirebaseStorage.instance.ref().child(
                            'tiles/${user.id}/${_dataSheetFile!.path.split('/').last}');
                        await storageRef.putFile(_dataSheetFile!);
                        _dataSheetUrl = await storageRef.getDownloadURL();
                      }
                      final newTile = TileModel(
                        id: isEditing
                            ? tile.id
                            : 'personal_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text,
                        manufacturer: manufacturerController.text,
                        description: descriptionController.text,
                        materialType: materialType,
                        slateTileHeight: double.parse(heightController.text),
                        tileCoverWidth: double.parse(widthController.text),
                        minGauge: double.parse(minGaugeController.text),
                        maxGauge: double.parse(maxGaugeController.text),
                        minSpacing: double.parse(minSpacingController.text),
                        maxSpacing: double.parse(maxSpacingController.text),
                        defaultCrossBonded: crossBonded,
                        leftHandTileWidth: crossBonded &&
                                leftHandTileWidthController.text.isNotEmpty
                            ? double.parse(leftHandTileWidthController.text)
                            : null,
                        isPublic: isEditing ? tile.isPublic : false,
                        isApproved: isEditing ? tile.isApproved : false,
                        createdById: user.id,
                        createdAt: isEditing ? tile.createdAt : DateTime.now(),
                        updatedAt: DateTime.now(),
                        image: _imageUrl,
                        dataSheet: _dataSheetUrl,
                      );
                      if (isEditing) {
                        await tileService.updateTile(newTile);
                      } else {
                        await tileService.createTile(newTile);
                      }
                      final tilesBox = Hive.box<TileModel>('tilesBox');
                      await tilesBox.put(newTile.id, newTile);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                isEditing ? 'Tile updated' : 'Tile created')),
                      );
                      ref.invalidate(allAvailableTilesProvider(user.id));
                      Navigator.pop(context);
                      context.go('/tiles');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving tile: $e')),
                      );
                    } finally {
                      setState(() => _isLoading = false);
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
            ),
          ],
        ),
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

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open URL')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
    }
  }
}
