import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/app/calculator/services/calculation_service.dart';
import 'package:roofgrid_uk/providers/auth_provider.dart';
import 'package:roofgrid_uk/services/hive_service.dart';
import '../../../models/calculator/horizontal_calculation_input.dart';
import '../../../models/calculator/horizontal_calculation_result.dart';
import '../../../models/calculator/vertical_calculation_input.dart';
import '../../../models/calculator/vertical_calculation_result.dart';
import '../services/horizontal_calculation_service.dart';
import '../services/vertical_calculation_service.dart';

// State class for calculator
class CalculatorState {
  final TileModel? selectedTile;
  final bool isLoading;
  final String? errorMessage;
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;
  final double gutterOverhang;
  final String useDryRidge;
  final String useDryVerge;
  final String abutmentSide;
  final String useLHTile;
  final String crossBonded;

  CalculatorState({
    this.selectedTile,
    this.isLoading = false,
    this.errorMessage,
    this.verticalResult,
    this.horizontalResult,
    this.gutterOverhang = 50,
    this.useDryRidge = 'NO',
    this.useDryVerge = 'NO',
    this.abutmentSide = 'NONE',
    this.useLHTile = 'NO',
    this.crossBonded = 'NO',
  });

  CalculatorState copyWith({
    TileModel? selectedTile,
    bool? isLoading,
    String? errorMessage,
    VerticalCalculationResult? verticalResult,
    HorizontalCalculationResult? horizontalResult,
    double? gutterOverhang,
    String? useDryRidge,
    String? useDryVerge,
    String? abutmentSide,
    String? useLHTile,
    String? crossBonded,
  }) {
    return CalculatorState(
      selectedTile: selectedTile ?? this.selectedTile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      verticalResult: verticalResult ?? this.verticalResult,
      horizontalResult: horizontalResult ?? this.horizontalResult,
      gutterOverhang: gutterOverhang ?? this.gutterOverhang,
      useDryRidge: useDryRidge ?? this.useDryRidge,
      useDryVerge: useDryVerge ?? this.useDryVerge,
      abutmentSide: abutmentSide ?? this.abutmentSide,
      useLHTile: useLHTile ?? this.useLHTile,
      crossBonded: crossBonded ?? this.crossBonded,
    );
  }

