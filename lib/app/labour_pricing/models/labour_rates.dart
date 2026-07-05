import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rate_profile.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

/// User-editable rate tables and travel/overnight costs.
class LabourRates {
  final LabourRateProfile direct;
  final LabourRateProfile subContractor;
  final Map<LabourRoofType, double> roofTypeMultipliers;
  final double costPerMile;
  final double overnightCostPerNight;

  const LabourRates({
    required this.direct,
    required this.subContractor,
    required this.roofTypeMultipliers,
    required this.costPerMile,
    required this.overnightCostPerNight,
  });

  LabourRateProfile profileFor(LabourPricingMode mode) {
    switch (mode) {
      case LabourPricingMode.direct:
        return direct;
      case LabourPricingMode.subContractor:
        return subContractor;
    }
  }

  double roofMultiplierFor(LabourRoofType roofType) =>
      roofTypeMultipliers[roofType] ?? 1.0;

  LabourRates copyWith({
    LabourRateProfile? direct,
    LabourRateProfile? subContractor,
    Map<LabourRoofType, double>? roofTypeMultipliers,
    double? costPerMile,
    double? overnightCostPerNight,
  }) {
    return LabourRates(
      direct: direct ?? this.direct,
      subContractor: subContractor ?? this.subContractor,
      roofTypeMultipliers: roofTypeMultipliers ?? this.roofTypeMultipliers,
      costPerMile: costPerMile ?? this.costPerMile,
      overnightCostPerNight: overnightCostPerNight ?? this.overnightCostPerNight,
    );
  }

  Map<String, dynamic> toJson() => {
        'direct': direct.toJson(),
        'subContractor': subContractor.toJson(),
        'roofTypeMultipliers': roofTypeMultipliers.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'costPerMile': costPerMile,
        'overnightCostPerNight': overnightCostPerNight,
      };

  factory LabourRates.fromJson(Map<String, dynamic> json) {
    return LabourRates(
      direct: LabourRateProfile.fromJson(
        Map<String, dynamic>.from(json['direct'] as Map),
      ),
      subContractor: LabourRateProfile.fromJson(
        Map<String, dynamic>.from(json['subContractor'] as Map),
      ),
      roofTypeMultipliers: {
        for (final entry
            in (json['roofTypeMultipliers'] as Map<String, dynamic>).entries)
          labourRoofTypeFromName(entry.key):
              (entry.value as num).toDouble(),
      },
      costPerMile: (json['costPerMile'] as num).toDouble(),
      overnightCostPerNight: (json['overnightCostPerNight'] as num).toDouble(),
    );
  }
}