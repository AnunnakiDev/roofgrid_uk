import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/models/tile_model.dart';
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
  CalculatorNotifier() : super(CalculatorState());

  void setTile(TileModel tile) {
    state = state.copyWith(selectedTile: tile).clearResults();
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

  Future<void> calculateVertical(List<double> rafterHeights) async {
    if (state.selectedTile == null) {
      state = state.copyWith(
        errorMessage: 'Please select a tile before calculating',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final input = VerticalCalculationInput(
        rafterHeights: rafterHeights,
        gutterOverhang: state.gutterOverhang,
        useDryRidge: state.useDryRidge,
      );

      final result = VerticalCalculationService.calculateVertical(
        input: input,
        materialType: state.selectedTile!.materialTypeString,
        slateTileHeight: state.selectedTile!.slateTileHeight,
        maxGauge: state.selectedTile!.maxGauge,
        minGauge: state.selectedTile!.minGauge,
      );
      state = state.copyWith(verticalResult: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> calculateHorizontal(List<double> widths) async {
    if (state.selectedTile == null) {
      state = state.copyWith(
        errorMessage: 'Please select a tile before calculating',
      );
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
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

      final result = HorizontalCalculationService.calculateHorizontal(input);
      state = state.copyWith(horizontalResult: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading: false,
      );
    }
  }

  void clearResults() {
    state = state.clearResults();
  }
}

final calculatorProvider =
    StateNotifierProvider<CalculatorNotifier, CalculatorState>((ref) {
  return CalculatorNotifier();
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
      name: 'Standard Concrete Tile',
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
