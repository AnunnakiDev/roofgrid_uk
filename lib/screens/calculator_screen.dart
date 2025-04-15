import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isVertical = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isVertical = _tabController.index == 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roofing Calculator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.straighten),
              text: 'Vertical',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.grid_4x4),
              text: 'Horizontal',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showCalculatorInfo(context);
            },
          ),
        ],
      ),
      drawer: const MainDrawer(),
      body: userAsync.when(
        data: (user) => _buildCalculatorContent(context, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Error loading user data: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Calculator is the second item (index 1)
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
            icon: Icons.home,
            activeIcon: Icons.home_filled,
          ),
          BottomNavItem(
            label: 'Calculator',
            icon: Icons.calculate,
            activeIcon: Icons.calculate_outlined,
          ),
          BottomNavItem(
            label: 'Results',
            icon: Icons.save,
            activeIcon: Icons.save_alt,
          ),
          BottomNavItem(
            label: 'Tiles',
            icon: Icons.grid_view,
            activeIcon: Icons.grid_view_outlined,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_isVertical) {
            _calculateVertical();
          } else {
            _calculateHorizontal();
          }
        },
        label: const Text('Calculate'),
        icon: const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildCalculatorContent(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Center(
        child: Text('User data not found. Please sign in again.'),
      );
    }

    // Use UserModel directly for permissions (stub PermissionsService)
    final canUseMultipleRafters = user.isPro;
    final canUseAdvancedOptions = user.isPro;
    final canExport = user.isPro;
    final canAccessDatabase = user.isPro;

    if (user.isTrialAboutToExpire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTrialExpirationWarning(context, user);
      });
    }

    return TabBarView(
      controller: _tabController,
      children: [
        VerticalCalculatorTab(
          user: user,
          canUseMultipleRafters: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
        ),
        HorizontalCalculatorTab(
          user: user,
          canUseMultipleWidths: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
        ),
      ],
    );
  }

  void _showTrialExpirationWarning(BuildContext context, UserModel user) {
    final remainingDays = user.remainingTrialDays;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pro Trial Expiring Soon'),
        content: Text(
          'Your Pro trial will expire in $remainingDays ${remainingDays == 1 ? 'day' : 'days'}. '
          'Upgrade now to keep access to all Pro features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/subscription');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _calculateVertical() {
    if (_tabController.index == 0) {
      final verticalTabState =
          context.findAncestorStateOfType<_VerticalCalculatorTabState>();
      if (verticalTabState != null) {
        verticalTabState.calculate();
      }
    }
  }

  void _calculateHorizontal() {
    if (_tabController.index == 1) {
      final horizontalTabState =
          context.findAncestorStateOfType<_HorizontalCalculatorTabState>();
      if (horizontalTabState != null) {
        horizontalTabState.calculate();
      }
    }
  }

  void _showCalculatorInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isVertical ? 'Vertical Calculator' : 'Horizontal Calculator',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isVertical
                    ? 'The Vertical Calculator helps determine batten gauge (spacing) based on rafter height.'
                    : 'The Horizontal Calculator helps determine tile spacing based on width measurements.',
              ),
              const SizedBox(height: 16),
              Text(
                'How to use:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _isVertical
                  ? const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Enter your rafter height(s)'),
                        Text('2. Select your tile type'),
                        Text('3. Tap Calculate'),
                        Text('4. View your batten gauge and results'),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Enter your width measurement(s)'),
                        Text('2. Select your tile type'),
                        Text('3. Tap Calculate'),
                        Text('4. View your tile spacing and results'),
                      ],
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
}

class VerticalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleRafters;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;

  const VerticalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleRafters,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
  });

  @override
  ConsumerState<VerticalCalculatorTab> createState() =>
      _VerticalCalculatorTabState();
}

class _VerticalCalculatorTabState extends ConsumerState<VerticalCalculatorTab> {
  final List<TextEditingController> _rafterControllers = [
    TextEditingController()
  ];
  final List<String> _rafterNames = ['Rafter 1'];
  double _gutterOverhang = 50.0;
  String _useDryRidge = 'NO';

