import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roofgrid_uk/models/user_model.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/providers/developer_mode_provider.dart';
import 'package:roofgrid_uk/screens/calculator/enter_measurements_step.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';
import 'package:roofgrid_uk/utils/saved_result_inputs.dart';
import 'package:roofgrid_uk/screens/calculator/view_results_step.dart';
import 'package:roofgrid_uk/widgets/main_drawer.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_input_visibility.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';
import 'package:roofgrid_uk/app/calculator/providers/calculator_provider.dart';
import 'package:roofgrid_uk/app/results/models/saved_result.dart';
import 'package:roofgrid_uk/app/results/providers/results_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import 'package:roofgrid_uk/widgets/app_header.dart';
import 'package:roofgrid_uk/widgets/save_result_dialog.dart';

// Define CalculatorStep enum for step-based flow
enum CalculatorStep {
  confirmTile,
  enterMeasurements,
  viewResults,
}

class CalculatorScreen extends ConsumerWidget {
  final SavedResult? savedResult;
  final CalculationTypeSelection? initialMode;

  const CalculatorScreen({
    super.key,
    this.savedResult,
    this.initialMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userAsync = ref.watch(currentUserProvider);

    if (!authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // print("User not authenticated, redirecting to /auth/login"); // removed for prod
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
        initialMode: initialMode,
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
  final CalculationTypeSelection? initialMode;

  const CalculatorContent({
    super.key,
    required this.user,
    this.savedResult,
    this.initialMode,
  });

  @override
  ConsumerState<CalculatorContent> createState() => _CalculatorContentState();
}

class _CalculatorContentState extends ConsumerState<CalculatorContent> {
  bool _isOnline = true;
  bool _hasRedirectedToTileSelect = false;
  bool _tileSelectScheduled = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  CalculatorStep _currentStep = CalculatorStep.confirmTile;
  CalculationTypeSelection? _calculationType;
  VerticalInputs _verticalInputs = VerticalInputs();
  HorizontalInputs _horizontalInputs = HorizontalInputs();
  Map<String, dynamic>? _lastVerticalCalculationData;
  Map<String, dynamic>? _lastHorizontalCalculationData;

  @override
  void initState() {
    super.initState();
    if (widget.savedResult != null) {
      final savedResult = normalizeSavedResult(widget.savedResult!);
      final savedTile = TileModel.fromJson(savedResult.tile);
      _calculationType = calculationTypeFromSavedResult(savedResult.type);

      final verticalInputs =
          savedResult.inputs['vertical_inputs'] as Map<String, dynamic>?;
      final horizontalInputs =
          savedResult.inputs['horizontal_inputs'] as Map<String, dynamic>?;

      if (_calculationType == CalculationTypeSelection.verticalOnly ||
          _calculationType == CalculationTypeSelection.both) {
        _verticalInputs = VerticalInputs(
          rafterHeights: (verticalInputs?['rafterHeights'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          gutterOverhang: (verticalInputs?['gutterOverhang'] as num?)
                  ?.toDouble() ??
              50.0,
          useDryRidge: verticalInputs?['useDryRidge'] as String? ?? 'NO',
        );
      }

      if (_calculationType == CalculationTypeSelection.horizontalOnly ||
          _calculationType == CalculationTypeSelection.both) {
        _horizontalInputs = HorizontalInputs(
          widths: (horizontalInputs?['widths'] as List<dynamic>?)
                  ?.map((item) => item as Map<String, dynamic>)
                  .toList() ??
              [],
          useDryVerge: horizontalInputs?['useDryVerge'] as String? ?? 'NO',
          abutmentSide:
              horizontalInputs?['abutmentSide'] as String? ?? 'NONE',
          useLHTile: horizontalInputs?['useLHTile'] as String? ?? 'NO',
          crossBonded: resolveCrossBonded(
            saved: horizontalInputs?['crossBonded'] as String?,
            tile: savedTile,
          ),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(calculatorProvider.notifier).setTile(savedTile);
        _hydrateProviderFromInputs();
      });

      _resetModeScopedCalculationData(_calculationType!);
      _currentStep = CalculatorStep.enterMeasurements;
      _hasRedirectedToTileSelect = true;
    } else if (widget.initialMode != null) {
      _setCalculationMode(widget.initialMode!);
      _scheduleTileSelection();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/home');
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(calculatorProvider.notifier).clearResults();
      final mode = _calculationType;
      if (mode != null && widget.savedResult == null) {
        ref.read(calculatorProvider.notifier).resetOptionsForMode(mode);
        _hydrateProviderFromInputs();
      }
    });

    // Check initial connectivity
    _checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() {
        _isOnline = isOnlineFromResults(result);
      });
      if (_isOnline) {
        ref.read(calculationServiceProvider).syncCalculations();
      }
    });
  }

  @override
  void didUpdateWidget(CalculatorContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.savedResult != null) return;

    final newMode = widget.initialMode;
    if (newMode == null || newMode == _calculationType) return;

    _applyCalculationMode(newMode);
  }

