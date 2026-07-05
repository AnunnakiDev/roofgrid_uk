import 'package:roofgrid_uk/app/labour_pricing/models/complexity_derivation_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_config.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/complexity_derivation.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_uplift.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_slate_multiplier.dart';

/// Section-specific parameters passed into [LabourPricingEngine.calculateDual].
class LabourSectionCalcParams {
  final LabourRoofType? stripRoofType;
  final double installAreaMultiplier;
  final double additionalHours;

  const LabourSectionCalcParams({
    this.stripRoofType,
    this.installAreaMultiplier = 1,
    this.additionalHours = 0,
  });
}

/// Prepares effective section inputs and uplifted config for the engine.
class LabourSectionCalculator {
  LabourSectionCalculator._();

  static ComplexityDerivationResult derivedQuantities(LabourRoofSection section) {
    return ComplexityDerivation.derive(section.complexityFeatures);
  }

  static LabourQuoteInput effectiveInput(LabourRoofSection section) {
    final derived = derivedQuantities(section);
    final merged = applyDerivedQuantities(section.input, derived);
    return merged.copyWith(includeStrip: section.stripping.includeStrip);
  }

  static LabourQuoteInput applyDerivedQuantities(
    LabourQuoteInput input,
    ComplexityDerivationResult derived,
  ) {
    final linear = Map<LabourLinearItem, double>.from(input.linearMetres);
    for (final entry in derived.extraLinearMetres.entries) {
      linear[entry.key] = (linear[entry.key] ?? 0) + entry.value;
    }

    final ancillary = Map<LabourAncillary, int>.from(input.ancillaryCounts);
    for (final entry in derived.extraAncillaryCounts.entries) {
      ancillary[entry.key] = (ancillary[entry.key] ?? 0) + entry.value;
    }

    return input.copyWith(
      roofAreaSqm: input.roofAreaSqm + derived.extraRoofAreaSqm,
      linearMetres: linear,
      ancillaryCounts: ancillary,
    );
  }

  static LabourQuoteConfig configWithSectionUplift({
    required LabourQuoteConfig baseConfig,
    required LabourRoofSection section,
  }) {
    final sectionUplift = LabourSectionUplift.totalUpliftPercent(
      pitchDegrees: section.pitchDegrees,
      heritage: section.heritage,
      accessUpliftPercent: section.accessUpliftPercent,
    );
    return baseConfig.copyWith(
      difficultyUpliftPercent:
          baseConfig.difficultyUpliftPercent + sectionUplift,
    );
  }

  static LabourSectionCalcParams calcParams(LabourRoofSection section) {
    final stripping = section.stripping;
    return LabourSectionCalcParams(
      stripRoofType: stripping.includeStrip ? stripping.oldRoofType : null,
      installAreaMultiplier: LabourSlateMultiplier.installMultiplier(
        roofType: section.input.roofType,
        slateSize: section.newCovering.slateSize,
      ),
      additionalHours: derivedQuantities(section).extraHours,
    );
  }
}