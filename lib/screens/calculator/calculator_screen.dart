import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
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
import 'package:roofgrid_uk/services/hive_service.dart';

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

class CalculatorScreen extends ConsumerWidget {
  final SavedResult? savedResult; // Optional parameter for editing

  const CalculatorScreen({super.key, this.savedResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(currentUserProvider);

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("User not authenticated, redirecting to /auth/login");
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(child: Text('Please log in to access this feature')),
      );
    }

    return userAsync.when(
      data: (user) => CalculatorContent(
        user: user,
        savedResult: savedResult,
      ),
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
}

class CalculatorContent extends ConsumerStatefulWidget {
  final UserModel? user;
  final SavedResult? savedResult;

  const CalculatorContent({
    super.key,
    required this.user,
    this.savedResult,
  });

  @override
  ConsumerState<CalculatorContent> createState() => _CalculatorContentState();
}

class _CalculatorContentState extends ConsumerState<CalculatorContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isVertical = true;
  bool _isOnline = true;
  bool _hasRedirectedToTileSelect = false; // Flag to prevent repeated redirects
  final GlobalKey<VerticalCalculatorTabState> _verticalTabKey = GlobalKey();
  final GlobalKey<HorizontalCalculatorTabState> _horizontalTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize tab based on savedResult, if present
    if (widget.savedResult != null) {
      _isVertical = widget.savedResult!.type == CalculationType.vertical;
      _tabController.index = _isVertical ? 0 : 1;
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
    // Handle null user case
    if (widget.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print("User data not found, redirecting to /auth/login");
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(child: Text('User data not found. Please sign in again.')),
      );
    }

    final user = widget.user!; // Safe to use non-null user now
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final padding = isLargeScreen ? 24.0 : 16.0;

