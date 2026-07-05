import 'package:roofgrid_uk/app/labour_pricing/models/labour_dual_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_method_resolver.dart';

/// Per-section dual-method output within a project calculation.
class LabourSectionResult {
  final LabourRoofSection section;
  final LabourDualQuoteResult dualResult;

  const LabourSectionResult({
    required this.section,
    required this.dualResult,
  });

  LabourQuoteResult get activeResult => LabourSectionMethodResolver.activeResult(
        section: section,
        dual: dualResult,
      );

  double get activeLabourCostGbp => LabourSectionMethodResolver.activeLabourCostGbp(
        section: section,
        dual: dualResult,
      );
}

/// Project-level rollup — travel, overnight, contingency, and margin applied once.
class LabourProjectResult {
  final List<LabourSectionResult> sectionResults;
  final LabourQuoteResult rollup;
  final LabourQuoteResult methodARollup;
  final LabourQuoteResult methodBRollup;

  const LabourProjectResult({
    required this.sectionResults,
    required this.rollup,
    required this.methodARollup,
    required this.methodBRollup,
  });

  double get activeQuoteTotalGbp => rollup.quoteTotalGbp;

  double get methodATotalGbp => methodARollup.quoteTotalGbp;

  double get methodBTotalGbp => methodBRollup.quoteTotalGbp;

  double get contingencyCostGbp {
    final labour = sectionResults.fold<double>(
      0,
      (sum, s) => sum + s.activeLabourCostGbp,
    );
    final preContingency =
        labour + rollup.travelCostGbp + rollup.overnightCostGbp;
    return rollup.subtotalCostGbp - preContingency;
  }
}