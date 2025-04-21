import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/calculator/vertical_calculator_tab.dart';
import 'package:roofgrid_uk/screens/calculator/horizontal_calculator_tab.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Define a class to hold vertical inputs
class VerticalInputs {
  final List<Map<String, dynamic>> rafterHeights; // List of {label, value}
  final double gutterOverhang;
  final String useDryRidge;

  VerticalInputs({
    this.rafterHeights = const [],
    this.gutterOverhang = 50.0,
    this.useDryRidge = 'NO',
  });

  VerticalInputs copyWith({
    List<Map<String, dynamic>>? rafterHeights,
    double? gutterOverhang,
    String? useDryRidge,
  }) {
    return VerticalInputs(
      rafterHeights: rafterHeights ?? this.rafterHeights,
      gutterOverhang: gutterOverhang ?? this.gutterOverhang,
      useDryRidge: useDryRidge ?? this.useDryRidge,
    );
  }
}

// Define a class to hold horizontal inputs
class HorizontalInputs {
  final List<Map<String, dynamic>> widths; // List of {label, value}
  final String useDryVerge;
  final String abutmentSide;
  final String useLHTile;
  final String crossBonded;

  HorizontalInputs({
    this.widths = const [],
    this.useDryVerge = 'NO',
    this.abutmentSide = 'NONE',
    this.useLHTile = 'NO',
    this.crossBonded = 'NO',
  });

  HorizontalInputs copyWith({
    List<Map<String, dynamic>>? widths,
    String? useDryVerge,
    String? abutmentSide,
    String? useLHTile,
    String? crossBonded,
  }) {
    return HorizontalInputs(
      widths: widths ?? this.widths,
      useDryVerge: useDryVerge ?? this.useDryVerge,
      abutmentSide: abutmentSide ?? this.abutmentSide,
      useLHTile: useLHTile ?? this.useLHTile,
      crossBonded: crossBonded ?? this.crossBonded,
    );
  }
}

class CalculatorScreen extends ConsumerStatefulWidget {
  final SavedResult? savedResult; // Optional parameter for editing

  const CalculatorScreen({super.key, this.savedResult});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isVertical = true;
  bool _isOnline = true;
  final GlobalKey<VerticalCalculatorTabState> _verticalTabKey = GlobalKey();
  final GlobalKey<HorizontalCalculatorTabState> _horizontalTabKey = GlobalKey();
  late VerticalInputs _verticalInputs;
  late HorizontalInputs _horizontalInputs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize inputs based on savedResult if present
    if (widget.savedResult != null) {
      final inputs = widget.savedResult!.inputs;
      if (widget.savedResult!.type == CalculationType.vertical) {
        _isVertical = true;
        _tabController.index = 0;
        _verticalInputs = VerticalInputs(
          rafterHeights:
              (inputs['vertical_inputs']?['rafterHeights'] as List<dynamic>?)
                      ?.map<Map<String, dynamic>>(
                          (item) => Map<String, dynamic>.from(item as Map))
                      .toList() ??
                  [],
          gutterOverhang: inputs['vertical_inputs']?['gutterOverhang'] ?? 50.0,
          useDryRidge: inputs['vertical_inputs']?['useDryRidge'] ?? 'NO',
        );
        _horizontalInputs = HorizontalInputs();
      } else {
        _isVertical = false;
        _tabController.index = 1;
        _horizontalInputs = HorizontalInputs(
          widths: (inputs['horizontal_inputs']?['widths'] as List<dynamic>?)
                  ?.map<Map<String, dynamic>>(
                      (item) => Map<String, dynamic>.from(item as Map))
                  .toList() ??
              [],
          useDryVerge: inputs['horizontal_inputs']?['useDryVerge'] ?? 'NO',
          abutmentSide: inputs['horizontal_inputs']?['abutmentSide'] ?? 'NONE',
          useLHTile: inputs['horizontal_inputs']?['useLHTile'] ?? 'NO',
          crossBonded: inputs['horizontal_inputs']?['crossBonded'] ?? 'NO',
        );
        _verticalInputs = VerticalInputs();
      }
    } else {
      _verticalInputs = VerticalInputs();
      _horizontalInputs = HorizontalInputs();
    }