    // Redirect to tile selection if not already done
    if (!_hasRedirectedToTileSelect) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final selectedTile = await context.push('/calculator/tile-select');
          if (selectedTile != null && selectedTile is TileModel) {
            print("Tile selected: ${selectedTile.name}");
            ref.read(calculatorProvider.notifier).setTile(selectedTile);
          } else {
            debugPrint('No tile selected or invalid tile data returned');
            // Optionally, redirect back to home if no tile is selected
            context.go('/home');
          }
        } catch (e) {
          debugPrint('Error selecting tile: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error selecting tile: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.go('/home');
        }
      });
      setState(() {
        _hasRedirectedToTileSelect = true;
      });
    }

    // Display error message if present using a Consumer for errorMessage only
    return Consumer(
      builder: (context, ref, child) {
        final errorMessage =
            ref.watch(calculatorProvider.select((state) => state.errorMessage));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (errorMessage != null) {
            print("Showing error message: $errorMessage");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            ref.read(calculatorProvider.notifier).clearResults();
          }
        });
        return child!;
      },
      child: Scaffold(
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
                onPressed: () {
                  print("Opening navigation drawer");
                  Scaffold.of(context).openDrawer();
                },
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
        body: _buildCalculatorContent(context, user, padding),
        bottomNavigationBar: BottomNavBar(
          currentIndex: 1, // Highlight Calculator tab
          onTap: (index) {
            if (index == 0) {
              print("Navigating to /home from bottom navigation");
              context.go('/home');
            }
            if (index == 1) {
              print(
                  "Navigating to /home from bottom navigation (profile redirect)");
              context.go('/home');
            }
            if (index == 2) {
              // Tiles
              if (user.isPro != true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro to access this feature'),
                  ),
                );
                print("User not Pro, redirecting to /subscription");
                context.go('/subscription');
              } else {
                print("Navigating to /tiles from bottom navigation");
                context.go('/tiles');
              }
            }
            if (index == 3) {
              // Results
              if (user.isPro != true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Upgrade to Pro to access this feature'),
                  ),
                );
                print("User not Pro, redirecting to /subscription");
                context.go('/subscription');
              } else {
                print("Navigating to /results from bottom navigation");
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
              tooltip: user.isPro ? 'Tiles' : 'Upgrade to Pro to access tiles',
            ),
            BottomNavItem(
              label: 'Results',
              icon: Icons.save,
              activeIcon: Icons.save,
              tooltip: user.isPro
                  ? 'Saved Results'
                  : 'Upgrade to Pro to access saved results',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatorContent(
      BuildContext context, UserModel user, double padding) {
    final canUseMultipleRafts = user.isPro;
    final canUseAdvancedOptions = user.isPro;
    final canExport = user.isPro;
    final canAccessDatabase = user.isPro;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;
    final fontSize = isLargeScreen ? 16.0 : 14.0;

    return Column(
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
        Padding(
          padding: EdgeInsets.all(padding),
          child: Consumer(
            builder: (context, ref, child) {
              final selectedTile = ref.watch(
                  calculatorProvider.select((state) => state.selectedTile));
              print(
                  "Rebuilding selected tile row, selectedTile: ${selectedTile?.name}");
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Selected Tile: ${selectedTile?.name ?? "None"}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canAccessDatabase)
                    Semantics(
                      label: 'Edit selected tile',
                      child: TextButton(
                        onPressed: () async {
                          try {
                            final selectedTile =
                                await context.push('/calculator/tile-select');
                            if (selectedTile != null &&
                                selectedTile is TileModel) {
                              print("Tile selected: ${selectedTile.name}");
                              ref
                                  .read(calculatorProvider.notifier)
                                  .setTile(selectedTile);
                            } else {
                              debugPrint(
                                  'No tile selected or invalid tile data returned');
                            }
                          } catch (e) {
                            debugPrint('Error selecting tile: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error selecting tile: $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Edit Tile',
                          style: TextStyle(fontSize: fontSize - 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              VerticalCalculatorTab(
                key: _verticalTabKey,
                user: user,
                canUseMultipleRafters: canUseMultipleRafts,
                canUseAdvancedOptions: canUseAdvancedOptions,
                canExport: canExport,
                canAccessDatabase: canAccessDatabase,
                initialInputs: widget.savedResult != null &&
                        widget.savedResult!.type == CalculationType.vertical
                    ? VerticalInputs(
                        rafterHeights: (widget
                                        .savedResult!.inputs['vertical_inputs']
                                    ?['rafterHeights'] as List<dynamic>?)
                                ?.map((item) => item as Map<String, dynamic>)
                                .toList() ??
                            [],
                        gutterOverhang: widget.savedResult!
                                .inputs['vertical_inputs']?['gutterOverhang'] ??
                            50.0,
                        useDryRidge: widget.savedResult!
                                .inputs['vertical_inputs']?['useDryRidge'] ??
                            'NO',
                      )
                    : VerticalInputs(),
                onInputsChanged: (_) {
                  // No-op: We no longer need to update parent state
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
                initialInputs: widget.savedResult != null &&
                        widget.savedResult!.type == CalculationType.horizontal
                    ? HorizontalInputs(
                        widths: (widget.savedResult!.inputs['horizontal_inputs']
                                    ?['widths'] as List<dynamic>?)
                                ?.map((item) => item as Map<String, dynamic>)
                                .toList() ??
                            [],
                        useDryVerge: widget.savedResult!
                                .inputs['horizontal_inputs']?['useDryVerge'] ??
                            'NO',
                        abutmentSide: widget.savedResult!
                                .inputs['horizontal_inputs']?['abutmentSide'] ??
                            'NONE',
                        useLHTile: widget.savedResult!
                                .inputs['horizontal_inputs']?['useLHTile'] ??
                            'NO',
                        crossBonded: widget.savedResult!
                                .inputs['horizontal_inputs']?['crossBonded'] ??
                            'NO',
                      )
                    : HorizontalInputs(),
                onInputsChanged: (_) {
                  // No-op: We no longer need to update parent state
                },
                saveResultCallback: (calculationData, type) => _saveResult(
                  user,
                  calculationData,
                  type,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(padding),
          child: _buildCalculateButton(user),
        ),
      ],
    );
  }

  Widget _buildCalculateButton(UserModel user) {
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

  void _calculateVertical(UserModel user) async {
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

  void _calculateHorizontal(UserModel user) async {
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
    // Wait for HiveService initialization to complete
    await ref.read(hiveServiceInitializerProvider.future);

    // Collect inputs directly from the tabs
    final verticalInputs = type == 'vertical'
        ? _verticalTabKey.currentState?.inputs ?? {}
        : _horizontalTabKey.currentState != null
            ? _horizontalTabKey.currentState!.inputs
            : {};
    final horizontalInputs = type == 'horizontal'
        ? _horizontalTabKey.currentState?.inputs ?? {}
        : _verticalTabKey.currentState != null
            ? _verticalTabKey.currentState!.inputs
            : {};

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
      final hiveService = ref.read(hiveServiceProvider);
      final resultsBox = hiveService.resultsBox;
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
