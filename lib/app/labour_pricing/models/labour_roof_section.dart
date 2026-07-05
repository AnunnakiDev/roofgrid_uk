import 'package:roofgrid_uk/app/labour_pricing/models/labour_complexity_feature.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_material_line.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_materials_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_new_covering.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/section_stripping.dart';

/// One roof area within a multi-section labour quote.
class LabourRoofSection {
  final String id;
  final String label;
  final LabourQuoteInput input;
  final LabourQuoteMethod selectedMethod;
  final double pitchDegrees;
  final bool heritage;
  final double accessUpliftPercent;
  final List<LabourComplexityFeature> complexityFeatures;
  final SectionStripping stripping;
  final SectionNewCovering newCovering;
  final double? manualOverrideGbp;
  final List<LabourMaterialLine> materialLines;
  final SectionMaterialsMode materialsMode;

  const LabourRoofSection({
    required this.id,
    required this.label,
    required this.input,
    this.selectedMethod = LabourQuoteMethod.timingBased,
    this.pitchDegrees = 0,
    this.heritage = false,
    this.accessUpliftPercent = 0,
    this.complexityFeatures = const [],
    this.stripping = const SectionStripping(),
    this.newCovering = const SectionNewCovering(),
    this.manualOverrideGbp,
    this.materialLines = const [],
    this.materialsMode = SectionMaterialsMode.inheritProject,
  });

  factory LabourRoofSection.initial({
    required String id,
    String label = 'Section 1',
  }) {
    return LabourRoofSection(
      id: id,
      label: label,
      input: const LabourQuoteInput(
        mode: LabourPricingMode.direct,
        roofType: LabourRoofType.traditionalPantile,
        roofAreaSqm: 0,
      ),
    );
  }

  LabourComplexityFeature? complexityFeatureOf(LabourComplexityFeatureType type) {
    for (final feature in complexityFeatures) {
      if (feature.type == type) return feature;
    }
    return null;
  }

  LabourRoofSection copyWith({
    String? id,
    String? label,
    LabourQuoteInput? input,
    LabourQuoteMethod? selectedMethod,
    double? pitchDegrees,
    bool? heritage,
    double? accessUpliftPercent,
    List<LabourComplexityFeature>? complexityFeatures,
    SectionStripping? stripping,
    SectionNewCovering? newCovering,
    double? manualOverrideGbp,
    bool clearManualOverrideGbp = false,
    List<LabourMaterialLine>? materialLines,
    SectionMaterialsMode? materialsMode,
  }) {
    return LabourRoofSection(
      id: id ?? this.id,
      label: label ?? this.label,
      input: input ?? this.input,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      pitchDegrees: pitchDegrees ?? this.pitchDegrees,
      heritage: heritage ?? this.heritage,
      accessUpliftPercent: accessUpliftPercent ?? this.accessUpliftPercent,
      complexityFeatures: complexityFeatures ?? this.complexityFeatures,
      stripping: stripping ?? this.stripping,
      newCovering: newCovering ?? this.newCovering,
      manualOverrideGbp: clearManualOverrideGbp
          ? null
          : (manualOverrideGbp ?? this.manualOverrideGbp),
      materialLines: materialLines ?? this.materialLines,
      materialsMode: materialsMode ?? this.materialsMode,
    );
  }

  double get sectionMaterialCostGbp => materialLines.fold<double>(
        0,
        (sum, line) => sum + line.lineTotalGbp,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'input': input.toJson(),
        'selectedMethod': selectedMethod.name,
        'pitchDegrees': pitchDegrees,
        'heritage': heritage,
        'accessUpliftPercent': accessUpliftPercent,
        'complexityFeatures':
            complexityFeatures.map((feature) => feature.toJson()).toList(),
        'stripping': stripping.toJson(),
        'newCovering': newCovering.toJson(),
        if (manualOverrideGbp != null) 'manualOverrideGbp': manualOverrideGbp,
        'materialLines': materialLines.map((line) => line.toJson()).toList(),
        'materialsMode': materialsMode.name,
      };

  factory LabourRoofSection.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['complexityFeatures'] as List<dynamic>? ?? const [];
    return LabourRoofSection(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Section',
      input: LabourQuoteInput.fromJson(json['input'] as Map<String, dynamic>),
      selectedMethod: LabourQuoteMethod.values
          .byName(json['selectedMethod'] as String? ?? 'timingBased'),
      pitchDegrees: (json['pitchDegrees'] as num?)?.toDouble() ?? 0,
      heritage: json['heritage'] as bool? ?? false,
      accessUpliftPercent:
          (json['accessUpliftPercent'] as num?)?.toDouble() ?? 0,
      complexityFeatures: rawFeatures
          .map(
            (raw) =>
                LabourComplexityFeature.fromJson(raw as Map<String, dynamic>),
          )
          .toList(),
      stripping: json['stripping'] != null
          ? SectionStripping.fromJson(
              json['stripping'] as Map<String, dynamic>,
            )
          : const SectionStripping(),
      newCovering: json['newCovering'] != null
          ? SectionNewCovering.fromJson(
              json['newCovering'] as Map<String, dynamic>,
            )
          : const SectionNewCovering(),
      manualOverrideGbp: (json['manualOverrideGbp'] as num?)?.toDouble(),
      materialLines: _parseMaterialLines(json['materialLines']),
      materialsMode: SectionMaterialsMode.values.byName(
        json['materialsMode'] as String? ?? 'inheritProject',
      ),
    );
  }

  static List<LabourMaterialLine> _parseMaterialLines(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(
          (entry) =>
              LabourMaterialLine.fromJson(entry as Map<String, dynamic>),
        )
        .toList();
  }
}