    // Check initial connectivity
    _checkConnectivity();
    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        // Sync calculations when going online
        ref.read(calculationServiceProvider).syncCalculations();
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
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(currentUserProvider);
    final calculatorState = ref.watch(calculatorProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 24.0 : 16.0;

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(child: Text('Please log in to access this feature')),
      );
    }

    // Display error message if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (calculatorState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(calculatorState.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        // Clear the error message after displaying
        ref.read(calculatorProvider.notifier).clearResults();
      }
    });

    return userAsync.when(
      data: (user) => _buildScaffold(context, user, padding),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text(
            'Error loading user data: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, UserModel? user, double padding) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.savedResult != null
            ? 'Edit Calculation: ${widget.savedResult!.projectName}'
            : 'Roofing Calculator'),
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Semantics(
              label: 'Step 2 description',
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
                  'Step 2, enter your measurements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
          Expanded(
            child: _buildCalculatorContent(context, user, padding),
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: _buildCalculateButton(user),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // Highlight Calculator tab
        onTap: (index) {
          if (index == 0) context.go('/home'); // Home
          if (index == 1)
            context.go('/home'); // Profile (redirects to home for now)
          if (index == 2) {
            // Tiles
            if (user?.isPro != true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade to Pro to access this feature'),
                ),
              );
              context.go('/subscription');
            } else {
              context.go('/tiles');
            }
          }
          if (index == 3) {
            // Results
            if (user?.isPro != true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade to Pro to access this feature'),
                ),
              );
              context.go('/subscription');
            } else {
              context.go('/results');
            }
          }
        },
        items: [
          const BottomNavItem(
            label: 'Home',
            icon: Icons.home,
            activeIcon: Icons.home_filled,
          ),
          const BottomNavItem(
            label: 'Profile',
            icon: Icons.person,
            activeIcon: Icons.person,
          ),
          BottomNavItem(
            label: 'Tiles',
            icon: Icons.grid_view,
            activeIcon: Icons.grid_view,
            tooltip: user?.isPro == true
                ? 'Tiles'
                : 'Upgrade to Pro to access tiles',
          ),
          BottomNavItem(
            label: 'Results',
            icon: Icons.save,
            activeIcon: Icons.save,
            tooltip: user?.isPro == true
                ? 'Saved Results'
                : 'Upgrade to Pro to access saved results',
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorContent(
      BuildContext context, UserModel? user, double padding) {
    if (user == null) {
      return const Center(
          child: Text('User data not found. Please sign in again.'));
    }

    final canUseMultipleRafts = user.isPro;
    final canUseAdvancedOptions = user.isPro;
    final canExport = user.isPro;
    final canAccessDatabase = user.isPro;

    return TabBarView(
      controller: _tabController,
      children: [
        VerticalCalculatorTab(
          key: _verticalTabKey,
          user: user,
          canUseMultipleRafters: canUseMultipleRafts,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
          initialInputs: _verticalInputs,
          onInputsChanged: (inputs) {
            setState(() {
              _verticalInputs = inputs;
            });
          },
          saveResultCallback: (calculationData, type) => _saveResult(
            user,
            calculationData,
            type,
          ),
        ),
        HorizontalCalculatorTab(
          key: _horizontalTabKey,
          user: user,
          canUseMultipleWidths: canUseMultipleRafts,
          canUseAdvancedOptions: canUseAdvancedOptions,
          canExport: canExport,
          canAccessDatabase: canAccessDatabase,
          initialInputs: _horizontalInputs,
          onInputsChanged: (inputs) {
            setState(() {
              _horizontalInputs = inputs;
            });
          },
          saveResultCallback: (calculationData, type) => _saveResult(
            user,
            calculationData,
            type,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton(UserModel? user) {
    return Semantics(
      label: 'Calculate results',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: ElevatedButton(
          onPressed: () {
            if (_isVertical) {
              _calculateVertical(user);
            } else {
              _calculateHorizontal(user);
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50), // Full-width
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text(
            'Calculate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _calculateVertical(UserModel? user) async {
    debugPrint('Starting _calculateVertical');
    final verticalTabState = _verticalTabKey.currentState;
    if (verticalTabState == null) {
      debugPrint('verticalTabState is null');
      return;
    }
    debugPrint('Calling calculate on verticalTabState');
    final result = await verticalTabState.calculate();
    debugPrint('Calculate result: $result');
    if (result != null) {
      // Auto-scroll to results
      final context = verticalTabState.resultsKey.currentContext;
      if (context != null) {
        debugPrint('Auto-scrolling to vertical results');
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        debugPrint('Context not found for vertical results');
      }
    } else {
      debugPrint('No result returned from vertical calculate');
    }
  }

  void _calculateHorizontal(UserModel? user) async {
    debugPrint('Starting _calculateHorizontal');
    final horizontalTabState = _horizontalTabKey.currentState;
    if (horizontalTabState == null) {
      debugPrint('horizontalTabState is null');
      return;
    }
    debugPrint('Calling calculate on horizontalTabState');
    final result = await horizontalTabState.calculate();
    debugPrint('Calculate result: $result');
    if (result != null) {
      // Auto-scroll to results
      final context = horizontalTabState.resultsKey.currentContext;
      if (context != null) {
        debugPrint('Auto-scrolling to horizontal results');
        await Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else {
        debugPrint('Context not found for horizontal results');
      }
    } else {
      debugPrint('No result returned from horizontal calculate');
    }
  }

  Future<void> _saveResult(
      UserModel user, Map<String, dynamic> calculationData, String type) async {
    // Collect inputs from both tabs
    final verticalInputs = _verticalTabKey.currentState?.inputs ?? {};
    final horizontalInputs = _horizontalTabKey.currentState?.inputs ?? {};

    // Combine inputs based on the type of calculation
    Map<String, dynamic> combinedInputs = {};
    if (type == 'vertical') {
      combinedInputs = {
        'vertical_inputs': verticalInputs,
        if (horizontalInputs.isNotEmpty) 'horizontal_inputs': horizontalInputs,
      };
    } else {
      combinedInputs = {
        'horizontal_inputs': horizontalInputs,
        if (verticalInputs.isNotEmpty) 'vertical_inputs': verticalInputs,
      };
    }

    // Use the result data for outputs
    final outputs = calculationData['outputs'] ?? calculationData;
    final tile = calculationData['tile'] ??
        ref.read(calculatorProvider).selectedTile?.toJson() ??
        {};

    final calculationId = calculationData['id'] as String? ??
        'calc_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    final savedResult = SavedResult(
      id: calculationId,
      userId: user.id,
      projectName: calculationData['projectName'] ?? '',
      type: type == 'vertical'
          ? CalculationType.vertical
          : CalculationType.horizontal,
      timestamp: DateTime.now(),
      inputs: combinedInputs,
      outputs: outputs,
      tile: tile,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to the calculations collection
    debugPrint('Saving calculation to Firestore: $calculationId');
    try {
      await ref.read(calculationServiceProvider).saveCalculation(
            id: calculationId,
            userId: user.id,
            tileId: tile['id'] as String,
            type: type,
            inputs: calculationData['inputs'] as Map<String, dynamic>,
            result: outputs,
            tile: tile,
            success: (calculationData['outputs']
                    as Map<String, dynamic>)['warning'] ==
                null,
          );
    } catch (e) {
      debugPrint('Error saving calculation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save calculation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    // Save to the saved_results collection
    try {
      debugPrint('Saving result to Firestore: ${savedResult.id}');
      await ref.read(resultsServiceProvider).saveResult(user.id, savedResult);

      // Save to Hive for offline caching
      final resultsBox = Hive.box<SavedResult>('resultsBox');
      debugPrint('Saving result to Hive: ${savedResult.id}');
      try {
        await resultsBox.put(savedResult.id, savedResult);
        debugPrint('Result saved to Hive successfully');
      } catch (e) {
        debugPrint('Error saving to Hive: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Saved to Firestore, but failed to save offline: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Calculation result saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save result: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
