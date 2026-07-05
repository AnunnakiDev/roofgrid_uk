import 'package:roofgrid_uk/app/labour_pricing/models/labour_dual_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';

/// Resolves per-section active labour from dual-method output.
class LabourSectionMethodResolver {
  LabourSectionMethodResolver._();

  static double activeLabourCostGbp({
    required LabourRoofSection section,
    required LabourDualQuoteResult dual,
  }) {
    switch (section.selectedMethod) {
      case LabourQuoteMethod.rateBased:
        return dual.methodA.baseLabourCostGbp;
      case LabourQuoteMethod.timingBased:
        return dual.methodB.baseLabourCostGbp;
      case LabourQuoteMethod.average:
        return (dual.methodA.baseLabourCostGbp +
                dual.methodB.baseLabourCostGbp) /
            2;
      case LabourQuoteMethod.manualOverride:
        final manual = section.manualOverrideGbp;
        if (manual == null || manual <= 0) {
          return dual.methodB.baseLabourCostGbp;
        }
        return manual;
    }
  }

  static LabourQuoteResult activeResult({
    required LabourRoofSection section,
    required LabourDualQuoteResult dual,
  }) {
    switch (section.selectedMethod) {
      case LabourQuoteMethod.rateBased:
        return dual.methodA;
      case LabourQuoteMethod.timingBased:
        return dual.methodB;
      case LabourQuoteMethod.average:
        return blendSectionResults(dual.methodA, dual.methodB);
      case LabourQuoteMethod.manualOverride:
        final manual = section.manualOverrideGbp;
        if (manual == null || manual <= 0) return dual.methodB;
        return _withLabourCost(dual.methodB, manual);
    }
  }

  static LabourQuoteResult blendSectionResults(
    LabourQuoteResult methodA,
    LabourQuoteResult methodB,
  ) {
    return LabourQuoteResult(
      baseHours: (methodA.baseHours + methodB.baseHours) / 2,
      upliftedHours: (methodA.upliftedHours + methodB.upliftedHours) / 2,
      manDays: (methodA.manDays + methodB.manDays) / 2,
      baseLabourCostGbp:
          (methodA.baseLabourCostGbp + methodB.baseLabourCostGbp) / 2,
      travelCostGbp: 0,
      overnightCostGbp: 0,
      subtotalCostGbp:
          (methodA.baseLabourCostGbp + methodB.baseLabourCostGbp) / 2,
      quoteTotalGbp:
          (methodA.baseLabourCostGbp + methodB.baseLabourCostGbp) / 2,
      profitableDayRatePerManGbp: 0,
      profitableDayRatePerGangGbp: 0,
      breakdown: const [],
    );
  }

  static LabourQuoteResult _withLabourCost(
    LabourQuoteResult template,
    double labourCostGbp,
  ) {
    return LabourQuoteResult(
      baseHours: template.baseHours,
      upliftedHours: template.upliftedHours,
      manDays: template.manDays,
      baseLabourCostGbp: labourCostGbp,
      travelCostGbp: 0,
      overnightCostGbp: 0,
      subtotalCostGbp: labourCostGbp,
      quoteTotalGbp: labourCostGbp,
      profitableDayRatePerManGbp: 0,
      profitableDayRatePerGangGbp: 0,
      breakdown: template.breakdown,
    );
  }
}