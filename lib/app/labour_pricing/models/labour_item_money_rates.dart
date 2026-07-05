import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_catalog.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';

/// Method A £/lm and £/unit rates for linear and ancillary items.
class LabourItemMoneyRates {
  final Map<LabourLinearItem, double> linearRatePerMetre;
  final Map<LabourAncillary, double> ancillaryRateEach;

  const LabourItemMoneyRates({
    required this.linearRatePerMetre,
    required this.ancillaryRateEach,
  });

  double linearRateFor(LabourLinearItem item) =>
      linearRatePerMetre[item] ?? 0;

  double ancillaryRateFor(LabourAncillary ancillary) =>
      ancillaryRateEach[ancillary] ?? 0;

  LabourItemMoneyRates copyWith({
    Map<LabourLinearItem, double>? linearRatePerMetre,
    Map<LabourAncillary, double>? ancillaryRateEach,
  }) {
    return LabourItemMoneyRates(
      linearRatePerMetre: linearRatePerMetre ?? this.linearRatePerMetre,
      ancillaryRateEach: ancillaryRateEach ?? this.ancillaryRateEach,
    );
  }

  Map<String, dynamic> toJson() => {
        'linearRatePerMetre': linearRatePerMetre.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'ancillaryRateEach': ancillaryRateEach.map(
          (key, value) => MapEntry(key.name, value),
        ),
      };

  factory LabourItemMoneyRates.fromJson(Map<String, dynamic> json) {
    return LabourItemMoneyRates(
      linearRatePerMetre: _parseLinearRates(json['linearRatePerMetre']),
      ancillaryRateEach: _parseAncillaryRates(json['ancillaryRateEach']),
    );
  }

  static Map<LabourLinearItem, double> _parseLinearRates(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <LabourLinearItem, double>{};
    for (final entry in raw.entries) {
      final item = tryParseLabourLinearItem(entry.key as String);
      if (item != null) {
        result[item] = (entry.value as num).toDouble();
      }
    }
    return result;
  }

  static Map<LabourAncillary, double> _parseAncillaryRates(dynamic raw) {
    if (raw is! Map) return const {};
    final result = <LabourAncillary, double>{};
    for (final entry in raw.entries) {
      final item = tryParseLabourAncillary(entry.key as String);
      if (item != null) {
        result[item] = (entry.value as num).toDouble();
      }
    }
    return result;
  }
}