  void _setCalculationMode(CalculationTypeSelection mode) {
    _calculationType = mode;
    _resetModeScopedCalculationData(mode);
    if (_currentStep == CalculatorStep.viewResults) {
      _currentStep = CalculatorStep.enterMeasurements;
    }
  }

  void _applyCalculationMode(CalculationTypeSelection mode) {
    setState(() => _setCalculationMode(mode));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(calculatorProvider.notifier).clearResults();
      ref.read(calculatorProvider.notifier).resetOptionsForMode(mode);
      _hydrateProviderFromInputs();
    });
  }

  void _hydrateProviderFromInputs() {
    final mode = _calculationType;
    if (mode == null) return;

    ref.read(calculatorProvider.notifier).hydrateCalculatorOptionsFromInputs(
          vertical: includesVertical(mode) ? _verticalInputs : null,
          horizontal: includesHorizontal(mode) ? _horizontalInputs : null,
        );
  }

  void _resetModeScopedCalculationData(CalculationTypeSelection mode) {
    if (mode == CalculationTypeSelection.verticalOnly) {
      _horizontalInputs = HorizontalInputs();
      _lastHorizontalCalculationData = null;
    } else if (mode == CalculationTypeSelection.horizontalOnly) {
      _verticalInputs = VerticalInputs();
      _lastVerticalCalculationData = null;
    }
  }

  Future<void> _openTileSelection() async {
    try {
      final selectedTile = await context.push('/calculator/tile-select');
      if (!mounted) return;
      if (selectedTile != null && selectedTile is TileModel) {
        ref.read(calculatorProvider.notifier).setTile(selectedTile);
        setState(() {
          _horizontalInputs = _horizontalInputs.copyWith(
            crossBonded: crossBondedFromTile(selectedTile),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(
        'Error selecting tile: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  void _scheduleTileSelection() {
    if (_tileSelectScheduled || _hasRedirectedToTileSelect) return;
    _tileSelectScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final selectedTile = await context.push('/calculator/tile-select');
        if (!mounted) return;
        if (selectedTile != null && selectedTile is TileModel) {
          ref.read(calculatorProvider.notifier).setTile(selectedTile);
          setState(() {
            _horizontalInputs = _horizontalInputs.copyWith(
              crossBonded: crossBondedFromTile(selectedTile),
            );
            _currentStep = CalculatorStep.enterMeasurements;
            _hasRedirectedToTileSelect = true;
          });
        } else {
          context.go('/home');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting tile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        context.go('/home');
      }
    });
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
    _connectivitySubscription?.cancel();
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
        // print("User data not found, redirecting to /auth/login"); // removed for prod
        context.go('/auth/login');
      });
      return const Scaffold(
        body: Center(child: Text('User data not found. Please sign in again.')),
      );
    }

    final user = widget.user!;
    final effectiveIsPro = ref.watch(effectiveIsProProvider);

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
                child: _buildStepContent(context, user, effectiveIsPro),
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
                  // print("Showing error message: $errorMessage"); // removed for prod
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
    );
  }

  Widget _buildStepContent(
      BuildContext context, UserModel user, bool effectiveIsPro) {
    switch (_currentStep) {
      case CalculatorStep.confirmTile:
        return const Center(child: CircularProgressIndicator());
      case CalculatorStep.enterMeasurements:
        return EnterMeasurementsStep(
          key: ValueKey(_calculationType),
          user: user,
          effectiveIsPro: effectiveIsPro,
          calculationType: _calculationType!,
          initialVerticalInputs: _verticalInputs,
          initialHorizontalInputs: _horizontalInputs,
          onBackToTileSelect: _openTileSelection,
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
          existingSavedResultId: widget.savedResult?.id,
          existingProjectName: widget.savedResult?.projectName,
          onBack: () {
            setState(() {
              _currentStep = CalculatorStep.enterMeasurements;
              ref.read(calculatorProvider.notifier).clearResults();
            });
          },
          onSaveCombined: (user) => _promptSaveCombinedResult(user),
          onSaveResult: (user, calculationData, type, {saveAction = SaveResultAction.saveAsNew}) =>
              _saveResult(
            user,
            calculationData,
            type,
            saveAction: saveAction,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showCalculatorInfo(BuildContext context) {
    final mode = _calculationType;
    final title = mode == null
        ? 'Roofing Calculator'
        : calculationTypeLabel(mode);
    final description = switch (mode) {
      CalculationTypeSelection.verticalOnly =>
        'Determine batten gauge (spacing) from rafter heights.',
      CalculationTypeSelection.horizontalOnly =>
        'Determine tile marking out from width measurements.',
      CalculationTypeSelection.both =>
        'Full roof layout — vertical batten gauge and horizontal tile set-out.',
      null => 'Select a calculation type from the home screen to begin.',
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description),
              const SizedBox(height: 16),
              Text(
                'How to use:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              switch (mode) {
                CalculationTypeSelection.verticalOnly => const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Select a tile type'),
                      Text(
                          '2. Enter rafter height(s) — fascia top to ridge'),
                      Text('3. Tap Calculate'),
                      Text('4. View your batten gauge and results'),
                    ],
                  ),
                CalculationTypeSelection.horizontalOnly => const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Select a tile type'),
                      Text(
                          '2. Enter width(s) — verge to verge before overhangs'),
                      Text('3. Tap Calculate'),
                      Text('4. View your tile spacing and results'),
                    ],
                  ),
                CalculationTypeSelection.both => const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Select a tile type'),
                      Text('2. Enter rafter heights, then widths'),
                      Text('3. Tap Calculate'),
                      Text('4. View combined vertical and horizontal results'),
                    ],
                  ),
                null => const SizedBox.shrink(),
              },
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

    if (_verticalInputs.rafterHeights.isEmpty) {
      debugPrint('No rafter heights provided');
      _showSnackbar('Please enter at least one rafter height',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    final result = await ref
        .read(calculatorProvider.notifier)
        .calculateVertical(_verticalInputs);
    debugPrint('Result from calculateVertical: $result');
    setState(() {
      _lastVerticalCalculationData = result;
      _lastHorizontalCalculationData = null;
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

    if (_horizontalInputs.widths.isEmpty) {
      debugPrint('No widths provided');
      _showSnackbar('Please enter at least one width',
          backgroundColor: Theme.of(context).colorScheme.error);
      return;
    }

    final result = await ref
        .read(calculatorProvider.notifier)
        .calculateHorizontal(_horizontalInputs);
    debugPrint('Result from calculateHorizontal: $result');
    setState(() {
      _lastHorizontalCalculationData = result;
      _lastVerticalCalculationData = null;
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

  Future<void> _promptSaveCombinedResult(UserModel user) async {
    final dialogResult = await showSaveResultDialog(
      context: context,
      title: 'Save Combined Calculation',
      initialProjectName: widget.savedResult?.projectName,
      allowUpdateExisting: widget.savedResult != null,
    );
    if (dialogResult == null) return;

    final combinedCalculationData = <String, dynamic>{
      'id': dialogResult.action == SaveResultAction.updateExisting &&
              widget.savedResult != null
          ? widget.savedResult!.id
          : 'calc_${DateTime.now().millisecondsSinceEpoch}',
      'inputs': {
        'vertical_inputs': _lastVerticalCalculationData!['inputs'],
        'horizontal_inputs': _lastHorizontalCalculationData!['inputs'],
      },
      'outputs': {
        'vertical': _lastVerticalCalculationData!['outputs'],
        'horizontal': _lastHorizontalCalculationData!['outputs'],
      },
      'tile': _lastVerticalCalculationData!['tile'],
      'projectName': dialogResult.projectName,
    };

    await _saveResult(
      user,
      combinedCalculationData,
      'combined',
      saveAction: dialogResult.action,
    );
  }

  Future<SavedResult?> _saveResult(
    UserModel user,
    Map<String, dynamic> calculationData,
    String type, {
    SaveResultAction saveAction = SaveResultAction.saveAsNew,
  }) async {
    if (widget.savedResult?.type == CalculationType.combined &&
        type != 'combined') {
      _showSnackbar(
        'Use Save Combined to update this job',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return null;
    }

    // Wait for HiveService initialization to complete
    await ref.read(hiveServiceInitializerProvider.future);

    final isUpdate = saveAction == SaveResultAction.updateExisting &&
        widget.savedResult != null;
    final now = DateTime.now();
    final calculationId = isUpdate
        ? widget.savedResult!.id
        : (calculationData['id'] as String? ??
            'calc_${user.id}_${now.millisecondsSinceEpoch}');
    final normalizedInputs = normalizeCalculationInputsForSave(
      type,
      Map<String, dynamic>.from(
        calculationData['inputs'] as Map<String, dynamic>,
      ),
    );

    final savedResult = SavedResult(
      id: calculationId,
      userId: user.id,
      projectName: calculationData['projectName'] ?? '',
      type: type == 'vertical'
          ? CalculationType.vertical
          : type == 'horizontal'
              ? CalculationType.horizontal
              : CalculationType.combined,
      timestamp: now,
      inputs: normalizedInputs,
      outputs: calculationData['outputs'] as Map<String, dynamic>,
      tile: calculationData['tile'] as Map<String, dynamic>,
      createdAt: isUpdate ? widget.savedResult!.createdAt : now,
      updatedAt: now,
    );

    // Save to the calculations collection
    debugPrint('Saving calculation to Firestore: $calculationId');
    try {
      await ref.read(calculationServiceProvider).saveCalculation(
            id: calculationId,
            userId: user.id,
            tileId: savedResult.tile['id'] as String,
            type: type,
            inputs: normalizedInputs,
            result: calculationData['outputs'] as Map<String, dynamic>,
            tile: calculationData['tile'] as Map<String, dynamic>,
            success: (calculationData['outputs']
                    as Map<String, dynamic>)['solution'] !=
                'Invalid',
          );
    } catch (e) {
      debugPrint('Error saving calculation: $e');
      if (mounted) {
        _showSnackbar('Failed to save calculation: $e',
            backgroundColor: Theme.of(context).colorScheme.error);
      }
    }

    var savedToCloud = false;
    try {
      debugPrint('Saving result to Firestore: ${savedResult.id}');
      if (isUpdate) {
        await ref.read(resultsServiceProvider).updateResult(savedResult);
      } else {
        await ref.read(resultsServiceProvider).saveResult(user.id, savedResult);
      }
      savedToCloud = true;
    } catch (e) {
      debugPrint('Error saving result to Firestore: $e');
    }

    var savedLocally = false;
    try {
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.resultsBox.put(savedResult.id, savedResult);
      savedLocally = true;
    } catch (e) {
      debugPrint('Error saving to Hive: $e');
    }

    if (!savedToCloud && !savedLocally) {
      if (mounted) {
        _showSnackbar(
          'Failed to save result',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
      return null;
    }

    if (mounted) {
      final actionLabel = isUpdate ? 'Updated' : 'Saved';
      final cloudNote = savedToCloud
          ? ''
          : ' (offline only — cloud sync failed)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionLabel "${savedResult.projectName}"$cloudNote'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              context.push('/result-detail', extra: savedResult);
            },
          ),
        ),
      );
    }
    return savedResult;
  }
}