  final TextEditingController _tileHeightController = TextEditingController();
  final TextEditingController _tileCoverWidthController =
      TextEditingController();
  final TextEditingController _minGaugeController = TextEditingController();
  final TextEditingController _maxGaugeController = TextEditingController();
  final TextEditingController _minSpacingController = TextEditingController();
  final TextEditingController _maxSpacingController = TextEditingController();
  final TextEditingController _courseOffsetController = TextEditingController();
  final TextEditingController _eaveBattenController = TextEditingController();
  final TextEditingController _ridgeOffsetController = TextEditingController();
  bool _crossBonded = true;

  @override
  void dispose() {
    for (final controller in _rafterControllers) {
      controller.dispose();
    }
    _tileHeightController.dispose();
    _tileCoverWidthController.dispose();
    _minGaugeController.dispose();
    _maxGaugeController.dispose();
    _minSpacingController.dispose();
    _maxSpacingController.dispose();
    _courseOffsetController.dispose();
    _eaveBattenController.dispose();
    _ridgeOffsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final defaultTiles = ref.watch(defaultTilesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Tile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildTileSelector(defaultTiles),
          const SizedBox(height: 16),
          if (!widget.canAccessDatabase) ...[
            TextFormField(
              controller: _tileHeightController,
              decoration: const InputDecoration(
                labelText: 'Tile Height/Length (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tileCoverWidthController,
              decoration: const InputDecoration(
                labelText: 'Tile Cover Width (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minGaugeController,
              decoration: const InputDecoration(
                labelText: 'Min Gauge (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxGaugeController,
              decoration: const InputDecoration(
                labelText: 'Max Gauge (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minSpacingController,
              decoration: const InputDecoration(
                labelText: 'Min Spacing (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxSpacingController,
              decoration: const InputDecoration(
                labelText: 'Max Spacing (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Gutter Overhang:'),
              ),
              Expanded(
                flex: 5,
                child: Slider(
                  value: _gutterOverhang,
                  min: 25.0,
                  max: 75.0,
                  divisions: 10,
                  label: '${_gutterOverhang.round()} mm',
                  onChanged: (value) {
                    setState(() {
                      _gutterOverhang = value;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setGutterOverhang(value);
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text('${_gutterOverhang.round()} mm'),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Use Dry Ridge:'),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'YES',
                      groupValue: _useDryRidge,
                      onChanged: (value) {
                        setState(() {
                          _useDryRidge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryRidge(value!);
                      },
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'NO',
                      groupValue: _useDryRidge,
                      onChanged: (value) {
                        setState(() {
                          _useDryRidge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryRidge(value!);
                      },
                    ),
                    const Text('No'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rafter Height',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.canUseMultipleRafters)
                TextButton.icon(
                  onPressed: _addRafter,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Rafter'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildRafterInputs(),
          if (!widget.canAccessDatabase || widget.canUseAdvancedOptions) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _courseOffsetController,
              decoration: const InputDecoration(
                labelText: 'Course Offset (mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _eaveBattenController,
              decoration: const InputDecoration(
                labelText: 'Under-Eave Batten (mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ridgeOffsetController,
              decoration: const InputDecoration(
                labelText: 'Ridge Offset (mm)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Cross Bonded'),
              value: _crossBonded,
              onChanged: (value) {
                setState(() {
                  _crossBonded = value ?? true;
                });
                ref
                    .read(calculatorProvider.notifier)
                    .setCrossBonded(value! ? 'YES' : 'NO');
              },
            ),
          ],
          if (!widget.canUseMultipleRafters)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro Feature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const Text(
                          'Upgrade to Pro to calculate multiple rafters at once',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/subscription');
                    },
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          if (calcState.verticalResult != null) _buildResultsCard(calcState),
          if (calcState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      calcState.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(CalculatorState calcState) {
    final result = calcState.verticalResult!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vertical Calculation Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  result.solution,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _resultItem('Input Rafter', '${result.inputRafter} mm'),
                _resultItem('Total Courses', result.totalCourses.toString()),
                _resultItem('Ridge Offset', '${result.ridgeOffset} mm'),
                if (result.underEaveBatten != null)
                  _resultItem(
                      'Under Eave Batten', '${result.underEaveBatten} mm'),
                if (result.eaveBatten != null)
                  _resultItem('Eave Batten', '${result.eaveBatten} mm'),
                if (result.firstBatten != null)
                  _resultItem('1st Batten', '${result.firstBatten} mm'),
                if (result.cutCourse != null)
                  _resultItem('Cut Course', '${result.cutCourse} mm'),
                _resultItem('Gauge', result.gauge),
                if (result.splitGauge != null)
                  _resultItem('Split Gauge', result.splitGauge!),
              ],
            ),
            if (result.warning != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.warning!)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Save calculation
                        }
                      : null,
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Share calculation
                        }
                      : null,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _resultItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(value),
        ),
      ],
    );
  }

  List<Widget> _buildRafterInputs() {
    final List<Widget> rafterInputs = [];
    final int displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      rafterInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (widget.canUseMultipleRafters) ...[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: TextEditingController(text: _rafterNames[i]),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _rafterNames[i] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.canUseMultipleRafters ? 5 : 8,
                child: TextField(
                  controller: _rafterControllers[i],
                  decoration: InputDecoration(
                    labelText: widget.canUseMultipleRafters
                        ? null
                        : 'Rafter height in mm',
                    hintText: 'e.g., 6000',
                    suffixText: 'mm',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (widget.canUseMultipleRafters &&
                  _rafterControllers.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeRafter(i),
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove rafter',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return rafterInputs;
  }

  Widget _buildTileSelector(List<TileModel> tiles) {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final selectedTile = ref.watch(calculatorProvider).selectedTile;

    if (!widget.canAccessDatabase) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Free users must input tile measurements manually'),
          const SizedBox(height: 12),
          _buildManualTileInputs(),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      value: selectedTile?.id,
      hint: const Text('Select tile type'),
      items: tiles.map<DropdownMenuItem<String>>((tile) {
        return DropdownMenuItem<String>(
          value: tile.id,
          child: Text('${tile.name} (${tile.materialTypeString})'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selected = tiles.firstWhere((tile) => tile.id == value);
          calculatorNotifier.setTile(selected);
        }
      },
    );
  }

  void _addRafter() {
    if (!widget.canUseMultipleRafters) return;

    setState(() {
      _rafterControllers.add(TextEditingController());
      _rafterNames.add('Rafter ${_rafterControllers.length}');
    });
  }

  void _removeRafter(int index) {
    if (!widget.canUseMultipleRafters) return;
    if (_rafterControllers.length <= 1) return;

    setState(() {
      _rafterControllers[index].dispose();
      _rafterControllers.removeAt(index);
      _rafterNames.removeAt(index);
    });
  }

  Future<void> calculate() async {
    final calculatorState = ref.read(calculatorProvider);
    if (calculatorState.selectedTile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tile type first'),
        ),
      );
      return;
    }

    final List<double> rafterHeights = [];
    final displayCount =
        widget.canUseMultipleRafters ? _rafterControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final heightText = _rafterControllers[i].text.trim();
      if (heightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please enter a height for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}'),
          ),
        );
        return;
      }

      final double? height = double.tryParse(heightText);
      if (height == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Invalid height value for ${widget.canUseMultipleRafters ? _rafterNames[i] : 'the rafter'}'),
          ),
        );
        return;
      }

      rafterHeights.add(height);
    }

    await ref
        .read(calculatorProvider.notifier)
        .calculateVertical(rafterHeights);
  }

  Widget _buildManualTileInputs() {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final nameController = TextEditingController(text: 'Custom Tile');

    return Column(
      children: [
        TextFormField(
          controller: _tileHeightController,
          decoration: const InputDecoration(
            labelText: 'Tile Height/Length (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tileCoverWidthController,
          decoration: const InputDecoration(
            labelText: 'Tile Cover Width (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minGaugeController,
          decoration: const InputDecoration(
            labelText: 'Min Gauge (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxGaugeController,
          decoration: const InputDecoration(
            labelText: 'Max Gauge (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minSpacingController,
          decoration: const InputDecoration(
            labelText: 'Min Spacing (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxSpacingController,
          decoration: const InputDecoration(
            labelText: 'Max Spacing (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_tileHeightController.text.isNotEmpty &&
                _tileCoverWidthController.text.isNotEmpty &&
                _minGaugeController.text.isNotEmpty &&
                _maxGaugeController.text.isNotEmpty &&
                _minSpacingController.text.isNotEmpty &&
                _maxSpacingController.text.isNotEmpty) {
              final now = DateTime.now();
              final tempTile = TileModel(
                id: 'temp_manual_tile_${now.millisecondsSinceEpoch}',
                name: nameController.text,
                manufacturer: 'Manual Input',
                materialType: TileSlateType.unknown,
                description: 'Manually entered tile specifications',
                isPublic: false,
                isApproved: false,
                createdById: 'temp_user',
                createdAt: now,
                updatedAt: now,
                slateTileHeight:
                    double.tryParse(_tileHeightController.text) ?? 0,
                tileCoverWidth:
                    double.tryParse(_tileCoverWidthController.text) ?? 0,
                minGauge: double.tryParse(_minGaugeController.text) ?? 0,
                maxGauge: double.tryParse(_maxGaugeController.text) ?? 0,
                minSpacing: double.tryParse(_minSpacingController.text) ?? 0,
                maxSpacing: double.tryParse(_maxSpacingController.text) ?? 0,
                defaultCrossBonded: false,
              );

              calculatorNotifier.setTile(tempTile);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tile specifications applied'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all tile specification fields'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Apply Specifications'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
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
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pro users have access to our complete tile database with predefined measurements for all standard UK roofing tiles.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  context.go('/subscription');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                ),
                child: const Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HorizontalCalculatorTab extends ConsumerStatefulWidget {
  final UserModel user;
  final bool canUseMultipleWidths;
  final bool canUseAdvancedOptions;
  final bool canExport;
  final bool canAccessDatabase;

  const HorizontalCalculatorTab({
    super.key,
    required this.user,
    required this.canUseMultipleWidths,
    required this.canUseAdvancedOptions,
    required this.canExport,
    required this.canAccessDatabase,
  });

  @override
  ConsumerState<HorizontalCalculatorTab> createState() =>
      _HorizontalCalculatorTabState();
}

class _HorizontalCalculatorTabState
    extends ConsumerState<HorizontalCalculatorTab> {
  final List<TextEditingController> _widthControllers = [
    TextEditingController()
  ];
  final List<String> _widthNames = ['Width 1'];
  String _useDryVerge = 'NO';
  String _abutmentSide = 'NONE';
  String _useLHTile = 'NO';
  String _crossBonded = 'NO';

  final TextEditingController _tileHeightController = TextEditingController();
  final TextEditingController _tileCoverWidthController =
      TextEditingController();
  final TextEditingController _minGaugeController = TextEditingController();
  final TextEditingController _maxGaugeController = TextEditingController();
  final TextEditingController _minSpacingController = TextEditingController();
  final TextEditingController _maxSpacingController = TextEditingController();

  @override
  void dispose() {
    for (final controller in _widthControllers) {
      controller.dispose();
    }
    _tileHeightController.dispose();
    _tileCoverWidthController.dispose();
    _minGaugeController.dispose();
    _maxGaugeController.dispose();
    _minSpacingController.dispose();
    _maxSpacingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final defaultTiles = ref.watch(defaultTilesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Tile',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildTileSelector(defaultTiles),
          const SizedBox(height: 16),
          if (!widget.canAccessDatabase) ...[
            TextFormField(
              controller: _tileHeightController,
              decoration: const InputDecoration(
                labelText: 'Tile Height/Length (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tileCoverWidthController,
              decoration: const InputDecoration(
                labelText: 'Tile Cover Width (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minGaugeController,
              decoration: const InputDecoration(
                labelText: 'Min Gauge (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxGaugeController,
              decoration: const InputDecoration(
                labelText: 'Max Gauge (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minSpacingController,
              decoration: const InputDecoration(
                labelText: 'Min Spacing (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxSpacingController,
              decoration: const InputDecoration(
                labelText: 'Max Spacing (mm) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Use Dry Verge:'),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'YES',
                      groupValue: _useDryVerge,
                      onChanged: (value) {
                        setState(() {
                          _useDryVerge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryVerge(value!);
                      },
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'NO',
                      groupValue: _useDryVerge,
                      onChanged: (value) {
                        setState(() {
                          _useDryVerge = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseDryVerge(value!);
                      },
                    ),
                    const Text('No'),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Abutment Side:'),
              ),
              Expanded(
                flex: 5,
                child: DropdownButton<String>(
                  value: _abutmentSide,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'NONE', child: Text('None')),
                    DropdownMenuItem(value: 'LEFT', child: Text('Left')),
                    DropdownMenuItem(value: 'RIGHT', child: Text('Right')),
                    DropdownMenuItem(value: 'BOTH', child: Text('Both')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _abutmentSide = value!;
                    });
                    ref
                        .read(calculatorProvider.notifier)
                        .setAbutmentSide(value!);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Use LH Tile:'),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'YES',
                      groupValue: _useLHTile,
                      onChanged: (value) {
                        setState(() {
                          _useLHTile = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseLHTile(value!);
                      },
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'NO',
                      groupValue: _useLHTile,
                      onChanged: (value) {
                        setState(() {
                          _useLHTile = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setUseLHTile(value!);
                      },
                    ),
                    const Text('No'),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Cross Bonded:'),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Radio<String>(
                      value: 'YES',
                      groupValue: _crossBonded,
                      onChanged: (value) {
                        setState(() {
                          _crossBonded = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setCrossBonded(value!);
                      },
                    ),
                    const Text('Yes'),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: 'NO',
                      groupValue: _crossBonded,
                      onChanged: (value) {
                        setState(() {
                          _crossBonded = value!;
                        });
                        ref
                            .read(calculatorProvider.notifier)
                            .setCrossBonded(value!);
                      },
                    ),
                    const Text('No'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Width Measurement',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.canUseMultipleWidths)
                TextButton.icon(
                  onPressed: _addWidth,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Width'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildWidthInputs(),
          if (!widget.canUseMultipleWidths)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro Feature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const Text(
                          'Upgrade to Pro to calculate multiple widths at once',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/subscription');
                    },
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
          if (calcState.horizontalResult != null)
            _buildHorizontalResultsCard(calcState),
          if (calcState.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      calcState.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildWidthInputs() {
    final List<Widget> widthInputs = [];
    final int displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      widthInputs.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            children: [
              if (widget.canUseMultipleWidths) ...[
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: TextEditingController(text: _widthNames[i]),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _widthNames[i] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: widget.canUseMultipleWidths ? 5 : 8,
                child: TextField(
                  controller: _widthControllers[i],
                  decoration: InputDecoration(
                    labelText:
                        widget.canUseMultipleWidths ? null : 'Width in mm',
                    hintText: 'e.g., 5000',
                    suffixText: 'mm',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              if (widget.canUseMultipleWidths &&
                  _widthControllers.length > 1) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _removeWidth(i),
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                  tooltip: 'Remove width',
                ),
              ],
            ],
          ),
        ),
      );
    }

    return widthInputs;
  }

  Widget _buildTileSelector(List<TileModel> tiles) {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final selectedTile = ref.watch(calculatorProvider).selectedTile;

    if (!widget.canAccessDatabase) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Free users must input tile measurements manually'),
          const SizedBox(height: 12),
          _buildManualTileInputs(),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      value: selectedTile?.id,
      hint: const Text('Select tile type'),
      items: tiles.map<DropdownMenuItem<String>>((tile) {
        return DropdownMenuItem<String>(
          value: tile.id,
          child: Text('${tile.name} (${tile.materialTypeString})'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final selected = tiles.firstWhere((tile) => tile.id == value);
          calculatorNotifier.setTile(selected);
        }
      },
    );
  }

  void _addWidth() {
    if (!widget.canUseMultipleWidths) return;

    setState(() {
      _widthControllers.add(TextEditingController());
      _widthNames.add('Width ${_widthControllers.length}');
    });
  }

  void _removeWidth(int index) {
    if (!widget.canUseMultipleWidths) return;
    if (_widthControllers.length <= 1) return;

    setState(() {
      _widthControllers[index].dispose();
      _widthControllers.removeAt(index);
      _widthNames.removeAt(index);
    });
  }

  Future<void> calculate() async {
    final calculatorState = ref.read(calculatorProvider);
    if (calculatorState.selectedTile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a tile type first'),
        ),
      );
      return;
    }

    final List<double> widths = [];
    final displayCount =
        widget.canUseMultipleWidths ? _widthControllers.length : 1;

    for (int i = 0; i < displayCount; i++) {
      final widthText = _widthControllers[i].text.trim();
      if (widthText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please enter a width for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}'),
          ),
        );
        return;
      }

      final double? width = double.tryParse(widthText);
      if (width == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Invalid width value for ${widget.canUseMultipleWidths ? _widthNames[i] : 'the width'}'),
          ),
        );
        return;
      }

      widths.add(width);
    }

    await ref.read(calculatorProvider.notifier).calculateHorizontal(widths);
  }

  Widget _buildHorizontalResultsCard(CalculatorState calcState) {
    final result = calcState.horizontalResult!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Horizontal Calculation Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  result.solution,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _resultItem('Width', '${result.width} mm'),
                if (result.lhOverhang != null)
                  _resultItem('LH Overhang', '${result.lhOverhang} mm'),
                if (result.rhOverhang != null)
                  _resultItem('RH Overhang', '${result.rhOverhang} mm'),
                if (result.cutTile != null)
                  _resultItem('Cut Tile', '${result.cutTile} mm'),
                if (result.firstMark != null)
                  _resultItem('First Mark', '${result.firstMark} mm'),
                if (result.secondMark != null)
                  _resultItem('Second Mark', '${result.secondMark} mm'),
                _resultItem('Marks', result.marks),
                if (result.splitMarks != null)
                  _resultItem('Split Marks', result.splitMarks!),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Save calculation
                        }
                      : null,
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.canExport
                      ? () {
                          // TODO: Share calculation
                        }
                      : null,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _resultItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildManualTileInputs() {
    final calculatorNotifier = ref.read(calculatorProvider.notifier);
    final nameController = TextEditingController(text: 'Custom Tile');

    return Column(
      children: [
        TextFormField(
          controller: _tileHeightController,
          decoration: const InputDecoration(
            labelText: 'Tile Height/Length (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tileCoverWidthController,
          decoration: const InputDecoration(
            labelText: 'Tile Cover Width (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minGaugeController,
          decoration: const InputDecoration(
            labelText: 'Min Gauge (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxGaugeController,
          decoration: const InputDecoration(
            labelText: 'Max Gauge (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _minSpacingController,
          decoration: const InputDecoration(
            labelText: 'Min Spacing (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxSpacingController,
          decoration: const InputDecoration(
            labelText: 'Max Spacing (mm) *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            if (_tileHeightController.text.isNotEmpty &&
                _tileCoverWidthController.text.isNotEmpty &&
                _minGaugeController.text.isNotEmpty &&
                _maxGaugeController.text.isNotEmpty &&
                _minSpacingController.text.isNotEmpty &&
                _maxSpacingController.text.isNotEmpty) {
              final now = DateTime.now();
              final tempTile = TileModel(
                id: 'temp_manual_tile_${now.millisecondsSinceEpoch}',
                name: nameController.text,
                manufacturer: 'Manual Input',
                materialType: TileSlateType.unknown,
                description: 'Manually entered tile specifications',
                isPublic: false,
                isApproved: false,
                createdById: 'temp_user',
                createdAt: now,
                updatedAt: now,
                slateTileHeight:
                    double.tryParse(_tileHeightController.text) ?? 0,
                tileCoverWidth:
                    double.tryParse(_tileCoverWidthController.text) ?? 0,
                minGauge: double.tryParse(_minGaugeController.text) ?? 0,
                maxGauge: double.tryParse(_maxGaugeController.text) ?? 0,
                minSpacing: double.tryParse(_minSpacingController.text) ?? 0,
                maxSpacing: double.tryParse(_maxSpacingController.text) ?? 0,
                defaultCrossBonded: false,
              );

              calculatorNotifier.setTile(tempTile);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tile specifications applied'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all tile specification fields'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Apply Specifications'),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
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
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pro users have access to our complete tile database with predefined measurements for all standard UK roofing tiles.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  context.go('/subscription');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade900,
                ),
                child: const Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
