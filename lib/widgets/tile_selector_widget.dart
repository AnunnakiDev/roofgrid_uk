import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/widgets/add_tile_widget.dart';
import 'package:roofgrid_uk/widgets/custom_expansion_tile.dart';
import 'package:roofgrid_uk/widgets/header_widget.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/utils/tile_access.dart';
import 'package:roofgrid_uk/utils/tile_image_utils.dart';

enum TileSelectorDensity { standard, wizard }

class TileSelectorWidget extends ConsumerStatefulWidget {
  final List<TileModel> tiles;
  final UserModel user;
  final Function(TileModel) onTileSelected;
  final bool showAddTileButton;
  final bool embeddedInScrollView;
  final bool showSectionHeaders;
  final TileSelectorDensity density;

  const TileSelectorWidget({
    super.key,
    required this.tiles,
    required this.user,
    required this.onTileSelected,
    this.showAddTileButton = true,
    this.embeddedInScrollView = false,
    this.showSectionHeaders = true,
    this.density = TileSelectorDensity.standard,
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
    final online = await isDeviceOnline();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
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

  void _openAddTileDialog() {
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
  }

  bool get _isWizard => widget.density == TileSelectorDensity.wizard;

  List<Widget> _buildTileSections({
    required List<TileModel> filteredTiles,
    required bool effectiveIsPro,
  }) {
    final defaultTiles = partitionDefaultTiles(filteredTiles);
    final personalTiles = partitionPersonalTiles(filteredTiles, widget.user.id);
    final showHeaders = widget.showSectionHeaders &&
        defaultTiles.isNotEmpty &&
        personalTiles.isNotEmpty;

    final sections = <Widget>[];

    void addSection(String title, List<TileModel> sectionTiles) {
      if (sectionTiles.isEmpty) return;
      sections.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, _isWizard ? 4 : 8, 16, 4),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      for (var i = 0; i < sectionTiles.length; i++) {
        sections.add(
          _isWizard
              ? _buildWizardTileRow(
                  sectionTiles[i],
                  effectiveIsPro: effectiveIsPro,
                )
              : _buildTileCard(
                  sectionTiles[i],
                  i,
                  effectiveIsPro: effectiveIsPro,
                ),
        );
      }
    }

    if (showHeaders) {
      addSection('Default tiles', defaultTiles);
      addSection('My tiles', personalTiles);
    } else {
      for (var i = 0; i < filteredTiles.length; i++) {
        sections.add(
          _isWizard
              ? _buildWizardTileRow(
                  filteredTiles[i],
                  effectiveIsPro: effectiveIsPro,
                )
              : _buildTileCard(
                  filteredTiles[i],
                  i,
                  effectiveIsPro: effectiveIsPro,
                ),
        );
      }
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIsPro = ref.watch(effectiveIsProProvider);
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

    final gap = _isWizard ? 8.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:
          widget.embeddedInScrollView ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (!_isWizard)
          HeaderWidget(
            title: effectiveIsPro || widget.user.isAdmin
                ? 'Select Tile'
                : 'Manual Tile Input (Free User)',
          ),
        if (!_isWizard) SizedBox(height: gap),
        _isWizard ? _buildWizardSearchBar() : _buildSearchBar(),
        SizedBox(height: gap),
        if (!_isWizard) ...[
          _buildFilterChips(),
          SizedBox(height: gap),
        ],
        if (widget.showAddTileButton &&
            canAddTilesInList(
              user: widget.user,
              effectiveIsPro: effectiveIsPro,
            )) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isWizard
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openAddTileDialog,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add tile'),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _openAddTileDialog,
                    child: const Text('Add New Tile'),
                  ),
          ),
          SizedBox(height: gap),
        ],
        if (widget.embeddedInScrollView)
          filteredTiles.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No tiles found')),
                )
              : ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _buildTileSections(
                    filteredTiles: filteredTiles,
                    effectiveIsPro: effectiveIsPro,
                  ),
                )
        else
          Expanded(
            child: filteredTiles.isEmpty
                ? const Center(child: Text('No tiles found'))
                : ListView(
                    children: _buildTileSections(
                      filteredTiles: filteredTiles,
                      effectiveIsPro: effectiveIsPro,
                    ),
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

  Widget _buildWizardSearchBar() {
    final filterLabel = _selectedFilter == null
        ? 'All types'
        : _getTileSlateTypeDisplayName(_selectedFilter!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterTiles,
              decoration: InputDecoration(
                hintText: 'Search by $_searchField',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
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
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _searchField,
              isDense: true,
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
                  child: Text(value, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ),
          Tooltip(
            message: 'Filter: $filterLabel',
            child: PopupMenuButton<TileSlateType?>(
              tooltip: '',
              padding: EdgeInsets.zero,
              icon: Badge(
                isLabelVisible: _selectedFilter != null,
                smallSize: 8,
                child: const Icon(Icons.filter_list, size: 20),
              ),
              onSelected: (type) {
                setState(() {
                  _selectedFilter = type;
                });
              },
              itemBuilder: (context) => [
                CheckedPopupMenuItem<TileSlateType?>(
                  value: null,
                  checked: _selectedFilter == null,
                  child: const Text('All types'),
                ),
                ...TileSlateType.values.map(
                  (type) => CheckedPopupMenuItem<TileSlateType?>(
                    value: type,
                    checked: _selectedFilter == type,
                    child: Text(_getTileSlateTypeDisplayName(type)),
                  ),
                ),
              ],
            ),
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
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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

  Widget _buildWizardTileRow(
    TileModel tile, {
    required bool effectiveIsPro,
  }) {
    final canEdit = canEditTileInList(
      tile: tile,
      user: widget.user,
      effectiveIsPro: effectiveIsPro,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTileSelected(tile),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            minVerticalPadding: 0,
            leading: SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: (!_isOnline && !isBundledTileImage(tile.image))
                    ? _getPlaceholderImage(tile.materialType)
                    : buildTilePreviewImage(
                        image: tile.image,
                        materialType: tile.materialType,
                        placeholderBuilder: _getPlaceholderImage,
                        width: 40,
                        height: 40,
                        borderRadius: BorderRadius.circular(6),
                      ),
              ),
            ),
            title: Text(
              tile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${tile.materialTypeString} · ${tile.manufacturer}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
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
                    tooltip: 'Edit tile',
                  ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _showTileDetailsSheet(tile),
                  tooltip: 'Tile details',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTileDetailsSheet(TileModel tile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tile.name,
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
                        'Height/Length',
                        '${tile.slateTileHeight} mm',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoRow(
                        'Cover Width',
                        '${tile.tileCoverWidth} mm',
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _infoRow('Min Gauge', '${tile.minGauge} mm'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoRow('Max Gauge', '${tile.maxGauge} mm'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _infoRow('Min Spacing', '${tile.minSpacing} mm'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoRow('Max Spacing', '${tile.maxSpacing} mm'),
                    ),
                  ],
                ),
                _infoRow(
                  'Cross Bonded',
                  tile.defaultCrossBonded ? 'Yes' : 'No',
                ),
                if (tile.leftHandTileWidth != null &&
                    tile.leftHandTileWidth! > 0)
                  _infoRow(
                    'Left Hand Tile Width',
                    '${tile.leftHandTileWidth} mm',
                  ),
                if (tile.dataSheet != null && tile.dataSheet!.isNotEmpty)
                  _infoRow('Data Sheet', tile.dataSheet!),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    widget.onTileSelected(tile);
                  },
                  child: const Text('Select tile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTileCard(
    TileModel tile,
    int index, {
    required bool effectiveIsPro,
  }) {
    final canEdit = canEditTileInList(
      tile: tile,
      user: widget.user,
      effectiveIsPro: effectiveIsPro,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.3),
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
          child: (!_isOnline && !isBundledTileImage(tile.image))
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: _getPlaceholderImage(tile.materialType),
                )
              : buildTilePreviewImage(
                  image: tile.image,
                  materialType: tile.materialType,
                  placeholderBuilder: _getPlaceholderImage,
                  width: 50,
                  height: 50,
                  borderRadius: BorderRadius.circular(8.0),
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
            if (canEdit)
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
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
              child: const Text('Select'),
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
