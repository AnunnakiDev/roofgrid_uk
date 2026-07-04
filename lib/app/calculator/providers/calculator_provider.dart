import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/calculator/services/calculation_service.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/horizontal_calculation_result.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_input.dart';
import 'package:roofgrid_uk/models/calculator/vertical_calculation_result.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/utils/calculator_flow_inputs.dart';
import 'package:roofgrid_uk/utils/calculator_input_visibility.dart';
import 'package:roofgrid_uk/utils/calculator_mode.dart';

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
    bool clearVerticalResult = false,
    bool clearHorizontalResult = false,
    bool clearErrorMessage = false,
  }) {
    return CalculatorState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      selectedTile: selectedTile ?? this.selectedTile,
      gutterOverhang: gutterOverhang ?? this.gutterOverhang,
      useDryRidge: useDryRidge ?? this.useDryRidge,
      useDryVerge: useDryVerge ?? this.useDryVerge,
      abutmentSide: abutmentSide ?? this.abutmentSide,
      useLHTile: useLHTile ?? this.useLHTile,
      crossBonded: crossBonded ?? this.crossBonded,
      verticalResult: clearVerticalResult
          ? null
          : (verticalResult ?? this.verticalResult),
      horizontalResult: clearHorizontalResult
          ? null
          : (horizontalResult ?? this.horizontalResult),
    );
  }
}

class CalculatorNotifier extends Notifier<CalculatorState> {
  late final CalculationService _calculationService;

  @override
  CalculatorState build() {
    _calculationService = ref.watch(calculationServiceProvider);
    return CalculatorState();
  }

  void setTile(TileModel tile) {
    debugPrint('Setting selected tile: ${tile.name}');
    state = state.copyWith(
      selectedTile: tile,
      crossBonded: crossBondedFromTile(tile),
    );
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

  void resetOptionsForMode(CalculationTypeSelection mode) {
    switch (mode) {
      case CalculationTypeSelection.verticalOnly:
        state = state.copyWith(
          useDryVerge: 'NO',
          abutmentSide: 'NONE',
          useLHTile: 'NO',
          crossBonded: state.selectedTile != null
              ? crossBondedFromTile(state.selectedTile!)
              : 'NO',
        );
      case CalculationTypeSelection.horizontalOnly:
        state = state.copyWith(
          gutterOverhang: 50.0,
          useDryRidge: 'NO',
        );
      case CalculationTypeSelection.both:
        break;
    }
  }

  void hydrateCalculatorOptionsFromInputs({
    VerticalInputs? vertical,
    HorizontalInputs? horizontal,
  }) {
    if (vertical != null) {
      state = state.copyWith(
        gutterOverhang: vertical.gutterOverhang,
        useDryRidge: vertical.useDryRidge,
      );
    }
    if (horizontal != null) {
      state = state.copyWith(
        useDryVerge: horizontal.useDryVerge,
        abutmentSide: horizontal.abutmentSide,
        useLHTile: horizontal.useLHTile,
        crossBonded: horizontal.crossBonded,
      );
    }
  }

  Future<Map<String, dynamic>> calculateVertical(
    VerticalInputs inputs,
  ) async {
    hydrateCalculatorOptionsFromInputs(vertical: inputs);
    final rafterHeights = rafterValuesFromEntries(inputs.rafterHeights);
    debugPrint(
        'Starting calculateVertical with rafter heights: $rafterHeights');
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _calculationService.calculateVertical(
        input: VerticalCalculationInput(
          rafterHeights: rafterHeights,
          gutterOverhang: inputs.gutterOverhang,
          useDryRidge: inputs.useDryRidge,
        ),
        materialType: state.selectedTile!.materialTypeString,
        slateTileHeight: state.selectedTile!.slateTileHeight,
        maxGauge: state.selectedTile!.maxGauge,
        minGauge: state.selectedTile!.minGauge,
      );
      debugPrint('calculateVertical result: $result');
      state = state.copyWith(
        verticalResult: result,
        clearHorizontalResult: true,
        isLoading: false,
      );
      debugPrint('Updated state with verticalResult: ${state.verticalResult}');
      return {
        'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
        'inputs': {
          'rafterHeights': inputs.rafterHeights,
          'gutterOverhang': inputs.gutterOverhang,
          'useDryRidge': inputs.useDryRidge,
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

  Future<Map<String, dynamic>> calculateHorizontal(
    HorizontalInputs inputs,
  ) async {
    hydrateCalculatorOptionsFromInputs(horizontal: inputs);
    final widths = widthValuesFromEntries(inputs.widths);
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
          useDryVerge: inputs.useDryVerge,
          abutmentSide: inputs.abutmentSide,
          useLHTile: inputs.useLHTile,
          crossBonded: inputs.crossBonded,
          materialType: state.selectedTile!.materialTypeString,
        ),
      );
      debugPrint('calculateHorizontal result: $result');
      state = state.copyWith(
        horizontalResult: result,
        clearVerticalResult: true,
        isLoading: false,
      );
      debugPrint(
          'Updated state with horizontalResult: ${state.horizontalResult}');
      return {
        'id': 'calc_${DateTime.now().millisecondsSinceEpoch}',
        'inputs': {
          'widths': inputs.widths,
          'useDryVerge': inputs.useDryVerge,
          'abutmentSide': inputs.abutmentSide,
          'useLHTile': inputs.useLHTile,
          'crossBonded': inputs.crossBonded,
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
      clearVerticalResult: true,
      clearHorizontalResult: true,
      clearErrorMessage: true,
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
    NotifierProvider<CalculatorNotifier, CalculatorState>(CalculatorNotifier.new);
