import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
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
import 'package:roofgrid_uk/widgets/result_visualization.dart';
import 'package:roofgrid_uk/widgets/visulization_toggle.dart';

// Define CalculatorStep enum for step-based flow
enum CalculatorStep {
  confirmTile,
  enterMeasurements,
  viewResults,
}

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
  bool _hasRedirectedToTileSelect = false;
  CalculatorStep _currentStep = CalculatorStep.enterMeasurements;

  // Store inputs directly in this widget's state
  VerticalInputs _verticalInputs = VerticalInputs();
  HorizontalInputs _horizontalInputs = HorizontalInputs();
  bool _isVerticalInputsConfirmed = false;
  bool _isHorizontalInputsConfirmed = false;
  Map<String, dynamic>? _lastVerticalCalculationData;
  Map<String, dynamic>? _lastHorizontalCalculationData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initialize inputs from savedResult, if present
    if (widget.savedResult != null) {
      _isVertical = widget.savedResult!.type == CalculationType.vertical;
      _tabController.index = _isVertical ? 0 : 1;
      if (widget.savedResult!.type == CalculationType.vertical) {
        _verticalInputs = VerticalInputs(
          rafterHeights: (widget.savedResult!.inputs['vertical_inputs']
                      ?['rafterHeights'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          gutterOverhang: widget.savedResult!.inputs['vertical_inputs']
                  ?['gutterOverhang'] ??
              50.0,
          useDryRidge: widget.savedResult!.inputs['vertical_inputs']
                  ?['useDryRidge'] ??
              'NO',
        );
        _isVerticalInputsConfirmed = true;
      } else if (widget.savedResult!.type == CalculationType.horizontal) {
        _horizontalInputs = HorizontalInputs(
          widths: (widget.savedResult!.inputs['horizontal_inputs']?['widths']
                      as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          useDryVerge: widget.savedResult!.inputs['horizontal_inputs']
                  ?['useDryVerge'] ??
              'NO',
          abutmentSide: widget.savedResult!.inputs['horizontal_inputs']
                  ?['abutmentSide'] ??
              'NONE',
          useLHTile: widget.savedResult!.inputs['horizontal_inputs']
                  ?['useLHTile'] ??
              'NO',
          crossBonded: widget.savedResult!.inputs['horizontal_inputs']
                  ?['crossBonded'] ??
              'NO',
        );
        _isHorizontalInputsConfirmed = true;
      } else if (widget.savedResult!.type == CalculationType.combined) {
        _verticalInputs = VerticalInputs(
          rafterHeights: (widget.savedResult!.inputs['vertical_inputs']
                      ?['rafterHeights'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          gutterOverhang: widget.savedResult!.inputs['vertical_inputs']
                  ?['gutterOverhang'] ??
              50.0,
          useDryRidge: widget.savedResult!.inputs['vertical_inputs']
                  ?['useDryRidge'] ??
              'NO',
        );
        _horizontalInputs = HorizontalInputs(
          widths: (widget.savedResult!.inputs['horizontal_inputs']?['widths']
                      as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          useDryVerge: widget.savedResult!.inputs['horizontal_inputs']
                  ?['useDryVerge'] ??
              'NO',
          abutmentSide: widget.savedResult!.inputs['horizontal_inputs']
                  ?['abutmentSide'] ??
              'NONE',
          useLHTile: widget.savedResult!.inputs['horizontal_inputs']
                  ?['useLHTile'] ??
              'NO',
          crossBonded: widget.savedResult!.inputs['horizontal_inputs']
                  ?['crossBonded'] ??
              'NO',
        );
        _isVerticalInputsConfirmed = true;
        _isHorizontalInputsConfirmed = true;
      }
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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

    return Image.asset(
      '$placeholderImagePath.png',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
            'Failed to load placeholder image: $placeholderImagePath.png, error: $error');
        return Image.asset(
          '$placeholderImagePath.jpg',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint(
                'Failed to load fallback image: $placeholderImagePath.jpg, error: $error');
            return const Icon(
              Icons.broken_image,
              size: 40,
              color: Colors.grey,
            );
          },
        );
      },
    );
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
      setState(() {
        _currentStep = CalculatorStep.confirmTile;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final selectedTile = await context.push('/calculator/tile-select');
          if (selectedTile != null && selectedTile is TileModel) {
            print(
                "Tile selected: ${selectedTile.name}, Image URL: ${selectedTile.image}");
            ref.read(calculatorProvider.notifier).setTile(selectedTile);
            setState(() {
              _currentStep = CalculatorStep.enterMeasurements;
            });
          } else {
            debugPrint('No tile selected or invalid tile data returned');
            // Redirect back to home if no tile is selected
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
          bottom: _currentStep == CalculatorStep.enterMeasurements
              ? TabBar(
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
                )
              : null,
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
        body: _buildStepContent(context, user, padding),
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

  Widget _buildStepContent(
      BuildContext context, UserModel user, double padding) {
    switch (_currentStep) {
      case CalculatorStep.confirmTile:
        return const Center(child: CircularProgressIndicator());
      case CalculatorStep.enterMeasurements:
        return _buildEnterMeasurementsStep(context, user, padding);
      case CalculatorStep.viewResults:
        return _buildViewResultsStep(context, user, padding);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnterMeasurementsStep(
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
        // Step Indicator
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
                'Step 2: Enter Your Measurements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),
        ),
        // Selected Tile Row
        Padding(
          padding: EdgeInsets.all(padding),
          child: Consumer(
            builder: (context, ref, child) {
              final selectedTile = ref.watch(
                  calculatorProvider.select((state) => state.selectedTile));
              print(
                  "Rebuilding selected tile row, selectedTile: ${selectedTile?.name}, Image URL: ${selectedTile?.image}");
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (user.isPro)
                          if (selectedTile?.image != null &&
                              selectedTile!.image!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Image.network(
                                selectedTile.image!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                      'Failed to load tile image: ${selectedTile.image}, error: $error');
                                  return _getPlaceholderImage(
                                      selectedTile.materialType);
                                },
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: selectedTile != null
                                  ? _getPlaceholderImage(
                                      selectedTile.materialType)
                                  : const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                            )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => context.go('/subscription'),
                              child: Semantics(
                                label:
                                    'Upgrade to Pro for access to the tile database',
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/upgrade_to_pro.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        debugPrint(
                                            'Failed to load upgrade_to_pro.png, error: $error');
                                        return const Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Upgrade\nto Pro',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Flexible(
                          child: Text(
                            'Selected Tile: ${selectedTile?.name ?? "None"}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
                              print(
                                  "Tile selected: ${selectedTile.name}, Image URL: ${selectedTile.image}");
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
        // Tabs for Vertical and Horizontal Inputs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              VerticalCalculatorTab(
                user: user,
                canUseMultipleRafters: canUseMultipleRafts,
                canUseAdvancedOptions: canUseAdvancedOptions,
                canExport: canExport,
                canAccessDatabase: canAccessDatabase,
                initialInputs: _verticalInputs,
                onInputsConfirmed: (inputs, isValid) {
                  setState(() {
                    _verticalInputs = inputs;
                    _isVerticalInputsConfirmed = isValid;
                  });
                  _showSnackbar(
                    _isHorizontalInputsConfirmed
                        ? "Inputs saved successfully. Go to the Calculate button."
                        : "Inputs saved successfully. Add inputs from the Horizontal tab or go straight to the Calculate button.",
                  );
                },
              ),
              HorizontalCalculatorTab(
                user: user,
                canUseMultipleWidths: canUseMultipleRafts,
                canUseAdvancedOptions: canUseAdvancedOptions,
                canExport: canExport,
                canAccessDatabase: canAccessDatabase,
                initialInputs: _horizontalInputs,
                onInputsConfirmed: (inputs, isValid) {
                  setState(() {
                    _horizontalInputs = inputs;
                    _isHorizontalInputsConfirmed = isValid;
                  });
                  _showSnackbar(
                    _isVerticalInputsConfirmed
                        ? "Inputs saved successfully. Go to the Calculate button."
                        : "Inputs saved successfully. Add inputs from the Vertical tab or go straight to the Calculate button.",
                  );
                },
              ),
            ],
          ),
        ),
        // Calculate Buttons (shown only after inputs are confirmed)
        if (_isVerticalInputsConfirmed || _isHorizontalInputsConfirmed) ...[
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                if (_isVerticalInputsConfirmed)
                  _buildCalculateButton(
                    label: 'Calculate Vertical',
                    onPressed: () => _calculateVertical(user),
                  ),
                if (_isHorizontalInputsConfirmed)
                  _buildCalculateButton(
                    label: 'Calculate Horizontal',
                    onPressed: () => _calculateHorizontal(user),
                  ),
                if (_isVerticalInputsConfirmed && _isHorizontalInputsConfirmed)
                  _buildCalculateButton(
                    label: 'Calculate Combined',
                    onPressed: () => _calculateCombined(user),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildViewResultsStep(
      BuildContext context, UserModel user, double padding) {
    final calcState = ref.watch(calculatorProvider);
    final fontSize = MediaQuery.of(context).size.width >= 600 ? 16.0 : 14.0;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(padding),
          child: Semantics(
            label: 'Step 3 description',
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
                'Step 3: View Results',
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calculation Context Section
                _buildCalculationContext(context, fontSize),
                const SizedBox(height: 16),
                // Single Visualization with Toggle Buttons
                _buildVisualizationSection(context, calcState, fontSize),
                const SizedBox(height: 16),
                // Results Summary and Details
                if (calcState.verticalResult != null &&
                    _lastVerticalCalculationData != null)
                  _buildVerticalResultsSection(
                      context, calcState.verticalResult!, fontSize),
                if (calcState.horizontalResult != null &&
                    _lastHorizontalCalculationData != null)
                  _buildHorizontalResultsSection(
                      context, calcState.horizontalResult!, fontSize),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontSize: fontSize - 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = CalculatorStep.enterMeasurements;
                    ref.read(calculatorProvider.notifier).clearResults();
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (calcState.verticalResult != null &&
                  calcState.horizontalResult != null)
                ElevatedButton(
                  onPressed: () => _promptSaveCombinedResult(user),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Save Combined',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculationContext(BuildContext context, double fontSize) {
    return Consumer(
      builder: (context, ref, child) {
        final selectedTile =
            ref.watch(calculatorProvider.select((state) => state.selectedTile));

        List<Widget> contextRows = [];

        // Tile Information
        if (selectedTile != null) {
          contextRows.add(_infoRow('Tile Name', selectedTile.name));
          contextRows.add(
              _infoRow('Material Type', selectedTile.materialType.toString()));
          contextRows.add(
              _infoRow('Cover Width', '${selectedTile.tileCoverWidth} mm'));
          contextRows
              .add(_infoRow('Height', '${selectedTile.slateTileHeight} mm'));
        } else {
          contextRows.add(_infoRow('Tile Name', 'N/A'));
        }

        // Vertical Inputs
        if (_isVerticalInputsConfirmed) {
          contextRows.add(const Divider());
          contextRows.add(_infoRow(
              'Gutter Overhang', '${_verticalInputs.gutterOverhang} mm'));
          contextRows.add(_infoRow('Dry Ridge',
              _verticalInputs.useDryRidge == 'YES' ? 'Yes' : 'No'));
          for (int i = 0; i < _verticalInputs.rafterHeights.length; i++) {
            final rafter = _verticalInputs.rafterHeights[i];
            contextRows.add(_infoRow(
                rafter['label'] ?? 'Rafter ${i + 1}', '${rafter['value']} mm'));
          }
        }

        // Horizontal Inputs
        if (_isHorizontalInputsConfirmed) {
          contextRows.add(const Divider());
          for (int i = 0; i < _horizontalInputs.widths.length; i++) {
            final width = _horizontalInputs.widths[i];
            contextRows.add(_infoRow(
                width['label'] ?? 'Width ${i + 1}', '${width['value']} mm'));
          }
          contextRows.add(_infoRow('Dry Verge',
              _horizontalInputs.useDryVerge == 'YES' ? 'Yes' : 'No'));
          contextRows
              .add(_infoRow('Abutment Side', _horizontalInputs.abutmentSide));
          contextRows.add(_infoRow('Left Hand Tile',
              _horizontalInputs.useLHTile == 'YES' ? 'Yes' : 'No'));
          contextRows.add(_infoRow('Cross Bonded',
              _horizontalInputs.crossBonded == 'YES' ? 'Yes' : 'No'));
        }

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculation Context',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                ),
                const Divider(),
                ...contextRows,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisualizationSection(
      BuildContext context, CalculatorState calcState, double fontSize) {
    final hasVertical = calcState.verticalResult != null &&
        _lastVerticalCalculationData != null;
    final hasHorizontal = calcState.horizontalResult != null &&
        _lastHorizontalCalculationData != null;

    // Default to Combined if both are available, otherwise the available result
    final defaultMode = hasVertical && hasHorizontal
        ? ViewMode.combined
        : hasVertical
            ? ViewMode.vertical
            : ViewMode.horizontal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visualization',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            if (hasVertical || hasHorizontal)
              VisualizationWithToggle(
                verticalResult: calcState.verticalResult,
                horizontalResult: calcState.horizontalResult,
                gutterOverhang: _verticalInputs.gutterOverhang,
                defaultMode: defaultMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalResultsSection(
      BuildContext context, VerticalCalculationResult result, double fontSize) {
    // Summary Metrics
    List<Widget> summaryRows = [
      _infoRow('Total Courses', result.totalCourses.toString()),
      _infoRow('Gauge', '${result.gauge} mm'),
      if (result.splitGauge != null)
        _infoRow('Split Gauge', '${result.splitGauge} mm'),
    ];

    // Detailed Results for Each Rafter Height
    List<Widget> detailRows = [];
    for (int i = 0; i < _verticalInputs.rafterHeights.length; i++) {
      final rafter = _verticalInputs.rafterHeights[i];
      detailRows.add(_infoRow(
          rafter['label'] ?? 'Rafter ${i + 1}', '${rafter['value']} mm'));
      detailRows.add(_infoRow('Ridge Offset', '${result.ridgeOffset} mm'));
      if (result.eaveBatten != null) {
        detailRows.add(_infoRow('Eave Batten', '${result.eaveBatten} mm'));
      }
      detailRows.add(_infoRow('First Batten', '${result.firstBatten} mm'));
      if (result.cutCourse != null) {
        detailRows.add(_infoRow('Cut Course', '${result.cutCourse} mm'));
      }
      if (i < _verticalInputs.rafterHeights.length - 1) {
        detailRows.add(const Divider());
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vertical Calculation Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            // Summary
            Column(children: summaryRows),
            if (result.warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.warning!,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Expandable Details
            ExpansionTile(
              title: Text(
                'Detailed Results per Rafter',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(children: detailRows),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: 'Share Vertical Calculation',
                  child: OutlinedButton(
                    onPressed: widget.user!.isPro
                        ? () {}
                        : null, // TODO: Implement share
                    child: Text(
                      'Share',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
                if (widget.user!.isPro)
                  Semantics(
                    label: 'Save Vertical Calculation Result',
                    child: ElevatedButton(
                      onPressed: () => _promptSaveResult(
                          _lastVerticalCalculationData!, 'vertical'),
                      child: const Text('Save Result'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalResultsSection(BuildContext context,
      HorizontalCalculationResult result, double fontSize) {
    // Summary Metrics
    List<Widget> summaryRows = [
      _infoRow('New Width', '${result.newWidth} mm'),
      _infoRow('Marks', '${result.marks} mm'),
      if (result.splitMarks != null)
        _infoRow('Split Marks', '${result.splitMarks} mm'),
    ];

    // Detailed Results for Each Width
    List<Widget> detailRows = [];
    for (int i = 0; i < _horizontalInputs.widths.length; i++) {
      final width = _horizontalInputs.widths[i];
      detailRows.add(
          _infoRow(width['label'] ?? 'Width ${i + 1}', '${width['value']} mm'));
      if (result.lhOverhang != null) {
        detailRows.add(_infoRow('LH Overhang', '${result.lhOverhang} mm'));
      }
      if (result.rhOverhang != null) {
        detailRows.add(_infoRow('RH Overhang', '${result.rhOverhang} mm'));
      }
      if (result.cutTile != null) {
        detailRows.add(_infoRow('Cut Tile', '${result.cutTile} mm'));
      }
      detailRows.add(_infoRow('First Mark', '${result.firstMark} mm'));
      if (result.secondMark != null) {
        detailRows.add(_infoRow('Second Mark', '${result.secondMark} mm'));
      }
      if (i < _horizontalInputs.widths.length - 1) {
        detailRows.add(const Divider());
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Horizontal Calculation Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
            ),
            const Divider(),
            // Summary
            Column(children: summaryRows),
            if (result.warning != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        result.warning!,
                        style: TextStyle(fontSize: fontSize - 2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Expandable Details
            ExpansionTile(
              title: Text(
                'Detailed Results per Width',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(children: detailRows),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  label: 'Share Horizontal Calculation',
                  child: OutlinedButton(
                    onPressed: widget.user!.isPro
                        ? () {}
                        : null, // TODO: Implement share
                    child: Text(
                      'Share',
                      style: TextStyle(fontSize: fontSize - 2),
                    ),
                  ),
                ),
                if (widget.user!.isPro)
                  Semantics(
                    label: 'Save Horizontal Calculation Result',
                    child: ElevatedButton(
                      onPressed: () => _promptSaveResult(
                          _lastHorizontalCalculationData!, 'horizontal'),
                      child: const Text('Save Result'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculateButton(
      {required String label, required VoidCallback onPressed}) {
    return Semantics(
      label: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: ElevatedButton(
          onPressed: onPressed,
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
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
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
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return;
    }

    final List<double> rafterHeights = _verticalInputs.rafterHeights
        .map((entry) => entry['value'] as double)
        .toList();

    if (rafterHeights.isEmpty) {
      debugPrint('No rafter heights provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter at least one rafter height')),
      );
      return;
    }

    debugPrint('Rafter heights: $rafterHeights');
    final result = await ref
        .read(calculatorProvider.notifier)
        .calculateVertical(rafterHeights);
    debugPrint('Result from calculateVertical: $result');

    setState(() {
      _lastVerticalCalculationData = result;
      if (_lastHorizontalCalculationData != null) {
        _currentStep = CalculatorStep.viewResults;
      } else {
        _currentStep = CalculatorStep.viewResults;
      }
    });
  }

  void _calculateHorizontal(UserModel user) async {
    debugPrint('Starting _calculateHorizontal');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return;
    }

    final List<double> widths = _horizontalInputs.widths
        .map((entry) => entry['value'] as double)
        .toList();

    if (widths.isEmpty) {
      debugPrint('No widths provided');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one width')),
      );
      return;
    }

    debugPrint('Widths: $widths');
    final result =
        await ref.read(calculatorProvider.notifier).calculateHorizontal(widths);
    debugPrint('Result from calculateHorizontal: $result');

    setState(() {
      _lastHorizontalCalculationData = result;
      if (_lastVerticalCalculationData != null) {
        _currentStep = CalculatorStep.viewResults;
      } else {
        _currentStep = CalculatorStep.viewResults;
      }
    });
  }

  void _calculateCombined(UserModel user) async {
    debugPrint('Starting _calculateCombined');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a tile first')),
      );
      return;
    }

    final List<double> rafterHeights = _verticalInputs.rafterHeights
        .map((entry) => entry['value'] as double)
        .toList();
    final List<double> widths = _horizontalInputs.widths
        .map((entry) => entry['value'] as double)
        .toList();

    if (rafterHeights.isEmpty || widths.isEmpty) {
      debugPrint('Missing inputs for combined calculation');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both rafter heights and widths')),
      );
      return;
    }

    try {
      final result =
          await ref.read(calculationServiceProvider).calculateCombined(
                rafterHeights: rafterHeights,
                widths: widths,
                materialType: calculatorState.selectedTile!.materialTypeString,
                slateTileHeight: calculatorState.selectedTile!.slateTileHeight,
                maxGauge: calculatorState.selectedTile!.maxGauge,
                minGauge: calculatorState.selectedTile!.minGauge,
                tileCoverWidth: calculatorState.selectedTile!.tileCoverWidth,
                minSpacing: calculatorState.selectedTile!.minSpacing,
                maxSpacing: calculatorState.selectedTile!.maxSpacing,
                lhTileWidth: calculatorState.selectedTile!.leftHandTileWidth ??
                    calculatorState.selectedTile!.tileCoverWidth,
                gutterOverhang: _verticalInputs.gutterOverhang,
                useDryRidge: _verticalInputs.useDryRidge,
                useDryVerge: _horizontalInputs.useDryVerge,
                abutmentSide: _horizontalInputs.abutmentSide,
                useLHTile: _horizontalInputs.useLHTile,
                crossBonded: _horizontalInputs.crossBonded,
              );

      debugPrint('Combined calculation result: $result');

      // Update state with both results
      ref.read(calculatorProvider.notifier).updateState(
            verticalResult:
                VerticalCalculationResult.fromJson(result['verticalResult']),
            horizontalResult: HorizontalCalculationResult.fromJson(
                result['horizontalResult']),
          );

      setState(() {
        _lastVerticalCalculationData = {
          'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
          'inputs': {
            'rafterHeights': _verticalInputs.rafterHeights,
            'gutterOverhang': _verticalInputs.gutterOverhang,
            'useDryRidge': _verticalInputs.useDryRidge,
          },
          'outputs': result['verticalResult'],
          'tile': calculatorState.selectedTile!.toJson(),
        };
        _lastHorizontalCalculationData = {
          'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
          'inputs': {
            'widths': _horizontalInputs.widths,
            'useDryVerge': _horizontalInputs.useDryVerge,
            'abutmentSide': _horizontalInputs.abutmentSide,
            'useLHTile': _horizontalInputs.useLHTile,
            'crossBonded': _horizontalInputs.crossBonded,
          },
          'outputs': result['horizontalResult'],
          'tile': calculatorState.selectedTile!.toJson(),
        };
        _currentStep = CalculatorStep.viewResults;
      });
    } catch (e) {
      debugPrint('Error in combined calculation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to calculate: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _promptSaveResult(Map<String, dynamic> calculationData, String type) {
    final TextEditingController projectNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Calculation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Would you like to save this calculation result?'),
            const SizedBox(height: 16),
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Skip saving
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              if (projectNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a project name'),
                  ),
                );
                return;
              }
              final updatedCalculationData =
                  Map<String, dynamic>.from(calculationData);
              updatedCalculationData['projectName'] =
                  projectNameController.text.trim();
              await _saveResult(widget.user!, updatedCalculationData, type);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _promptSaveCombinedResult(UserModel user) {
    final TextEditingController projectNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Combined Calculation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Would you like to save this combined calculation result?'),
            const SizedBox(height: 16),
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context), // Skip saving
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              if (projectNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a project name'),
                  ),
                );
                return;
              }
              final combinedCalculationData = {
                'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
                'inputs': {
                  'vertical_inputs': _lastVerticalCalculationData!['inputs'],
                  'horizontal_inputs':
                      _lastHorizontalCalculationData!['inputs'],
                },
                'outputs': {
                  'vertical': _lastVerticalCalculationData!['outputs'],
                  'horizontal': _lastHorizontalCalculationData!['outputs'],
                },
                'tile': _lastVerticalCalculationData!['tile'],
                'projectName': projectNameController.text.trim(),
              };
              await _saveResult(user, combinedCalculationData, 'combined');
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResult(
      UserModel user, Map<String, dynamic> calculationData, String type) async {
    // Wait for HiveService initialization to complete
    await ref.read(hiveServiceInitializerProvider.future);

    final calculationId = calculationData['id'] as String? ??
        'calc_${user.id}_${DateTime.now().millisecondsSinceEpoch}';
    final savedResult = SavedResult(
      id: calculationId,
      userId: user.id,
      projectName: calculationData['projectName'] ?? '',
      type: type == 'vertical'
          ? CalculationType.vertical
          : type == 'horizontal'
              ? CalculationType.horizontal
              : CalculationType.combined,
      timestamp: DateTime.now(),
      inputs: calculationData['inputs'] as Map<String, dynamic>,
      outputs: calculationData['outputs'] as Map<String, dynamic>,
      tile: calculationData['tile'] as Map<String, dynamic>,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to the calculations collection
    debugPrint('Saving calculation to Firestore: $calculationId');
    try {
      await ref.read(calculationServiceProvider).saveCalculation(
            id: calculationId,
            userId: user.id,
            tileId: savedResult.tile['id'] as String,
            type: type,
            inputs: calculationData['inputs'] as Map<String, dynamic>,
            result: calculationData['outputs'] as Map<String, dynamic>,
            tile: calculationData['tile'] as Map<String, dynamic>,
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
