import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

/// Quantities for a single labour quote.
class LabourQuoteInput {
  final LabourPricingMode mode;
  final LabourRoofType roofType;
  final double roofAreaSqm;
  final bool includeStrip;
  final Map<LabourLinearItem, double> linearMetres;
  final Map<LabourAncillary, int> ancillaryCounts;

  const LabourQuoteInput({
    required this.mode,
    required this.roofType,
    required this.roofAreaSqm,
    this.includeStrip = true,
    this.linearMetres = const {},
    this.ancillaryCounts = const {},
  });

  double linearMetresFor(LabourLinearItem item) => linearMetres[item] ?? 0;

  int ancillaryCountFor(LabourAncillary ancillary) =>
      ancillaryCounts[ancillary] ?? 0;

  bool get hasQuantities {
    if (roofAreaSqm > 0) return true;
    if (linearMetres.values.any((m) => m > 0)) return true;
    if (ancillaryCounts.values.any((c) => c > 0)) return true;
    return false;
  }

  LabourQuoteInput copyWith({
    LabourPricingMode? mode,
    LabourRoofType? roofType,
    double? roofAreaSqm,
    bool? includeStrip,
    Map<LabourLinearItem, double>? linearMetres,
    Map<LabourAncillary, int>? ancillaryCounts,
  }) {
    return LabourQuoteInput(
      mode: mode ?? this.mode,
      roofType: roofType ?? this.roofType,
      roofAreaSqm: roofAreaSqm ?? this.roofAreaSqm,
      includeStrip: includeStrip ?? this.includeStrip,
      linearMetres: linearMetres ?? this.linearMetres,
      ancillaryCounts: ancillaryCounts ?? this.ancillaryCounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'roofType': roofType.name,
        'roofAreaSqm': roofAreaSqm,
        'includeStrip': includeStrip,
        'linearMetres': linearMetres.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'ancillaryCounts': ancillaryCounts.map(
          (key, value) => MapEntry(key.name, value),
        ),
      };

  factory LabourQuoteInput.fromJson(Map<String, dynamic> json) {
    return LabourQuoteInput(
      mode: LabourPricingMode.values.byName(json['mode'] as String),
      roofType: labourRoofTypeFromName(json['roofType'] as String),
      roofAreaSqm: (json['roofAreaSqm'] as num).toDouble(),
      includeStrip: json['includeStrip'] as bool? ?? true,
      linearMetres: _parseLinearMetres(json['linearMetres']),
      ancillaryCounts: _parseAncillaryCounts(json['ancillaryCounts']),
    );
  }

  static Map<LabourLinearItem, double> _parseLinearMetres(dynamic raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        LabourLinearItem.values.byName(entry.key as String):
            (entry.value as num).toDouble(),
    };
  }

  static Map<LabourAncillary, int> _parseAncillaryCounts(dynamic raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        LabourAncillary.values.byName(entry.key as String):
            (entry.value as num).toInt(),
    };
  }
}