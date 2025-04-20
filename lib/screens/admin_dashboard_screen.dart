import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final List<String> _pageTitles = ['Home', 'Stats', 'Tiles', 'Users'];

  // Stats data
  int _totalUsers = 0;
  int _totalTiles = 0;
  int _totalCalculations = 0;
  int _onlineUsers = 0;
  bool _isLoadingStats = true;

  // Tile management data
  List<TileModel> _defaultTiles = [];
  List<Map<String, dynamic>> _pendingTiles = [];
  bool _isLoadingTiles = true;

  // User management data
  List<UserModel> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchTiles();
    _fetchUsers();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoadingStats = true;
    });
    try {
      // Total Users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _totalUsers = usersSnapshot.docs.length;

      // Total Tiles (public and approved)
      final tilesSnapshot = await FirebaseFirestore.instance
          .collection('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .get();
      _totalTiles = tilesSnapshot.docs.length;

      // Total Calculations (assumed 'calculations' collection)
      try {
        final calculationsSnapshot =
            await FirebaseFirestore.instance.collection('calculations').get();
        _totalCalculations = calculationsSnapshot.docs.length;
      } catch (e) {
        _totalCalculations = -1; // Indicate collection doesn't exist
      }

      // Current Online Users (assumed 'sessions' collection with TTL)
      try {
        final onlineSnapshot = await FirebaseFirestore.instance
            .collection('sessions')
            .where('lastActive',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(minutes: 5))))
            .get();
        _onlineUsers = onlineSnapshot.docs.length;
      } catch (e) {
        _onlineUsers = -1; // Indicate collection doesn't exist
      }

      setState(() {
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    }
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

      // Fetch pending user-submitted tiles
      final pendingTilesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('tiles')
          .where('isPublic', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .get();
      _pendingTiles = pendingTilesSnapshot.docs.map((doc) {
        return {
          'tile': TileModel.fromFirestore(doc),
          'userId': doc.reference.parent.parent?.id,
        };
      }).toList();

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

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _users = usersSnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.role != UserRole.admin) // Exclude admins
          .toList();

      setState(() {
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              // Router will handle navigation
            },
            tooltip: 'Sign out',
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomePage(),
          _buildStatsPage(),
          _buildTilesPage(),
          _buildUsersPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            context.go('/home'); // Navigate to Home page
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Admin Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Stats',
            tooltip: 'App Statistics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_4x4_outlined),
            activeIcon: Icon(Icons.grid_4x4),
            label: 'Tiles',
            tooltip: 'Manage Tiles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outlined),
            activeIcon: Icon(Icons.people),
            label: 'Users',
            tooltip: 'Manage Users',
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return const Center(
      child: Text(
        'Navigate to Home to manage your personal tiles',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildStatsPage() {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    // Data for the bar chart
    final List<ChartData> chartData = [
      ChartData('Users', _totalUsers),
      ChartData('Tiles', _totalTiles),
      if (_totalCalculations != -1)
        ChartData('Calculations', _totalCalculations),
      if (_onlineUsers != -1) ChartData('Online', _onlineUsers),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Admin dashboard statistics',
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Text(
                'Admin Dashboard: Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryCard('Total Users', _totalUsers.toString()),
              _buildSummaryCard(
                  'Online Users',
                  _onlineUsers == -1
                      ? 'Not Available'
                      : _onlineUsers.toString()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryCard('Total Tiles', _totalTiles.toString()),
              _buildSummaryCard(
                  'Total Calculations',
                  _totalCalculations == -1
                      ? 'Not Available'
                      : _totalCalculations.toString()),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Usage Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SfCartesianChart(
                    primaryXAxis: const CategoryAxis(),
                    series: <CartesianSeries<ChartData, String>>[
                      ColumnSeries<ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.label,
                        yValueMapper: (ChartData data, _) => data.value,
                        color: Theme.of(context).colorScheme.primary,
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTilesPage() {
    if (_isLoadingTiles) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Admin tile management',
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Text(
                'Admin Dashboard: Tile Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Default Tiles',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Semantics(
                label: 'Import tiles via CSV',
                child: ElevatedButton.icon(
                  onPressed: _importTilesFromCSV,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import CSV'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _defaultTiles.isEmpty
              ? const Center(child: Text('No default tiles available'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _defaultTiles.length,
                  itemBuilder: (context, index) {
                    final tile = _defaultTiles[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(tile.name),
                        subtitle: Text(
                            '${tile.materialTypeString} | ${tile.manufacturer}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editTile(tile),
                              tooltip: 'Edit Tile',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTile(tile.id),
                              tooltip: 'Delete Tile',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24),
          const Text(
            'Pending Approvals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _pendingTiles.isEmpty
              ? const Center(child: Text('No pending tiles for approval'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pendingTiles.length,
                  itemBuilder: (context, index) {
                    final tileData = _pendingTiles[index];
                    final tile = tileData['tile'] as TileModel;
                    final userId = tileData['userId'] as String;
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(tile.name),
                        subtitle: Text(
                            '${tile.materialTypeString} | ${tile.manufacturer} | Submitted by User: $userId'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveTile(tile, userId),
                              tooltip: 'Approve Tile',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _denyTile(tile, userId),
                              tooltip: 'Deny Tile',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
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

  Future<void> _editTile(TileModel tile) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: tile.name);
    final manufacturerController =
        TextEditingController(text: tile.manufacturer);
    final descriptionController = TextEditingController(text: tile.description);
    final heightController =
        TextEditingController(text: tile.slateTileHeight.toString());
    final widthController =
        TextEditingController(text: tile.tileCoverWidth.toString());
    final minGaugeController =
        TextEditingController(text: tile.minGauge.toString());
    final maxGaugeController =
        TextEditingController(text: tile.maxGauge.toString());
    final minSpacingController =
        TextEditingController(text: tile.minSpacing.toString());
    final maxSpacingController =
        TextEditingController(text: tile.maxSpacing.toString());
    final leftHandTileWidthController =
        TextEditingController(text: tile.leftHandTileWidth?.toString() ?? '');
    TileSlateType materialType = tile.materialType;
    bool crossBonded = tile.defaultCrossBonded;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Tile'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tile Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TileSlateType>(
                    value: materialType,
                    decoration: const InputDecoration(
                      labelText: 'Material Type *',
                      border: OutlineInputBorder(),
                    ),
                    items: TileSlateType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => materialType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: manufacturerController,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Manufacturer is required'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: heightController,
                    decoration: const InputDecoration(
                      labelText: 'Height/Length (mm) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Height is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: widthController,
                    decoration: const InputDecoration(
                      labelText: 'Cover Width (mm) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Width is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: minGaugeController,
                    decoration: const InputDecoration(
                      labelText: 'Min Gauge (mm) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Min gauge is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: maxGaugeController,
                    decoration: const InputDecoration(
                      labelText: 'Max Gauge (mm) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Max gauge is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: minSpacingController,
                    decoration: const InputDecoration(
                      labelText: 'Min Spacing (mm) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Min spacing is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: maxSpacingController,
                    decoration: const InputDecoration(
                      labelText: 'Max Spacing (mm) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Max spacing is required';
                      if (double.tryParse(value!) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: leftHandTileWidthController,
                    decoration: const InputDecoration(
                      labelText: 'Left Hand Tile Width (mm)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null)
                          return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Cross Bonded'),
                    value: crossBonded,
                    onChanged: (value) {
                      setState(() {
                        crossBonded = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updatedTile = tile.copyWith(
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
                    leftHandTileWidth:
                        leftHandTileWidthController.text.isNotEmpty
                            ? double.parse(leftHandTileWidthController.text)
                            : null,
                    defaultCrossBonded: crossBonded,
                    updatedAt: DateTime.now(),
                  );
                  await FirebaseFirestore.instance
                      .collection('tiles')
                      .doc(tile.id)
                      .set(updatedTile.toJson());
                  await _fetchTiles();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildUsersPage() {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Admin user management',
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.0,
                ),
              ),
              child: const Text(
                'Admin Dashboard: User Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Users',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _users.isEmpty
              ? const Center(child: Text('No users available'))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(user.email ?? 'No Email'),
                        subtitle: Text('Role: ${user.role}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                user.isPro ? Icons.star : Icons.star_border,
                                color: user.isPro ? Colors.green : Colors.grey,
                              ),
                              onPressed: () => _toggleProStatus(user),
                              tooltip: user.isPro
                                  ? 'Downgrade to Free'
                                  : 'Upgrade to Pro',
                            ),
                            IconButton(
                              icon: const Icon(Icons.block, color: Colors.red),
                              onPressed: () => _banUser(user),
                              tooltip: 'Ban User',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _toggleProStatus(UserModel user) async {
    final newRole = user.isPro ? UserRole.free : UserRole.pro;
    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'role': newRole.toString().split('.').last,
      'subscriptionEndDate': newRole == UserRole.pro
          ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)))
          : null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    await _fetchUsers();
  }

  Future<void> _banUser(UserModel user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'role': 'banned',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    await _fetchUsers();
  }
}

class ChartData {
  ChartData(this.label, this.value);
  final String label;
  final int value;
}
