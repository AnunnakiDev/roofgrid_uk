import 'package:roofgrid_uk/app/labour_pricing/models/labour_global_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type_rate_set.dart';

/// User-editable rate and timing tables keyed by roof type.
class LabourBackendData {
  final Map<LabourRoofType, LabourRoofTypeRateSet> rateSets;
  final LabourGlobalConfig global;

  const LabourBackendData({
    required this.rateSets,
    required this.global,
  });

  LabourRoofTypeRateSet rateSetFor(LabourRoofType roofType) =>
      rateSets[roofType]!;

  LabourBackendData copyWith({
    Map<LabourRoofType, LabourRoofTypeRateSet>? rateSets,
    LabourGlobalConfig? global,
  }) {
    return LabourBackendData(
      rateSets: rateSets ?? this.rateSets,
      global: global ?? this.global,
    );
  }

  LabourBackendData updateRateSet(
    LabourRoofType roofType,
    LabourRoofTypeRateSet rateSet,
  ) {
    return copyWith(
      rateSets: {...rateSets, roofType: rateSet},
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': 2,
        'rateSets': rateSets.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
        'global': global.toJson(),
      };

  factory LabourBackendData.fromJson(Map<String, dynamic> json) {
    final rawSets = json['rateSets'] as Map<String, dynamic>;
    return LabourBackendData(
      rateSets: {
        for (final entry in rawSets.entries)
          labourRoofTypeFromName(entry.key):
              LabourRoofTypeRateSet.fromJson(
                Map<String, dynamic>.from(entry.value as Map),
              ),
      },
      global: LabourGlobalConfig.fromJson(
        Map<String, dynamic>.from(json['global'] as Map),
      ),
    );
  }
}