import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/calculator/vertical_calculator_tab.dart';
import 'package:roofgrid_uk/screens/calculator/horizontal_calculator_tab.dart';
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
  final GlobalKey<VerticalCalculatorTabState> _verticalTabKey = GlobalKey();
  final GlobalKey<HorizontalCalculatorTabState> _horizontalTabKey = GlobalKey();

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
          builder: (context) => Semantics(
            label: 'Open navigation drawer',
            child: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open navigation drawer',
            ),
          ),
        ),
        actions: [
          Semantics(
            label: 'Show calculator information',
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showCalculatorInfo(context),
              tooltip: 'Show calculator information',
            ),
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
        currentIndex: 1,
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
              label: 'Home', icon: Icons.home, activeIcon: Icons.home_filled),
          BottomNavItem(
              label: 'Calculator',
              icon: Icons.calculate,
              activeIcon: Icons.calculate_outlined),
          BottomNavItem(
              label: 'Results', icon: Icons.save, activeIcon: Icons.save_alt),
          BottomNavItem(
              label: 'Tiles',
              icon: Icons.grid_view,
              activeIcon: Icons.grid_view_outlined),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Calculate results',
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_isVertical) {
              _calculateVertical();
            } else {
              _calculateHorizontal();
            }
          },
          label: const Text('Calculate'),
          icon: const Icon(Icons.calculate),
          tooltip: 'Calculate results',
        ),
      ),
    );
  }

  Widget _buildCalculatorContent(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Center(
          child: Text('User data not found. Please sign in again.'));
    }

    final canUseMultipleRafters = user.isPro;
    final canUseAdvancedOptions = user.isPro;
    final canExport = user.isPro;
    final canAccessDatabase = user.isPro;

    return TabBarView(
      controller: _tabController,
      children: [
        VerticalCalculatorTab(
          key: _verticalTabKey,
          user: user,
          canUseMultipleRafters: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
        ),
        HorizontalCalculatorTab(
          key: _horizontalTabKey,
          user: user,
          canUseMultipleWidths: canUseMultipleRafters,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
        ),
      ],
    );
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
                        Text('1. Select a tile type'),
                        Text('2. Enter your rafter height(s)'),
                        Text('3. Tap Calculate'),
                        Text('4. View your batten gauge and results'),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Select a tile type'),
                        Text('2. Enter your width measurement(s)'),
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

  void _calculateVertical() {
    final verticalTabState = _verticalTabKey.currentState;
    if (verticalTabState != null) {
      verticalTabState.calculate();
    }
  }

  void _calculateHorizontal() {
    final horizontalTabState = _horizontalTabKey.currentState;
    if (horizontalTabState != null) {
      horizontalTabState.calculate();
    }
  }
}