  CalculatorState clearResults() {
    return CalculatorState(
      selectedTile: selectedTile,
      gutterOverhang: gutterOverhang,
      useDryRidge: useDryRidge,
      useDryVerge: useDryVerge,
      abutmentSide: abutmentSide,
      useLHTile: useLHTile,
      crossBonded: crossBonded,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final CalculationService _calculationService;
  final String? _userId;
  final HiveService _hiveService = HiveService();
  final Ref _ref;

  CalculatorNotifier(this._calculationService, this._userId, this._ref)
      : super(CalculatorState()) {
    _loadLastSelectedTile();
  }

  void _loadLastSelectedTile() {
    if (_userId != null) {
      // Fix: Get the actual UserModel from the provider
      final user = _ref.read(currentUserProvider).value;
      if (user != null && (user.isPro || user.isAdmin)) {
        final lastTile = _hiveService.getLastSelectedTile();
        if (lastTile != null) {
          state = state.copyWith(selectedTile: lastTile);
        }
      }
    }
  }

  void setTile(TileModel tile) {
    state = state.copyWith(selectedTile: tile).clearResults();
    if (_userId != null) {
      _hiveService.saveLastSelectedTile(tile);
    }
  }

  void setGutterOverhang(double value) {
    state = state.copyWith(gutterOverhang: value).clearResults();
  }

  void setUseDryRidge(String value) {
    state = state.copyWith(useDryRidge: value).clearResults();
  }

  void setUseDryVerge(String value) {
    state = state.copyWith(useDryVerge: value).clearResults();
  }

  void setAbutmentSide(String value) {
    state = state.copyWith(abutmentSide: value).clearResults();
  }

  void setUseLHTile(String value) {
    state = state.copyWith(useLHTile: value).clearResults();
  }

  void setCrossBonded(String value) {
    state = state.copyWith(crossBonded: value).clearResults();
  }

  Future<Map<String, dynamic>?> calculateVertical(
      List<double> rafterHeights) async {
    debugPrint('Starting calculateVertical in CalculatorNotifier');
    if (state.selectedTile == null) {
      debugPrint('No tile selected');
      state = state.copyWith(
        errorMessage: 'Please select a tile before calculating',
      );
      return null;
    }

    if (_userId == null) {
      debugPrint('User not authenticated');
      state = state.copyWith(
        errorMessage: 'User not authenticated',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final input = VerticalCalculationInput(
      rafterHeights: rafterHeights,
      gutterOverhang: state.gutterOverhang,
      useDryRidge: state.useDryRidge,
    );

    debugPrint('Calling VerticalCalculationService.calculateVertical');
    final result = VerticalCalculationService.calculateVertical(
      input: input,
      materialType: state.selectedTile!.materialTypeString,
      slateTileHeight: state.selectedTile!.slateTileHeight,
      maxGauge: state.selectedTile!.maxGauge,
      minGauge: state.selectedTile!.minGauge,
    );
    debugPrint('Result from calculateVertical: $result');

    // Prepare calculation data
    final calculationId =
        'calc_${_userId}_${DateTime.now().millisecondsSinceEpoch}';
    final inputsMap = {
      'rafterHeights': rafterHeights
          .asMap()
          .entries
          .map((entry) => {
                'label': 'Rafter ${entry.key + 1}',
                'value': entry.value,
              })
          .toList(),
      'gutterOverhang': state.gutterOverhang,
      'useDryRidge': state.useDryRidge,
    };

    final resultMap = {
      'totalCourses': result.totalCourses,
      'ridgeOffset': result.ridgeOffset,
      'underEaveBatten': result.underEaveBatten,
      'eaveBatten': result.eaveBatten,
      'firstBatten': result.firstBatten,
      'cutCourse': result.cutCourse,
      'gauge': result.gauge,
      'splitGauge': result.splitGauge,
      'warning': result.warning,
    };

    final tileMap = {
      'id': state.selectedTile!.id,
      'name': state.selectedTile!.name,
      'materialType': state.selectedTile!.materialTypeString,
      'tileCoverWidth': state.selectedTile!.tileCoverWidth,
      'slateTileHeight': state.selectedTile!.slateTileHeight,
      'minGauge': state.selectedTile!.minGauge,
      'maxGauge': state.selectedTile!.maxGauge,
      'minSpacing': state.selectedTile!.minSpacing,
      'maxSpacing': state.selectedTile!.maxSpacing,
      'defaultCrossBonded': state.selectedTile!.defaultCrossBonded,
      'leftHandTileWidth': state.selectedTile!.leftHandTileWidth,
    };

    // Update state with the result, even if there's a warning
    state = state.copyWith(
      verticalResult: result,
      isLoading: false,
      errorMessage: result.warning,
    );
    debugPrint('State updated with verticalResult: ${state.verticalResult}');

    debugPrint('Returning result map from calculateVertical');
    return {
      'id': calculationId,
      'inputs': inputsMap,
      'outputs': resultMap,
      'tile': tileMap,
    };
  }

  Future<Map<String, dynamic>?> calculateHorizontal(List<double> widths) async {
    debugPrint('Starting calculateHorizontal in CalculatorNotifier');
    if (state.selectedTile == null) {
      debugPrint('No tile selected');
      state = state.copyWith(
        errorMessage: 'Please select a tile before calculating',
      );
      return null;
    }

    if (_userId == null) {
      debugPrint('User not authenticated');
      state = state.copyWith(
        errorMessage: 'User not authenticated',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final input = HorizontalCalculationInput(
      widths: widths,
      tileCoverWidth: state.selectedTile!.tileCoverWidth,
      minSpacing: state.selectedTile!.minSpacing,
      maxSpacing: state.selectedTile!.maxSpacing,
      useDryVerge: state.useDryVerge,
      abutmentSide: state.abutmentSide,
      useLHTile: state.useLHTile,
      lhTileWidth: state.selectedTile!.leftHandTileWidth ?? 0,
      crossBonded: state.crossBonded,
    );

    debugPrint('Calling HorizontalCalculationService.calculateHorizontal');
    final result = HorizontalCalculationService.calculateHorizontal(input);
    debugPrint('Result from calculateHorizontal: $result');

    // Prepare calculation data
    final calculationId =
        'calc_${_userId}_${DateTime.now().millisecondsSinceEpoch}';
    final inputsMap = {
      'widths': widths
          .asMap()
          .entries
          .map((entry) => {
                'label': 'Width ${entry.key + 1}',
                'value': entry.value,
              })
          .toList(),
      'useDryVerge': state.useDryVerge,
      'abutmentSide': state.abutmentSide,
      'useLHTile': state.useLHTile,
      'crossBonded': state.crossBonded,
    };

    final resultMap = {
      'solution': result.solution,
      'newWidth': result.newWidth,
      'lhOverhang': result.lhOverhang,
      'rhOverhang': result.rhOverhang,
      'cutTile': result.cutTile,
      'firstMark': result.firstMark,
      'secondMark': result.secondMark,
      'marks': result.marks,
      'splitMarks': result.splitMarks,
      'actualSpacing': result.actualSpacing,
      'warning': result.warning,
    };

    final tileMap = {
      'id': state.selectedTile!.id,
      'name': state.selectedTile!.name,
      'materialType': state.selectedTile!.materialTypeString,
      'tileCoverWidth': state.selectedTile!.tileCoverWidth,
      'slateTileHeight': state.selectedTile!.slateTileHeight,
      'minGauge': state.selectedTile!.minGauge,
      'maxGauge': state.selectedTile!.maxGauge,
      'minSpacing': state.selectedTile!.minSpacing,
      'maxSpacing': state.selectedTile!.maxSpacing,
      'defaultCrossBonded': state.selectedTile!.defaultCrossBonded,
      'leftHandTileWidth': state.selectedTile!.leftHandTileWidth,
    };

    // Update state with the result, even if there's a warning
    state = state.copyWith(
      horizontalResult: result,
      isLoading: false,
      errorMessage: result.warning,
    );
    debugPrint(
        'State updated with horizontalResult: ${state.horizontalResult}');

    debugPrint('Returning result map from calculateHorizontal');
    return {
      'id': calculationId,
      'inputs': inputsMap,
      'outputs': resultMap,
      'tile': tileMap,
    };
  }

  void clearResults() {
    state = state.clearResults();
  }
}

// Provider for CalculationService
final calculationServiceProvider = Provider<CalculationService>((ref) {
  return CalculationService();
});

// Provider for CalculatorNotifier, injecting userId
final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  final userId = ref.watch(currentUserProvider).value?.id;
  final calculationService = ref.watch(calculationServiceProvider);
  // Fix: Pass the ref to the CalculatorNotifier
  return CalculatorNotifier(calculationService, userId, ref);
});

// Provider for default tiles (for free users)
final defaultTilesProvider = Provider<List<TileModel>>((ref) {
  final now = DateTime.now();
  return [
    TileModel(
      id: 'default-slate',
      name: 'Standard Slate',
      manufacturer: 'Generic',
      materialType: TileSlateType.slate,
      description: 'Standard 500x250mm natural slate',
      isPublic: true,
      isApproved: true,
      createdById: 'system',
      createdAt: now,
      updatedAt: now,
      slateTileHeight: 500, // mm
      minGauge: 100, // mm
      maxGauge: 200, // mm
      tileCoverWidth: 225, // mm
      minSpacing: 3, // mm
      maxSpacing: 5, // mm
      defaultCrossBonded: true,
    ),
    TileModel(
      id: 'default-plain-tile',
      name: 'Standard Plain Tile',
      manufacturer: 'Generic',
      materialType: TileSlateType.plainTile,
      description: 'Standard 265x165mm clay plain tile',
      isPublic: true,
      isApproved: true,
      createdById: 'system',
      createdAt: now,
      updatedAt: now,
      slateTileHeight: 265, // mm
      minGauge: 85, // mm
      maxGauge: 115, // mm
      tileCoverWidth: 165, // mm
      minSpacing: 0, // mm
      maxSpacing: 2, // mm
      defaultCrossBonded: false,
    ),
    TileModel(
      id: 'default-concrete-tile',
      name: 'Test Tile 2',
      manufacturer: 'Generic',
      materialType: TileSlateType.concreteTile,
      description: 'Standard 420x330mm concrete tile',
      isPublic: true,
      isApproved: true,
      createdById: 'system',
      createdAt: now,
      updatedAt: now,
      slateTileHeight: 420, // mm
      minGauge: 310, // mm
      maxGauge: 345, // mm
      tileCoverWidth: 300, // mm
      minSpacing: 2, // mm
      maxSpacing: 4, // mm
      defaultCrossBonded: false,
    ),
  ];
});
