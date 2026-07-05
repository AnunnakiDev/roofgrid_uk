import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_result.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_method_resolver.dart';

/// Output of dual-method calculation — Method A (rate) and Method B (timing).
class LabourDualQuoteResult {
  final LabourQuoteResult methodA;
  final LabourQuoteResult methodB;
  final LabourQuoteMethod selectedMethod;

  const LabourDualQuoteResult({
    required this.methodA,
    required this.methodB,
    required this.selectedMethod,
  });

  LabourQuoteResult get activeResult {
    switch (selectedMethod) {
      case LabourQuoteMethod.rateBased:
        return methodA;
      case LabourQuoteMethod.timingBased:
        return methodB;
      case LabourQuoteMethod.average:
        return LabourSectionMethodResolver.blendSectionResults(
          methodA,
          methodB,
        );
      case LabourQuoteMethod.manualOverride:
        return methodB;
    }
  }

  double get activeQuoteTotalGbp => activeResult.quoteTotalGbp;

  LabourDualQuoteResult copyWith({
    LabourQuoteResult? methodA,
    LabourQuoteResult? methodB,
    LabourQuoteMethod? selectedMethod,
  }) {
    return LabourDualQuoteResult(
      methodA: methodA ?? this.methodA,
      methodB: methodB ?? this.methodB,
      selectedMethod: selectedMethod ?? this.selectedMethod,
    );
  }
}