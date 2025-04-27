import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/screens/calculator/select_calculation_type_step.dart';
import 'package:roofgrid_uk/screens/calculator/enter_measurements_step.dart';
import 'package:roofgrid_uk/screens/calculator/view_results_step.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';
import 'package:roofgrid_uk/widgets/bottom_nav_bar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/widgets/app_header.dart';

// Define CalculatorStep enum for step-based flow
enum CalculatorStep {
  confirmTile,
  selectCalculationType,
  enterMeasurements,
  viewResults,
}

// Enum for calculation type selection
enum CalculationTypeSelection {
  verticalOnly,
  horizontalOnly,
  both,
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

class _CalculatorContentState extends ConsumerState<CalculatorContent> {
  bool _isOnline = true;
  bool _hasRedirectedToTileSelect = false;
  CalculatorStep _currentStep = CalculatorStep.confirmTile;
  CalculationTypeSelection? _calculationType;
  VerticalInputs _verticalInputs = VerticalInputs();
  HorizontalInputs _horizontalInputs = HorizontalInputs();
  Map<String, dynamic>? _lastVerticalCalculationData;
  Map<String, dynamic>? _lastHorizontalCalculationData;

  @override
  void initState() {
    super.initState();
    // Initialize inputs from savedResult, if present
    if (widget.savedResult != null) {
      if (widget.savedResult!.type == CalculationType.vertical) {
        _calculationType = CalculationTypeSelection.verticalOnly;
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
      } else if (widget.savedResult!.type == CalculationType.horizontal) {
        _calculationType = CalculationTypeSelection.horizontalOnly;
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
      } else if (widget.savedResult!.type == CalculationType.combined) {
        _calculationType = CalculationTypeSelection.both;
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
      }
      // Skip to enterMeasurements if editing a saved result
      _currentStep = CalculatorStep.enterMeasurements;
      _hasRedirectedToTileSelect = true;
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
    super.dispose();
  }

  void _showSnackbar(String message, {Color backgroundColor = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: backgroundColor,
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

    final user = widget.user!;

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
              _currentStep = CalculatorStep.selectCalculationType;
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

    return Scaffold(
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          Column(
            children: [
              AppHeader(
                title: widget.savedResult != null
                    ? 'Edit Calculation: ${widget.savedResult!.projectName}'
                    : 'Roofing Calculator',
                actions: [
                  Semantics(
                    label: 'Show calculator information',
                    child: IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: () => _showCalculatorInfo(context),
                      tooltip: 'Show calculator information',
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _buildStepContent(context, user),
              ),
            ],
          ),
          // Isolate error message handling to reduce rebuild scope
          Consumer(
            builder: (context, ref, child) {
              final errorMessage = ref.watch(
                  calculatorProvider.select((state) => state.errorMessage));
              if (errorMessage != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  print("Showing error message: $errorMessage");
                  _showSnackbar(errorMessage,
                      backgroundColor: Theme.of(context).colorScheme.error);
                  ref.read(calculatorProvider.notifier).clearResults();
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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
              _showSnackbar('Upgrade to Pro to access this feature',
                  backgroundColor: Theme.of(context).colorScheme.error);
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
              _showSnackbar('Upgrade to Pro to access this feature',
                  backgroundColor: Theme.of(context).colorScheme.error);
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
    );
  }

  Widget _buildStepContent(BuildContext context, UserModel user) {
    switch (_currentStep) {
      case CalculatorStep.confirmTile:
        return const Center(child: CircularProgressIndicator());
      case CalculatorStep.selectCalculationType:
        return SelectCalculationTypeStep(
          onTypeSelected: (type) {
            setState(() {
              _calculationType = type;
              _currentStep = CalculatorStep.enterMeasurements;
            });
          },
        ).animate().fadeIn(duration: 600.ms);
      case CalculatorStep.enterMeasurements:
        return EnterMeasurementsStep(
          user: user,
          calculationType: _calculationType!,
          initialVerticalInputs: _verticalInputs,
          initialHorizontalInputs: _horizontalInputs,
          onChangeType: () {
            setState(() {
              _currentStep = CalculatorStep.selectCalculationType;
            });
          },
          onCalculate: (verticalInputs, horizontalInputs) {
            setState(() {
              _verticalInputs = verticalInputs;
              _horizontalInputs = horizontalInputs;
            });
            switch (_calculationType) {
              case CalculationTypeSelection.verticalOnly:
                _calculateVertical(user);
                break;
              case CalculationTypeSelection.horizontalOnly:
                _calculateHorizontal(user);
                break;
              case CalculationTypeSelection.both:
                _calculateCombined(user);
                break;
              default:
                break;
            }
          },
          placeholderImageBuilder: _getPlaceholderImage,
        ).animate().fadeIn(duration: 600.ms);
      case CalculatorStep.viewResults:
        return ViewResultsStep(
          user: user,
          verticalInputs: _verticalInputs,
          horizontalInputs: _horizontalInputs,
          calculationType: _calculationType!,
          lastVerticalCalculationData: _lastVerticalCalculationData,
          lastHorizontalCalculationData: _lastHorizontalCalculationData,
          onBack: () {
            setState(() {
              _currentStep = CalculatorStep.enterMeasurements;
              ref.read(calculatorProvider.notifier).clearResults();
            });
          },
          onSaveCombined: (user) => _promptSaveCombinedResult(user),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCalculatorInfo(BuildContext context) {
    final isVertical =
        _calculationType == CalculationTypeSelection.verticalOnly;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isVertical ? 'Vertical Calculator' : 'Horizontal Calculator',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isVertical
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
              isVertical
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

  Future<void> _calculateVertical(UserModel user) async {
    debugPrint('Starting _calculateVertical');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      _showSnackbar('Please select a tile first',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    final List<double> rafterHeights = _verticalInputs.rafterHeights
        .map((entry) => entry['value'] as double)
        .toList();
    if (rafterHeights.isEmpty) {
      debugPrint('No rafter heights provided');
      _showSnackbar('Please enter at least one rafter height',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    debugPrint('Rafter heights: $rafterHeights');
    final result = await ref
        .read(calculatorProvider.notifier)
        .calculateVertical(rafterHeights);
    debugPrint('Result from calculateVertical: $result');
    setState(() {
      _lastVerticalCalculationData = result;
      _currentStep = CalculatorStep.viewResults;
    });
  }

  Future<void> _calculateHorizontal(UserModel user) async {
    debugPrint('Starting _calculateHorizontal');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      _showSnackbar('Please select a tile first',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    final List<double> widths = _horizontalInputs.widths
        .map((entry) => entry['value'] as double)
        .toList();
    if (widths.isEmpty) {
      debugPrint('No widths provided');
      _showSnackbar('Please enter at least one width',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    debugPrint('Widths: $widths');
    final result =
        await ref.read(calculatorProvider.notifier).calculateHorizontal(widths);
    debugPrint('Result from calculateHorizontal: $result');
    setState(() {
      _lastHorizontalCalculationData = result;
      _currentStep = CalculatorStep.viewResults;
    });
  }

  Future<void> _calculateCombined(UserModel user) async {
    debugPrint('Starting _calculateCombined');
    final calculatorState = ref.read(calculatorProvider);
    debugPrint('Selected tile: ${calculatorState.selectedTile?.name}');
    if (calculatorState.selectedTile == null) {
      debugPrint('No tile selected');
      _showSnackbar('Please select a tile first',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    // Validate required tile properties
    final tile = calculatorState.selectedTile!;
    final invalidFields = [];

    // Check for invalid values (must be greater than 0)
    if (tile.slateTileHeight <= 0) invalidFields.add('slateTileHeight');
    if (tile.maxGauge <= 0) invalidFields.add('maxGauge');
    if (tile.minGauge <= 0) invalidFields.add('minGauge');
    if (tile.tileCoverWidth <= 0) invalidFields.add('tileCoverWidth');
    if (tile.minSpacing <= 0) invalidFields.add('minSpacing');
    if (tile.maxSpacing <= 0) invalidFields.add('maxSpacing');

    if (invalidFields.isNotEmpty) {
      final errorMessage =
          'Tile "${tile.name}" has invalid properties (must be greater than 0): ${invalidFields.join(", ")}';
      debugPrint(errorMessage);
      _showSnackbar(errorMessage,
          backgroundColor: Theme.of(context).colorScheme.error);
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
      _showSnackbar('Please enter both rafter heights and widths',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    try {
      final result =
          await ref.read(calculationServiceProvider).calculateCombined(
                rafterHeights: rafterHeights,
                widths: widths,
                materialType: tile.materialTypeString,
                slateTileHeight: tile.slateTileHeight,
                maxGauge: tile.maxGauge,
                minGauge: tile.minGauge,
                tileCoverWidth: tile.tileCoverWidth,
                minSpacing: tile.minSpacing,
                maxSpacing: tile.maxSpacing,
                lhTileWidth: tile.leftHandTileWidth ?? tile.tileCoverWidth,
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
      _showSnackbar('Failed to calculate: $e',
          backgroundColor: Theme.of(context).colorScheme.error);
    }
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
                _showSnackbar('Please enter a project name',
                    backgroundColor: Theme.of(context).colorScheme.error);
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
        _showSnackbar('Failed to save calculation: $e',
            backgroundColor: Theme.of(context).colorScheme.error);
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
          _showSnackbar('Saved to Firestore, but failed to save offline: $e',
              backgroundColor: Theme.of(context).colorScheme.error);
        }
      }
      if (mounted) {
        _showSnackbar('Calculation result saved successfully');
      }
    } catch (e) {
      debugPrint('Error saving result: $e');
      if (mounted) {
        _showSnackbar('Failed to save result: $e',
            backgroundColor: Theme.of(context).colorScheme.error);
      }
    }
  }
}
