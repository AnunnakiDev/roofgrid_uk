import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';
import 'package:roofgrid_uk/widgets/custom_expansion_tile.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TileSelectorWidget extends ConsumerStatefulWidget {
  final List<TileModel> tiles;
  final UserModel user;
  final Function(TileModel) onTileSelected;
  final bool showAddTileButton;

  const TileSelectorWidget({
    super.key,
    required this.tiles,
    required this.user,
    required this.onTileSelected,
    this.showAddTileButton = true,
  });

  @override
  ConsumerState<TileSelectorWidget> createState() => _TileSelectorWidgetState();
}

class _TileSelectorWidgetState extends ConsumerState<TileSelectorWidget> {
  String _searchQuery = '';
  String _searchField = 'Name'; // Default search field
  TileSlateType? _selectedFilter;
  bool _isOnline = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
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

  void _filterTiles(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  String _getTileSlateTypeDisplayName(TileSlateType type) {
    switch (type) {
      case TileSlateType.slate:
        return 'Slate';
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

  Widget _getPlaceholderImage(TileSlateType type) {
    String placeholderImagePath;
    switch (type) {
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

  @override
  Widget build(BuildContext context) {
    final filteredTiles = widget.tiles.where((tile) {
      final matchesSearch = _searchField == 'Name'
          ? tile.name.toLowerCase().contains(_searchQuery.toLowerCase())
          : _searchField == 'Manufacturer'
              ? tile.manufacturer
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())
              : tile.materialTypeString
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == null || tile.materialType == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeaderWidget(
            title: widget.user.isPro
                ? 'Select Tile'
                : 'Manual Tile Input (Free User)'),
        const SizedBox(height: 16),
        _buildSearchBar(),
        const SizedBox(height: 16),
        _buildFilterChips(),
        const SizedBox(height: 16),
        if (widget.showAddTileButton && widget.user.isPro) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: AddTileWidget(
                      userRole: widget.user.role,
                      userId: widget.user.id,
                      onTileCreated: (tile) {
                        widget.onTileSelected(tile);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              child: const Text('Add New Tile'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: filteredTiles.isEmpty
              ? const Center(child: Text('No tiles found'))
              : ListView.builder(
                  itemCount: filteredTiles.length,
                  itemBuilder: (context, index) {
                    final tile = filteredTiles[index];
                    return _buildTileCard(tile, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: isSmallScreen
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
                  items: ['Name', 'Manufacturer', 'Material Type']
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
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
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
                  items: ['Name', 'Manufacturer', 'Material Type']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                ),
              ],
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

  Widget _buildTileCard(TileModel tile, int index) {
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
        animationIndex: index,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.grey[200],
          ),
          child: (!_isOnline || tile.image == null || tile.image!.isEmpty)
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _getPlaceholderImage(tile.materialType),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    tile.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _getPlaceholderImage(tile.materialType),
                  ),
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
            if (widget.user.isPro)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: AddTileWidget(
                        userRole: widget.user.role,
                        userId: widget.user.id,
                        tile: tile,
                        onTileCreated: (updatedTile) {
                          widget.onTileSelected(updatedTile);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                tooltip: 'Edit Tile',
              ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => widget.onTileSelected(tile),
              child: const Text('Select'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tile Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _infoRow('Material Type',
                    _getTileSlateTypeDisplayName(tile.materialType)),
                _infoRow('Manufacturer', tile.manufacturer),
                _infoRow('Description', tile.description),
                Row(
                  children: [
                    Expanded(
                        child: _infoRow(
                            'Height/Length', '${tile.slateTileHeight} mm')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoRow(
                            'Cover Width', '${tile.tileCoverWidth} mm')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child: _infoRow('Min Gauge', '${tile.minGauge} mm')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoRow('Max Gauge', '${tile.maxGauge} mm')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                        child:
                            _infoRow('Min Spacing', '${tile.minSpacing} mm')),
                    const SizedBox(width: 8),
                    Expanded(
                        child:
                            _infoRow('Max Spacing', '${tile.maxSpacing} mm')),
                  ],
                ),
                _infoRow(
                    'Cross Bonded', tile.defaultCrossBonded ? 'Yes' : 'No'),
                if (tile.leftHandTileWidth != null &&
                    tile.leftHandTileWidth! > 0)
                  _infoRow(
                      'Left Hand Tile Width', '${tile.leftHandTileWidth} mm'),
                if (tile.dataSheet != null && tile.dataSheet!.isNotEmpty)
                  _infoRow('Data Sheet', tile.dataSheet!),
              ],
            ),
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
