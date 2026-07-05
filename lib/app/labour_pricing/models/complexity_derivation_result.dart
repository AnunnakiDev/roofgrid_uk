import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';

/// Quantities and hours derived from complexity measurements.
class ComplexityDerivationResult {
  final double extraRoofAreaSqm;
  final Map<LabourLinearItem, double> extraLinearMetres;
  final Map<LabourAncillary, int> extraAncillaryCounts;
  final double extraHours;

  const ComplexityDerivationResult({
    this.extraRoofAreaSqm = 0,
    this.extraLinearMetres = const {},
    this.extraAncillaryCounts = const {},
    this.extraHours = 0,
  });

  bool get hasDerivedQuantities =>
      extraRoofAreaSqm > 0 ||
      extraLinearMetres.values.any((m) => m > 0) ||
      extraAncillaryCounts.values.any((c) => c > 0) ||
      extraHours > 0;

  ComplexityDerivationResult merge(ComplexityDerivationResult other) {
    final linear = Map<LabourLinearItem, double>.from(extraLinearMetres);
    for (final entry in other.extraLinearMetres.entries) {
      linear[entry.key] = (linear[entry.key] ?? 0) + entry.value;
    }
    final ancillary = Map<LabourAncillary, int>.from(extraAncillaryCounts);
    for (final entry in other.extraAncillaryCounts.entries) {
      ancillary[entry.key] = (ancillary[entry.key] ?? 0) + entry.value;
    }
    return ComplexityDerivationResult(
      extraRoofAreaSqm: extraRoofAreaSqm + other.extraRoofAreaSqm,
      extraLinearMetres: linear,
      extraAncillaryCounts: ancillary,
      extraHours: extraHours + other.extraHours,
    );
  }
}