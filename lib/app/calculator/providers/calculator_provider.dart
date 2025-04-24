import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/calculator/services/calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/tile_model.dart';

class CalculatorState {
  final bool isLoading;
  final String? errorMessage;
  final TileModel? selectedTile;
  final double gutterOverhang;
  final String useDryRidge;
  final String useDryVerge;
  final String abutmentSide;
  final String useLHTile;
  final String crossBonded;
  final VerticalCalculationResult? verticalResult;
  final HorizontalCalculationResult? horizontalResult;

  CalculatorState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedTile,
    this.gutterOverhang = 50.0,
    this.useDryRidge = 'NO',
    this.useDryVerge = 'NO',
    this.abutmentSide = 'NONE',
    this.useLHTile = 'NO',
    this.crossBonded = 'NO',
    this.verticalResult,
    this.horizontalResult,
  });

  CalculatorState copyWith({
    bool? isLoading,
    String? errorMessage,
    TileModel? selectedTile,
    double? gutterOverhang,
    String? useDryRidge,
    String? useDryVerge,
    String? abutmentSide,
    String? useLHTile,
    String? crossBonded,
    VerticalCalculationResult? verticalResult,
    HorizontalCalculationResult? horizontalResult,
  }) {
    return CalculatorState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTile: selectedTile ?? this.selectedTile,
      gutterOverhang: gutterOverhang ?? this.gutterOverhang,
      useDryRidge: useDryRidge ?? this.useDryRidge,
      useDryVerge: useDryVerge ?? this.useDryVerge,
      abutmentSide: abutmentSide ?? this.abutmentSide,
      useLHTile: useLHTile ?? this.useLHTile,
      crossBonded: crossBonded ?? this.crossBonded,
      verticalResult: verticalResult ?? this.verticalResult,
      horizontalResult: horizontalResult ?? this.horizontalResult,
    );
  }
}

class CalculatorNotifier extends StateNotifier<CalculatorState> {
  final CalculationService _calculationService;

  CalculatorNotifier(this._calculationService) : super(CalculatorState());

  void setTile(TileModel tile) {
    debugPrint('Setting selected tile: ${tile.name}');
    state = state.copyWith(selectedTile: tile);
  }

  void setGutterOverhang(double value) {
    debugPrint('Setting gutter overhang: $value');
    state = state.copyWith(gutterOverhang: value);
  }

  void setUseDryRidge(String value) {
    debugPrint('Setting useDryRidge: $value');
    state = state.copyWith(useDryRidge: value);
  }

  void setUseDryVerge(String value) {
    debugPrint('Setting useDryVerge: $value');
    state = state.copyWith(useDryVerge: value);
  }

  void setAbutmentSide(String value) {
    debugPrint('Setting abutmentSide: $value');
    state = state.copyWith(abutmentSide: value);
  }

  void setUseLHTile(String value) {
    debugPrint('Setting useLHTile: $value');
    state = state.copyWith(useLHTile: value);
  }

  void setCrossBonded(String value) {
    debugPrint('Setting crossBonded: $value');
    state = state.copyWith(crossBonded: value);
  }

  Future<Map<String, dynamic>> calculateVertical(
      List<double> rafterHeights) async {
    debugPrint(
        'Starting calculateVertical with rafter heights: $rafterHeights');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _calculationService.calculateVertical(
        input: VerticalCalculationInput(
          rafterHeights: rafterHeights,
          gutterOverhang: state.gutterOverhang,
          useDryRidge: state.useDryRidge,
        ),
        materialType: state.selectedTile!.materialTypeString,
        slateTileHeight: state.selectedTile!.slateTileHeight,
        maxGauge: state.selectedTile!.maxGauge,
        minGauge: state.selectedTile!.minGauge,
      );
      debugPrint('calculateVertical result: $result');
      state = state.copyWith(
        verticalResult: result,
        isLoading: false,
      );
      debugPrint('Updated state with verticalResult: ${state.verticalResult}');
      return {
        'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
        'inputs': {
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
        },
        'outputs': result.toJson(),
        'tile': state.selectedTile!.toJson(),
      };
    } catch (e) {
      debugPrint('Error in calculateVertical: $e');
      state = state.copyWith(
        errorMessage: 'Failed to calculate: $e',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> calculateHorizontal(List<double> widths) async {
    debugPrint('Starting calculateHorizontal with widths: $widths');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _calculationService.calculateHorizontal(
        HorizontalCalculationInput(
          widths: widths,
          tileCoverWidth: state.selectedTile!.tileCoverWidth,
          minSpacing: state.selectedTile!.minSpacing,
          maxSpacing: state.selectedTile!.maxSpacing,
          lhTileWidth: state.selectedTile!.leftHandTileWidth ??
              state.selectedTile!.tileCoverWidth,
          useDryVerge: state.useDryVerge,
          abutmentSide: state.abutmentSide,
          useLHTile: state.useLHTile,
          crossBonded: state.crossBonded,
        ),
      );
      debugPrint('calculateHorizontal result: $result');
      state = state.copyWith(
        horizontalResult: result,
        isLoading: false,
      );
      debugPrint(
          'Updated state with horizontalResult: ${state.horizontalResult}');
      return {
        'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
        'inputs': {
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
        },
        'outputs': result.toJson(),
        'tile': state.selectedTile!.toJson(),
      };
    } catch (e) {
      debugPrint('Error in calculateHorizontal: $e');
      state = state.copyWith(
        errorMessage: 'Failed to calculate: $e',
        isLoading: false,
      );
      rethrow;
    }
  }

  void updateState({
    VerticalCalculationResult? verticalResult,
    HorizontalCalculationResult? horizontalResult,
  }) {
    debugPrint(
        'Updating state with verticalResult: $verticalResult, horizontalResult: $horizontalResult');
    state = state.copyWith(
      verticalResult: verticalResult,
      horizontalResult: horizontalResult,
    );
    debugPrint(
        'Updated state: verticalResult=${state.verticalResult}, horizontalResult=${state.horizontalResult}');
  }

  void clearResults() {
    debugPrint('Clearing calculation results');
    state = state.copyWith(
      verticalResult: null,
      horizontalResult: null,
      errorMessage: null,
      isLoading: false,
    );
    debugPrint(
        'Cleared state: verticalResult=${state.verticalResult}, horizontalResult=${state.horizontalResult}');
  }
}

final calculationServiceProvider = Provider<CalculationService>((ref) {
  return CalculationService();
});

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  final calculationService = ref.watch(calculationServiceProvider);
  return CalculatorNotifier(calculationService);
});
