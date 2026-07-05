/// Which calculation method drives the displayed quote total.
enum LabourQuoteMethod {
  rateBased,
  timingBased,
  average,
  manualOverride,
}

extension LabourQuoteMethodLabels on LabourQuoteMethod {
  String get label {
    switch (this) {
      case LabourQuoteMethod.rateBased:
        return 'Rate-based (fast)';
      case LabourQuoteMethod.timingBased:
        return 'Timing-based (accurate)';
      case LabourQuoteMethod.average:
        return 'Average of A & B';
      case LabourQuoteMethod.manualOverride:
        return 'Manual override';
    }
  }

  String get shortLabel {
    switch (this) {
      case LabourQuoteMethod.rateBased:
        return 'Method A';
      case LabourQuoteMethod.timingBased:
        return 'Method B';
      case LabourQuoteMethod.average:
        return 'Average';
      case LabourQuoteMethod.manualOverride:
        return 'Manual';
    }
  }
}