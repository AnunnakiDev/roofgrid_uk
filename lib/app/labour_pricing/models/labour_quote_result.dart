class LabourQuoteBreakdownLine {
  final String label;
  final double hours;
  final double? costGbp;

  const LabourQuoteBreakdownLine({
    required this.label,
    required this.hours,
    this.costGbp,
  });
}

/// Output of [LabourPricingEngine.calculate].
class LabourQuoteResult {
  final double baseHours;
  final double upliftedHours;
  final double manDays;
  final double baseLabourCostGbp;
  final double travelCostGbp;
  final double overnightCostGbp;
  final double subtotalCostGbp;
  final double quoteTotalGbp;
  final double profitableDayRatePerManGbp;
  final double profitableDayRatePerGangGbp;
  final List<LabourQuoteBreakdownLine> breakdown;

  const LabourQuoteResult({
    required this.baseHours,
    required this.upliftedHours,
    required this.manDays,
    required this.baseLabourCostGbp,
    required this.travelCostGbp,
    required this.overnightCostGbp,
    required this.subtotalCostGbp,
    required this.quoteTotalGbp,
    required this.profitableDayRatePerManGbp,
    required this.profitableDayRatePerGangGbp,
    required this.breakdown,
  });
}